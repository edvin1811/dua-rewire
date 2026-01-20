import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

// MARK: - Screen Time Manager
// Handles authorization, usage data queries, and app blocking

@objc(ScreenTimeManager)
public class ScreenTimeManager: NSObject {

    @objc public static let shared = ScreenTimeManager()

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()

    // Current authorization status
    @objc public var isAuthorized: Bool {
        return center.authorizationStatus == .approved
    }

    // MARK: - Authorization

    /// Request Screen Time authorization from the user
    @objc public func requestAuthorization(completion: @escaping (Bool, String?) -> Void) {
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }

    /// Check current authorization status
    @objc public func checkAuthorizationStatus() -> String {
        switch center.authorizationStatus {
        case .notDetermined:
            return "notDetermined"
        case .denied:
            return "denied"
        case .approved:
            return "approved"
        @unknown default:
            return "unknown"
        }
    }

    // MARK: - App Selection

    /// Present the Family Controls app picker
    @objc public func presentAppPicker() {
        // This would be called from the React Native side
        // The actual picker is presented using SwiftUI's FamilyActivityPicker
        NotificationCenter.default.post(
            name: Notification.Name("PresentAppPicker"),
            object: nil
        )
    }

    // MARK: - Activity Monitoring

    /// Start monitoring a focus session
    @objc public func startFocusSession(
        name: String,
        durationMinutes: Int,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let activityName = DeviceActivityName(name)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: false
        )

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            completion(true, nil)
        } catch {
            completion(false, error.localizedDescription)
        }
    }

    /// Stop monitoring a focus session
    @objc public func stopFocusSession(name: String) {
        let activityName = DeviceActivityName(name)
        deviceActivityCenter.stopMonitoring([activityName])
    }

    /// Stop all monitoring
    @objc public func stopAllMonitoring() {
        deviceActivityCenter.stopMonitoring()
        store.clearAllSettings()
    }

    // MARK: - App Shielding

    /// Block selected applications
    @objc public func blockApps(appTokens: Set<ApplicationToken>) {
        store.shield.applications = appTokens
    }

    /// Block app categories
    @objc public func blockCategories(categoryTokens: Set<ActivityCategoryToken>) {
        store.shield.applicationCategories = .specific(categoryTokens)
    }

    /// Unblock all apps
    @objc public func unblockAllApps() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - Usage Data (requires DeviceActivityReport)

    /// Get summary of app usage for a date range
    /// Note: Detailed usage data requires DeviceActivityReport SwiftUI view
    @objc public func getUsageSummary(completion: @escaping ([String: Any]?) -> Void) {
        // Usage data is accessed through DeviceActivityReport
        // This is a placeholder - actual implementation requires SwiftUI integration
        let summary: [String: Any] = [
            "totalScreenTime": 0,
            "pickups": 0,
            "notifications": 0,
            "note": "Use DeviceActivityReport for detailed usage data"
        ]
        completion(summary)
    }
}

// MARK: - Device Activity Names
extension DeviceActivityName {
    static let focusSession = Self("focusSession")
    static let dailyLimit = Self("dailyLimit")
    static let bedtime = Self("bedtime")
}

// MARK: - Device Activity Events
extension DeviceActivityEvent.Name {
    static let appLimitReached = Self("appLimitReached")
    static let categoryLimitReached = Self("categoryLimitReached")
}
