import UserNotifications
import Foundation

// MARK: - Notification Manager
// Centralized manager for sending local notifications for blocking session events

class NotificationManager {
    static let shared = NotificationManager()

    private init() {
        print("📬 NotificationManager initialized")
    }

    // MARK: - Authorization

    /// Request notification authorization from user
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        do {
            let granted = try await center.requestAuthorization(options: options)
            if granted {
                print("✅ Notification authorization granted")
            } else {
                print("⚠️ Notification authorization denied")
            }
        } catch {
            print("❌ Failed to request notification authorization: \(error.localizedDescription)")
            throw error
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Timer Notifications

    /// Send notification when timer expires
    func sendTimerExpired(sessionName: String, duration: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "Timer Completed"
        content.body = "\(sessionName) has ended. Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "TIMER_EXPIRED"
        content.badge = 0

        await sendNotification(identifier: "timer-\(UUID().uuidString)", content: content)
    }

    // MARK: - Steps Notifications

    /// Send notification when step goal is reached
    func sendStepsGoalReached(steps: Int, target: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Step Goal Reached!"
        content.body = "You've walked \(steps) steps (goal: \(target)). Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "STEPS_GOAL"
        content.badge = 0

        await sendNotification(identifier: "steps-\(UUID().uuidString)", content: content)
    }

    /// Send notification for steps progress milestone
    func sendStepsProgress(currentSteps: Int, targetSteps: Int, percentage: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Steps Progress: \(percentage)%"
        content.body = "\(currentSteps)/\(targetSteps) steps completed. Keep going!"
        content.sound = nil  // Silent notification
        content.categoryIdentifier = "STEPS_PROGRESS"

        await sendNotification(identifier: "steps-progress-\(UUID().uuidString)", content: content)
    }

    // MARK: - Location Notifications

    /// Send notification when entering a monitored location
    func sendLocationEntered(locationName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Location Blocking Active"
        content.body = "You've entered \(locationName). Apps are now blocked."
        content.sound = .default
        content.categoryIdentifier = "LOCATION_ENTER"
        content.badge = 0

        await sendNotification(identifier: "location-enter-\(UUID().uuidString)", content: content)
    }

    /// Send notification when exiting a monitored location
    func sendLocationExited(locationName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Location Blocking Ended"
        content.body = "You've left \(locationName). Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "LOCATION_EXIT"
        content.badge = 0

        await sendNotification(identifier: "location-exit-\(UUID().uuidString)", content: content)
    }

    // MARK: - Task Notifications

    /// Send notification when all tasks are completed
    func sendTasksCompleted(taskCount: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Tasks Completed!"
        content.body = "All \(taskCount) tasks finished. Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "TASKS_DONE"
        content.badge = 0

        await sendNotification(identifier: "tasks-\(UUID().uuidString)", content: content)
    }

    /// Send notification for task progress
    func sendTaskProgress(completed: Int, total: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "Task Progress"
        content.body = "\(completed)/\(total) tasks completed. \(total - completed) remaining."
        content.sound = nil  // Silent notification
        content.categoryIdentifier = "TASK_PROGRESS"

        await sendNotification(identifier: "task-progress-\(UUID().uuidString)", content: content)
    }

    // MARK: - Schedule Notifications

    /// Send notification when schedule starts
    func sendScheduleStarted(sessionName: String, endTime: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Schedule Started"
        content.body = "\(sessionName) is now active until \(endTime). Apps are blocked."
        content.sound = .default
        content.categoryIdentifier = "SCHEDULE_START"
        content.badge = 0

        await sendNotification(identifier: "schedule-start-\(UUID().uuidString)", content: content)
    }

    /// Send notification when schedule ends
    func sendScheduleEnded(sessionName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Schedule Ended"
        content.body = "\(sessionName) has ended. Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "SCHEDULE_END"
        content.badge = 0

        await sendNotification(identifier: "schedule-end-\(UUID().uuidString)", content: content)
    }

    // MARK: - Sleep Notifications

    /// Send notification when sleep mode starts
    func sendSleepModeStarted(wakeTime: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Sleep Mode Active"
        content.body = "Good night! Apps are blocked until \(wakeTime)."
        content.sound = .default
        content.categoryIdentifier = "SLEEP_START"
        content.badge = 0

        await sendNotification(identifier: "sleep-start-\(UUID().uuidString)", content: content)
    }

    /// Send notification when sleep mode ends
    func sendSleepModeEnded() async {
        let content = UNMutableNotificationContent()
        content.title = "Good Morning!"
        content.body = "Sleep mode has ended. Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "SLEEP_END"
        content.badge = 0

        await sendNotification(identifier: "sleep-end-\(UUID().uuidString)", content: content)
    }

    // MARK: - Generic Session Notifications

    /// Send notification for generic session end
    func sendSessionEnded(sessionType: String, sessionName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Session Ended"
        content.body = "\(sessionName) (\(sessionType)) has ended. Apps are now unlocked."
        content.sound = .default
        content.categoryIdentifier = "SESSION_END"
        content.badge = 0

        await sendNotification(identifier: "session-end-\(UUID().uuidString)", content: content)
    }

    // MARK: - Private Helper

    /// Send a notification with given identifier and content
    private func sendNotification(identifier: String, content: UNMutableNotificationContent) async {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil  // Immediate delivery
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📬 Sent notification: \(content.title)")
        } catch {
            print("❌ Failed to send notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Management

    /// Remove all delivered notifications
    func removeAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🧹 Removed all delivered notifications")
    }

    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🧹 Removed all pending notifications")
    }

    /// Remove notifications for a specific category
    func removeNotifications(forCategory category: String) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiers = notifications
                .filter { $0.request.content.categoryIdentifier == category }
                .map { $0.request.identifier }

            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            print("🧹 Removed \(identifiers.count) notifications for category: \(category)")
        }
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    /// Register notification categories with actions
    func registerNotificationCategories() {
        // Timer category
        let timerCategory = UNNotificationCategory(
            identifier: "TIMER_EXPIRED",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Steps category
        let stepsCategory = UNNotificationCategory(
            identifier: "STEPS_GOAL",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Location categories
        let locationEnterCategory = UNNotificationCategory(
            identifier: "LOCATION_ENTER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let locationExitCategory = UNNotificationCategory(
            identifier: "LOCATION_EXIT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Task category
        let taskCategory = UNNotificationCategory(
            identifier: "TASKS_DONE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Schedule categories
        let scheduleStartCategory = UNNotificationCategory(
            identifier: "SCHEDULE_START",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let scheduleEndCategory = UNNotificationCategory(
            identifier: "SCHEDULE_END",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Sleep categories
        let sleepStartCategory = UNNotificationCategory(
            identifier: "SLEEP_START",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let sleepEndCategory = UNNotificationCategory(
            identifier: "SLEEP_END",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Register all categories
        let categories: Set<UNNotificationCategory> = [
            timerCategory,
            stepsCategory,
            locationEnterCategory,
            locationExitCategory,
            taskCategory,
            scheduleStartCategory,
            scheduleEndCategory,
            sleepStartCategory,
            sleepEndCategory
        ]

        UNUserNotificationCenter.current().setNotificationCategories(categories)
        print("✅ Registered \(categories.count) notification categories")
    }
}
