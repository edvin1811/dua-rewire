import Foundation
import React
import FamilyControls
import DeviceActivity
import ManagedSettings

@objc(ScreenTimeModule)
class ScreenTimeModuleBridge: RCTEventEmitter {

    private let manager = ScreenTimeManager.shared

    override init() {
        super.init()

        // Listen for focus session events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFocusSessionStarted),
            name: Notification.Name("FocusSessionStarted"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFocusSessionEnded),
            name: Notification.Name("FocusSessionEnded"),
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - RCTEventEmitter

    override func supportedEvents() -> [String]! {
        return ["FocusSessionStarted", "FocusSessionEnded", "ThresholdReached", "AppPickerPresented"]
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    // MARK: - Authorization

    @objc func requestAuthorization(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        manager.requestAuthorization { success, error in
            if let error = error {
                reject("AUTH_ERROR", error, nil)
            } else {
                resolve(success)
            }
        }
    }

    @objc func checkAuthorizationStatus(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        let status = manager.checkAuthorizationStatus()
        resolve(status)
    }

    // MARK: - App Picker

    @objc func presentAppPicker() {
        manager.presentAppPicker()
        sendEvent(withName: "AppPickerPresented", body: nil)
    }

    // MARK: - Focus Sessions

    @objc func startFocusSession(
        _ name: String,
        durationMinutes: Int,
        resolver resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        manager.startFocusSession(name: name, durationMinutes: durationMinutes) { success, error in
            if let error = error {
                reject("FOCUS_ERROR", error, nil)
            } else {
                resolve(success)
            }
        }
    }

    @objc func stopFocusSession(_ name: String) {
        manager.stopFocusSession(name: name)
    }

    @objc func stopAllMonitoring() {
        manager.stopAllMonitoring()
    }

    // MARK: - Usage Data

    @objc func getUsageSummary(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        manager.getUsageSummary { summary in
            resolve(summary)
        }
    }

    // MARK: - Event Handlers

    @objc private func handleFocusSessionStarted(_ notification: Notification) {
        let activityName = notification.userInfo?["activity"] as? String ?? ""
        sendEvent(withName: "FocusSessionStarted", body: ["activity": activityName])
    }

    @objc private func handleFocusSessionEnded(_ notification: Notification) {
        let activityName = notification.userInfo?["activity"] as? String ?? ""
        sendEvent(withName: "FocusSessionEnded", body: ["activity": activityName])
    }
}
