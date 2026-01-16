import ActivityKit
import Foundation
import SwiftUI

// MARK: - Live Activity Manager
// Centralized manager for creating, updating, and ending Live Activities for blocking sessions

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    // Track all active Live Activities by session ID
    @Published var activeActivities: [String: Activity<BlockingActivityAttributes>] = [:]

    private init() {
        print("🎬 LiveActivityManager initialized")
    }

    // MARK: - Public API

    /// Start a new Live Activity for a blocking session
    func startActivity(
        sessionId: String,
        sessionType: String,
        sessionName: String,
        contentState: BlockingActivityAttributes.ContentState,
        primaryColor: String? = nil
    ) throws {
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities not authorized")
            throw LiveActivityError.notAuthorized
        }

        // Check if activity already exists
        if activeActivities[sessionId] != nil {
            print("⚠️ Live Activity already exists for session: \(sessionId)")
            return
        }

        // Create attributes
        let attributes = BlockingActivityAttributes(
            sessionStartTime: Date(),
            primaryColor: primaryColor ?? BlockingActivityAttributes.colorForSessionType(sessionType)
        )

        do {
            // Request activity from ActivityKit
            let activity = try Activity<BlockingActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil  // Can add push notifications later for remote updates
            )

            // Store activity reference
            activeActivities[sessionId] = activity
            print("✅ Started Live Activity for \(sessionType): \(sessionId)")
            print("   Activity ID: \(activity.id)")
            print("   Session Name: \(sessionName)")
            print("   Blocked Apps: \(contentState.blockedAppsCount)")

        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
            throw LiveActivityError.activityFailed(error)
        }
    }

    /// Update an existing Live Activity with new content state
    func updateActivity(sessionId: String, contentState: BlockingActivityAttributes.ContentState) async {
        guard let activity = activeActivities[sessionId] else {
            print("⚠️ No Live Activity found for session: \(sessionId)")
            return
        }

        do {
            await activity.update(using: contentState)
            print("🔄 Updated Live Activity: \(sessionId)")
            print("   Status: \(contentState.statusText)")

        } catch {
            print("❌ Failed to update Live Activity: \(error.localizedDescription)")
        }
    }

    /// End a Live Activity
    func endActivity(
        sessionId: String,
        finalState: BlockingActivityAttributes.ContentState? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default
    ) async {
        guard let activity = activeActivities[sessionId] else {
            print("⚠️ No Live Activity found to end: \(sessionId)")
            return
        }

        do {
            await activity.end(using: finalState, dismissalPolicy: dismissalPolicy)
            activeActivities.removeValue(forKey: sessionId)
            print("🛑 Ended Live Activity: \(sessionId)")
            print("   Dismissal Policy: \(dismissalPolicy)")

        } catch {
            print("❌ Failed to end Live Activity: \(error.localizedDescription)")
        }
    }

    /// End all active Live Activities (useful for cleanup)
    func endAllActivities(dismissalPolicy: ActivityUIDismissalPolicy = .default) async {
        print("🛑 Ending all Live Activities (\(activeActivities.count) active)")

        for (sessionId, _) in activeActivities {
            await endActivity(sessionId: sessionId, dismissalPolicy: dismissalPolicy)
        }
    }

    /// Check if a specific session has an active Live Activity
    func hasActivity(for sessionId: String) -> Bool {
        return activeActivities[sessionId] != nil
    }

    /// Get the current state of a Live Activity
    func getActivityState(for sessionId: String) -> BlockingActivityAttributes.ContentState? {
        guard let activity = activeActivities[sessionId] else { return nil }
        return activity.contentState
    }

    // MARK: - Activity Authorization

    /// Check if Live Activities are authorized
    var areActivitiesEnabled: Bool {
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Get authorization status
    var authorizationStatus: ActivityAuthorizationInfo {
        return ActivityAuthorizationInfo()
    }
}

// MARK: - Errors

enum LiveActivityError: Error, LocalizedError {
    case notAuthorized
    case activityFailed(Error)
    case notFound

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Live Activities are not authorized. User must enable them in Settings."
        case .activityFailed(let error):
            return "Failed to perform Live Activity operation: \(error.localizedDescription)"
        case .notFound:
            return "Live Activity not found for the specified session."
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 16.1, *)
extension LiveActivityManager {

    /// Create content state for a timer session
    func createTimerContentState(
        sessionName: String,
        endDate: Date,
        duration: TimeInterval,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        return BlockingActivityAttributes.ContentState(
            sessionType: "timer",
            sessionName: sessionName,
            statusText: "Active",
            timerEndDate: endDate,
            timerDuration: duration,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }

    /// Create content state for a steps session
    func createStepsContentState(
        sessionName: String,
        currentSteps: Int,
        targetSteps: Int,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        let progress = StepsProgress(current: currentSteps, target: targetSteps)
        let statusText = currentSteps >= targetSteps ? "Goal Reached!" : "\(progress.remainingSteps) steps to go"

        return BlockingActivityAttributes.ContentState(
            sessionType: "steps",
            sessionName: sessionName,
            statusText: statusText,
            stepsProgress: progress,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }

    /// Create content state for a task session
    func createTaskContentState(
        sessionName: String,
        completedTasks: Int,
        totalTasks: Int,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        let progress = TaskProgress(completed: completedTasks, total: totalTasks)
        let statusText = completedTasks >= totalTasks ? "All Tasks Done!" : "\(totalTasks - completedTasks) tasks left"

        return BlockingActivityAttributes.ContentState(
            sessionType: "task",
            sessionName: sessionName,
            statusText: statusText,
            taskProgress: progress,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }

    /// Create content state for a location session
    func createLocationContentState(
        sessionName: String,
        triggerType: String,
        isInside: Bool,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        let statusText = isInside ? "Inside Location" : "Outside Location"

        return BlockingActivityAttributes.ContentState(
            sessionType: "location",
            sessionName: sessionName,
            statusText: statusText,
            locationTriggerType: triggerType,
            locationIsInside: isInside,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }

    /// Create content state for a schedule session
    func createScheduleContentState(
        sessionName: String,
        endTime: String,
        isActive: Bool,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        let statusText = isActive ? "Schedule Active" : "Outside Schedule"

        return BlockingActivityAttributes.ContentState(
            sessionType: "schedule",
            sessionName: sessionName,
            statusText: statusText,
            scheduleEndTime: endTime,
            scheduleIsActive: isActive,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }

    /// Create content state for a sleep session
    func createSleepContentState(
        sessionName: String,
        wakeTime: String,
        isActive: Bool,
        blockedAppsCount: Int,
        sessionId: String
    ) -> BlockingActivityAttributes.ContentState {
        let statusText = isActive ? "Sleep Mode Active" : "Awake"

        return BlockingActivityAttributes.ContentState(
            sessionType: "sleep",
            sessionName: sessionName,
            statusText: statusText,
            sleepWakeTime: wakeTime,
            sleepIsActive: isActive,
            blockedAppsCount: blockedAppsCount,
            sessionId: sessionId
        )
    }
}
