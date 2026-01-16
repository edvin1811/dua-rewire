import ActivityKit
import Foundation

// MARK: - Live Activity Attributes for Blocking Sessions
// This struct defines the state model for Live Activities shown on lock screen and Dynamic Island

@available(iOS 16.1, *)
struct BlockingActivityAttributes: ActivityAttributes {

    // MARK: - Content State (Dynamic, changes during activity lifetime)
    public struct ContentState: Codable, Hashable {
        // Common session data
        var sessionType: String  // "timer", "schedule", "task", "location", "steps", "sleep"
        var sessionName: String
        var statusText: String

        // Timer-specific data
        var timerEndDate: Date?
        var timerDuration: TimeInterval?

        // Schedule-specific data
        var scheduleEndTime: String?
        var scheduleIsActive: Bool?

        // Task-specific data
        var taskProgress: TaskProgress?

        // Location-specific data
        var locationTriggerType: String?
        var locationIsInside: Bool?

        // Steps-specific data
        var stepsProgress: StepsProgress?

        // Sleep-specific data
        var sleepWakeTime: String?
        var sleepIsActive: Bool?

        // Common metadata
        var blockedAppsCount: Int
        var sessionId: String
    }

    // MARK: - Static Attributes (Never change during activity lifetime)
    let sessionStartTime: Date
    let primaryColor: String  // Hex color for session type
}

// MARK: - Supporting Structures

@available(iOS 16.1, *)
struct TaskProgress: Codable, Hashable {
    let completed: Int
    let total: Int

    var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var progressText: String {
        return "\(completed)/\(total)"
    }
}

@available(iOS 16.1, *)
struct StepsProgress: Codable, Hashable {
    let current: Int
    let target: Int

    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var progressText: String {
        return "\(current)/\(target)"
    }

    var remainingSteps: Int {
        return max(target - current, 0)
    }
}

// MARK: - Session Type Colors
@available(iOS 16.1, *)
extension BlockingActivityAttributes {
    static func colorForSessionType(_ type: String) -> String {
        switch type.lowercased() {
        case "timer":
            return "#FF6B35"  // Orange
        case "schedule":
            return "#1CB0F6"  // Blue
        case "task":
            return "#58CC02"  // Green
        case "location":
            return "#8B5CF6"  // Purple
        case "steps":
            return "#F59E0B"  // Amber
        case "sleep":
            return "#4C1D95"  // Deep Purple
        default:
            return "#6B7280"  // Gray
        }
    }

    static func iconForSessionType(_ type: String) -> String {
        switch type.lowercased() {
        case "timer":
            return "timer"
        case "schedule":
            return "calendar"
        case "task":
            return "checkmark.circle.fill"
        case "location":
            return "location.fill"
        case "steps":
            return "figure.walk"
        case "sleep":
            return "moon.fill"
        default:
            return "lock.fill"
        }
    }
}
