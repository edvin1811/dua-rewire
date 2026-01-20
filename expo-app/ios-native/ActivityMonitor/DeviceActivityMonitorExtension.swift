import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

// MARK: - Device Activity Monitor Extension
// This extension monitors app usage and enforces screen time limits

class UnwireDeviceActivityMonitor: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    // Called when a scheduled activity interval begins
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Start monitoring - could apply shields to discourage app use
        print("Focus session started: \(activity.rawValue)")

        // Post notification to update UI
        NotificationCenter.default.post(
            name: Notification.Name("FocusSessionStarted"),
            object: nil,
            userInfo: ["activity": activity.rawValue]
        )
    }

    // Called when a scheduled activity interval ends
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // End monitoring - remove shields
        store.clearAllSettings()

        print("Focus session ended: \(activity.rawValue)")

        // Post notification to update UI
        NotificationCenter.default.post(
            name: Notification.Name("FocusSessionEnded"),
            object: nil,
            userInfo: ["activity": activity.rawValue]
        )
    }

    // Called when app usage threshold is reached
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("Threshold reached for event: \(event.rawValue)")

        // Apply shield to block app
        // This would be configured based on user's blocked app selection
    }

    // Called when usage warning threshold is reached
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        print("Focus session starting soon: \(activity.rawValue)")
    }

    // Called when interval is about to end
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)

        print("Focus session ending soon: \(activity.rawValue)")
    }
}
