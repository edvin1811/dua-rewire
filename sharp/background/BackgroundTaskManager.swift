import BackgroundTasks
import Foundation

// MARK: - Background Task Manager
// Handles BGTaskScheduler registration and execution for background session monitoring

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    // Task identifiers (must match Info.plist BGTaskSchedulerPermittedIdentifiers)
    static let sessionCheckTaskID = "com.coolstudio.sharp.sessioncheck"
    static let stepsUpdateTaskID = "com.coolstudio.sharp.stepsupdate"

    private init() {
        print("⏰ BackgroundTaskManager initialized")
    }

    // MARK: - Registration

    /// Register background tasks with BGTaskScheduler
    /// Call this early in app launch (from App.init or AppDelegate)
    func registerBackgroundTasks() {
        // Register app refresh task for session checks
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.sessionCheckTaskID,
            using: nil
        ) { task in
            self.handleSessionCheck(task: task as! BGAppRefreshTask)
        }

        // Register processing task for steps updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.stepsUpdateTaskID,
            using: nil
        ) { task in
            self.handleStepsUpdate(task: task as! BGProcessingTask)
        }

        print("✅ Registered background tasks:")
        print("   - \(Self.sessionCheckTaskID)")
        print("   - \(Self.stepsUpdateTaskID)")
    }

    // MARK: - Session Check Handler (BGAppRefreshTask)

    private func handleSessionCheck(task: BGAppRefreshTask) {
        print("🔄 Background: Session check task started")

        // Schedule next session check before processing
        scheduleNextSessionCheck()

        // Create operation queue for background work
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = SessionCheckOperation()

        // Handle task expiration
        task.expirationHandler = {
            print("⚠️ Session check task expired, cancelling operations")
            queue.cancelAllOperations()
        }

        // Complete task when operation finishes
        operation.completionBlock = {
            let success = !operation.isCancelled
            task.setTaskCompleted(success: success)
            print(success ? "✅ Session check completed" : "⚠️ Session check cancelled")
        }

        queue.addOperation(operation)
    }

    // MARK: - Steps Update Handler (BGProcessingTask)

    private func handleStepsUpdate(task: BGProcessingTask) {
        print("🔄 Background: Steps update task started")

        // Schedule next steps update
        scheduleNextStepsUpdate()

        // Handle steps monitoring asynchronously
        Task {
            do {
                // Check if steps session is active
                let stepsSession = BlockingSessionManager.shared.activeStepsSession

                if let session = stepsSession {
                    print("📊 Active steps session found: \(session.name)")

                    // Fetch latest steps from HealthKit
                    let stepsManager = StepsManager()
                    let currentSteps = try await stepsManager.fetchTodaySteps()

                    print("👟 Current steps: \(currentSteps), Target: \(session.targetSteps)")

                    // Check if goal reached
                    if currentSteps >= session.targetSteps {
                        print("🎉 Background: Steps goal reached!")

                        // Send notification
                        await NotificationManager.shared.sendStepsGoalReached(
                            steps: currentSteps,
                            target: session.targetSteps
                        )

                        // Update Live Activity if available
                        if #available(iOS 16.1, *) {
                            let contentState = LiveActivityManager.shared.createStepsContentState(
                                sessionName: session.name,
                                currentSteps: currentSteps,
                                targetSteps: session.targetSteps,
                                blockedAppsCount: 0,  // Will be unlocked
                                sessionId: session.id.uuidString
                            )

                            await LiveActivityManager.shared.updateActivity(
                                sessionId: "steps-\(session.id.uuidString)",
                                contentState: contentState
                            )
                        }

                        // Set flag for app to end session on next launch
                        UserDefaults.standard.set(true, forKey: "pendingStepsGoalReached")
                        UserDefaults.standard.set(session.id.uuidString, forKey: "pendingStepsSessionId")

                        print("✅ Set flag for app to end steps session")
                    } else {
                        // Update progress in Live Activity
                        if #available(iOS 16.1, *) {
                            // Get blocked apps count from session manager
                            let selection = BlockingSessionManager.shared.getSessionSelection(for: "steps-\(session.id.uuidString)")
                            let blockedAppsCount = selection?.applicationTokens.count ?? 0

                            let contentState = LiveActivityManager.shared.createStepsContentState(
                                sessionName: session.name,
                                currentSteps: currentSteps,
                                targetSteps: session.targetSteps,
                                blockedAppsCount: blockedAppsCount,
                                sessionId: session.id.uuidString
                            )

                            await LiveActivityManager.shared.updateActivity(
                                sessionId: "steps-\(session.id.uuidString)",
                                contentState: contentState
                            )
                        }
                    }
                } else {
                    print("ℹ️ No active steps session")
                }

                task.setTaskCompleted(success: true)

            } catch {
                print("❌ Background steps update failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule next session check (BGAppRefreshTask)
    /// Runs every 15-60 minutes to check session states
    func scheduleNextSessionCheck() {
        let request = BGAppRefreshTaskRequest(identifier: Self.sessionCheckTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Scheduled next session check (in 15+ min)")
        } catch {
            print("❌ Failed to schedule session check: \(error.localizedDescription)")
        }
    }

    /// Schedule next steps update (BGProcessingTask)
    /// Runs every 30+ minutes to update step progress
    func scheduleNextStepsUpdate() {
        let request = BGProcessingTaskRequest(identifier: Self.stepsUpdateTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Scheduled next steps update (in 30+ min)")
        } catch {
            print("❌ Failed to schedule steps update: \(error.localizedDescription)")
        }
    }

    /// Cancel all pending background tasks
    func cancelAllPendingTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.sessionCheckTaskID)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.stepsUpdateTaskID)
        print("🛑 Cancelled all pending background tasks")
    }
}

// MARK: - Session Check Operation

/// Operation for checking session states in background
class SessionCheckOperation: Operation {

    override func main() {
        guard !isCancelled else {
            print("⚠️ Session check operation cancelled before start")
            return
        }

        print("🔍 Checking session states...")

        // Check timer sessions
        checkTimerSessions()

        // Check schedule sessions
        checkScheduleSessions()

        // Check sleep sessions
        checkSleepSessions()

        print("✅ Session check operation completed")
    }

    private func checkTimerSessions() {
        guard !isCancelled else { return }

        if let timer = BlockingSessionManager.shared.activeTimerSession {
            let timeRemaining = timer.timeRemaining

            if timeRemaining <= 0 {
                print("⏰ Background: Timer expired - \(timer.name)")

                // Set flag for app to process on next launch
                UserDefaults.standard.set(true, forKey: "pendingTimerExpiration")
                UserDefaults.standard.set(timer.id.uuidString, forKey: "pendingTimerId")

                // Send notification
                Task {
                    await NotificationManager.shared.sendTimerExpired(
                        sessionName: timer.name,
                        duration: timer.duration
                    )
                }
            } else {
                print("⏱️ Timer still running: \(Int(timeRemaining))s remaining")
            }
        }
    }

    private func checkScheduleSessions() {
        guard !isCancelled else { return }

        if let schedule = BlockingSessionManager.shared.activeScheduleSession {
            let isCurrentlyInSchedule = schedule.isCurrentlyInSchedule

            if !isCurrentlyInSchedule {
                print("📅 Background: Outside schedule window - \(schedule.name)")

                // Set flag for app to process
                UserDefaults.standard.set(true, forKey: "pendingScheduleExit")
                UserDefaults.standard.set(schedule.id.uuidString, forKey: "pendingScheduleId")

                // Send notification
                Task {
                    await NotificationManager.shared.sendScheduleEnded(sessionName: schedule.name)
                }
            } else {
                print("📅 Schedule still active: \(schedule.name)")
            }
        }
    }

    private func checkSleepSessions() {
        guard !isCancelled else { return }

        if let sleep = BlockingSessionManager.shared.activeSleepSession {
            let isCurrentlySleepTime = sleep.isCurrentlySleepTime

            if !isCurrentlySleepTime {
                print("😴 Background: Sleep time ended - \(sleep.name)")

                // Set flag for app to process
                UserDefaults.standard.set(true, forKey: "pendingSleepExit")
                UserDefaults.standard.set(sleep.id.uuidString, forKey: "pendingSleepId")

                // Send notification
                Task {
                    await NotificationManager.shared.sendSleepModeEnded()
                }
            } else {
                print("😴 Sleep mode still active: \(sleep.name)")
            }
        }
    }
}

// MARK: - Background Task Simulator (Development Only)

#if DEBUG
extension BackgroundTaskManager {
    /// Simulate background task execution (for testing in Xcode)
    /// Call this from Xcode debugger console:
    /// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.coolstudio.sharp.sessioncheck"]
    func simulateSessionCheck() {
        print("🧪 Simulating session check task...")
        let operation = SessionCheckOperation()
        operation.start()
        operation.waitUntilFinished()
        print("✅ Simulation complete")
    }

    func simulateStepsUpdate() {
        print("🧪 Simulating steps update task...")
        Task {
            let stepsManager = StepsManager()
            if let steps = try? await stepsManager.fetchTodaySteps() {
                print("📊 Simulated steps: \(steps)")
            }
        }
    }
}
#endif
