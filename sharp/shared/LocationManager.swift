//
//  LocationManager.swift
//  sharp
//
//  Created by Edvin Åslund on 2025-09-29.
//


import Foundation
import CoreLocation
import Combine
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isInsideMonitoredRegion = false

    // Track if we need Always authorization for background monitoring
    var needsAlwaysAuthorization: Bool {
        return authorizationStatus != .authorizedAlways
    }

    var isAuthorized: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isAuthorizedAlways: Bool {
        return authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self

        // Use lower accuracy for battery efficiency while maintaining region monitoring
        // Region monitoring works independently of accuracy setting
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // Enable background location for region monitoring
        manager.allowsBackgroundLocationUpdates = true

        // Don't pause - we need continuous region monitoring
        // Note: Region monitoring itself is battery efficient
        manager.pausesLocationUpdatesAutomatically = false

        // Show blue bar when using location in background
        manager.showsBackgroundLocationIndicator = true
    }

    func requestAuthorization() {
        // First request WhenInUse
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        // Request Always authorization for background monitoring
        // Note: Must be called AFTER WhenInUse is granted
        manager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func startMonitoring(coordinate: CLLocationCoordinate2D, radius: Double, identifier: String) {
        // CoreLocation requires minimum 100m radius for reliable monitoring
        // Larger radii are more battery efficient and work better with Low Power Mode
        let clampedRadius = max(radius, 100)

        if radius < 100 {
            print("⚠️ Radius \(radius)m is too small, clamping to 100m for battery efficiency")
        }

        let region = CLCircularRegion(
            center: coordinate,
            radius: clampedRadius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true

        // Stop location updates to save battery - region monitoring is separate and efficient
        manager.stopUpdatingLocation()

        // Start region monitoring (works even in Low Power Mode)
        manager.startMonitoring(for: region)

        // Request immediate state to check if already inside
        manager.requestState(for: region)

        print("📍 Started monitoring region: \(identifier) with radius: \(clampedRadius)m")
        print("📍 Region monitoring is battery efficient and works in Low Power Mode")
    }

    func isInside(coordinate: CLLocationCoordinate2D, radius: Double) -> Bool {
        guard let current = currentLocation else { return false }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = current.distance(from: location)
        return distance <= radius
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside:
            print("📍 Determined state: INSIDE region \(region.identifier)")
            isInsideMonitoredRegion = true
            NotificationCenter.default.post(name: NSNotification.Name("DidEnterRegion"), object: region.identifier)
        case .outside:
            print("📍 Determined state: OUTSIDE region \(region.identifier)")
            isInsideMonitoredRegion = false
        case .unknown:
            print("📍 Determined state: UNKNOWN for region \(region.identifier)")
        }
    }
    
    func stopMonitoring(identifier: String) {
        for region in manager.monitoredRegions {
            if region.identifier == identifier {
                manager.stopMonitoring(for: region)
                print("📍 Stopped monitoring region: \(identifier)")
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("📍 Location authorization changed: \(authorizationStatus.rawValue)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("📍 Entered region: \(region.identifier)")

        // Start a background task to ensure we have time to apply blocking
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            print("⚠️ Background task expired for region entry")
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }

        isInsideMonitoredRegion = true
        NotificationCenter.default.post(name: NSNotification.Name("DidEnterRegion"), object: region.identifier)

        // Send user notification
        Task {
            await NotificationManager.shared.sendLocationEntered(locationName: region.identifier)
        }

        // Give the notification handlers time to process (extended from 2s to 5s)
        // Family Controls API calls may take longer than 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            print("✅ Background task completed for region entry")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("📍 🚶 EXITED region: \(region.identifier)")

        // Start a background task to ensure we have time to remove blocking
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            print("⚠️ Background task expired for region exit")
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }

        isInsideMonitoredRegion = false

        // Post notification
        NotificationCenter.default.post(name: NSNotification.Name("DidExitRegion"), object: region.identifier)
        print("📍 Posted DidExitRegion notification for \(region.identifier)")

        // Send user notification
        Task {
            await NotificationManager.shared.sendLocationExited(locationName: region.identifier)
        }

        // Give the notification handlers time to process (extended from 2s to 5s)
        // Family Controls API calls may take longer than 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            print("✅ Background task completed for region exit")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error)")
    }
}
