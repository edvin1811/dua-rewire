import Foundation
import React
import WidgetKit

@objc(WidgetModule)
class WidgetModuleBridge: NSObject {

    // App Group identifier for sharing data with widget
    private let appGroupId = "group.com.unwire.focus"
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupId)
    }

    override init() {
        super.init()
    }

    @objc static func requiresMainQueueSetup() -> Bool {
        return false
    }

    /// Update widget data from React Native
    @objc func updateWidgetData(_ data: NSDictionary) {
        guard let defaults = sharedDefaults else {
            print("WidgetModule: Failed to access shared UserDefaults")
            return
        }

        // Save data to shared UserDefaults
        if let focusMinutes = data["focusMinutes"] as? Int {
            defaults.set(focusMinutes, forKey: "todayFocusMinutes")
        }

        if let streakDays = data["streakDays"] as? Int {
            defaults.set(streakDays, forKey: "streakDays")
        }

        if let blockedApps = data["blockedApps"] as? Int {
            defaults.set(blockedApps, forKey: "blockedAppsCount")
        }

        if let isFocusing = data["isFocusing"] as? Bool {
            defaults.set(isFocusing, forKey: "isInFocusSession")
        }

        if let dailyGoalMinutes = data["dailyGoalMinutes"] as? Int {
            defaults.set(dailyGoalMinutes, forKey: "dailyGoalMinutes")
        }

        defaults.synchronize()

        // Trigger widget refresh
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// Reload all widget timelines
    @objc func reloadAllTimelines() {
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    /// Reload a specific widget timeline
    @objc func reloadTimeline(_ kind: String) {
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
            }
        }
    }
}
