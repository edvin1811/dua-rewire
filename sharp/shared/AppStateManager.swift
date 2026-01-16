import Foundation
import SwiftUI
import Combine
import CoreData
import FamilyControls
import DeviceActivity

// MARK: - Enhanced App State Manager (Centralized Global State)
class AppStateManager: ObservableObject {
    // MARK: - Published State
    @Published var familyControlsManager = FamilyControlsManager()
    @Published var showRestorationMessage = false
    @Published var restorationMessage = ""
    
    // Authorization & Monitoring State
    @Published var authorizationState: AuthorizationState = .unknown
    @Published var monitoringState: MonitoringState = .stopped
    @Published var globalError: AppError?
    
    // Session State (Blocking)
    private var fallbackTimer: Timer?
    @Published var locationManager = LocationManager()
    @Published var stepsManager = StepsManager()
    @Published var activeTaskSession: TaskBlockingSession?
    @Published var activeTimerSession: TimerBlockingSession?
    @Published var sessionState: SessionState = .none
    
    // MARK: - Private Properties
    private var sessionManager = BlockingSessionManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialized = false
    private var hasRestoredSessions = false
    
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Initialization
    init() {
        setupSessionObservers()
        setupAuthorizationObserver()
    }
    
    // MARK: - App Lifecycle Management
    
    func initializeApp() {
        guard !hasInitialized else { return }

        print("🚀 AppStateManager: Initializing app...")

        requestAuthorizationIfNeeded()
        setupAutoUnlockFallback()

        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
        print("✅ Background tasks registered")

        // Enable HealthKit background delivery
        stepsManager.enableBackgroundDelivery()
        print("✅ HealthKit background delivery enabled")

        // Request notification permissions
        Task {
            do {
                try await NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.registerNotificationCategories()
                print("✅ Notification permissions granted and categories registered")
            } catch {
                print("⚠️ Notification authorization failed: \(error)")
            }
        }

        hasInitialized = true
    }
    
    func handleMainAppAppear() {
        // Handle session restoration when main app appears
        restoreSessionsIfNeeded()
        
        // Ensure monitoring is active if authorized
        ensureMonitoringActive()
    }
    
    func handleAppForeground() {
        print("🔄 AppStateManager: App came to foreground")

        // Re-check authorization status
        checkAuthorizationStatus()

        // Re-check sessions
        if hasRestoredSessions {
            sessionManager.restoreSessionsIfNeeded(
                familyControlsManager: familyControlsManager,
                context: persistenceController.container.viewContext,
                stepsManager: stepsManager,
                locationManager: locationManager
            )
        }

        // Ensure monitoring is still active
        ensureMonitoringActive()
    }

    func handleAppBackground() {
        print("🌙 AppStateManager: App going to background")

        // Schedule background tasks for session checking and steps updates
        BackgroundTaskManager.shared.scheduleNextSessionCheck()
        BackgroundTaskManager.shared.scheduleNextStepsUpdate()

        print("✅ Background tasks scheduled")
    }
    
    // MARK: - Authorization Management (Centralized)
    
    func requestAuthorizationIfNeeded() {
        guard authorizationState != .granted else {
            // Already authorized, ensure monitoring is active
            ensureMonitoringActive()
            return
        }
        
        authorizationState = .requesting
        familyControlsManager.requestAuthorization()
    }
    
    private func checkAuthorizationStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            if authorizationState != .granted {
                authorizationState = .granted
                ensureMonitoringActive()
            }
        case .denied:
            authorizationState = .denied
            monitoringState = .failed("Authorization denied")
        case .notDetermined:
            authorizationState = .unknown
        @unknown default:
            authorizationState = .unknown
        }
    }
    
    private func setupAuthorizationObserver() {
        familyControlsManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                DispatchQueue.main.async {
                    if isAuthorized {
                        self?.authorizationState = .granted
                        self?.ensureMonitoringActive()
                    } else {
                        self?.authorizationState = .denied
                        self?.monitoringState = .stopped
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Monitoring Management (Centralized)
    
    private func ensureMonitoringActive() {
        guard authorizationState == .granted else {
            print("⚠️ Cannot start monitoring: Not authorized")
            return
        }
        
        guard monitoringState != .active else {
            print("✅ Monitoring already active")
            return
        }
        
        startScreenTimeMonitoring()
    }
    
    private func startScreenTimeMonitoring() {
        print("🔄 AppStateManager: Starting screen time monitoring")
        monitoringState = .starting
        
        familyControlsManager.startAutoScreenTimeMonitoring()
        
        // Monitor the monitoring state
        familyControlsManager.$isMonitoring
            .sink { [weak self] isMonitoring in
                DispatchQueue.main.async {
                    if isMonitoring {
                        self?.monitoringState = .active
                        self?.globalError = nil
                    } else if self?.monitoringState == .starting {
                        self?.monitoringState = .failed("Failed to start monitoring")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func restartMonitoring() {
        print("🔄 AppStateManager: Restarting monitoring...")
        monitoringState = .restarting
        
        familyControlsManager.restartMonitoring()
        
        // Will be handled by the monitoring observer
    }
    
    // MARK: - Session Management (Centralized)
    
    private func setupSessionObservers() {
        // Observe session manager state for Timer and Task
        sessionManager.$activeTaskSession
            .sink { [weak self] session in
                DispatchQueue.main.async {
                    self?.activeTaskSession = session
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
        
        sessionManager.$activeTimerSession
            .sink { [weak self] session in
                DispatchQueue.main.async {
                    self?.activeTimerSession = session
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
        
        // Observe schedule session
        sessionManager.$activeScheduleSession
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
        
        // Observe location session
        sessionManager.$activeLocationSession
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
        
        // Observe steps session
        sessionManager.$activeStepsSession
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
        
        // Observe sleep session
        sessionManager.$activeSleepSession
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateSessionState()
                }
            }
            .store(in: &cancellables)
    }
    
    func setupAutoUnlockFallback() {
        // Check every minute for sessions that should have ended
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkPendingUnlocks()
        }
    }

    private func checkPendingUnlocks() {
        // Check timer sessions
        if let timer = activeTimerSession {
            if timer.timeRemaining <= 0 {
                print("⏰ Fallback: Timer expired, forcing unlock")
                BlockingSessionManager.shared.endTimerSession(familyControlsManager: familyControlsManager)
            }
        }
        
        // Check schedule sessions
        if let schedule = BlockingSessionManager.shared.activeScheduleSession {
            if !schedule.isCurrentlyInSchedule {
                print("📅 Fallback: Outside schedule, checking blocking")
                familyControlsManager.removeBlocking(sessionId: "schedule-\(schedule.id.uuidString)")
            }
        }
        
        // Check sleep sessions
        if let sleep = BlockingSessionManager.shared.activeSleepSession {
            if !sleep.isCurrentlySleepTime {
                print("😴 Fallback: Sleep time ended, checking blocking")
                familyControlsManager.removeBlocking(sessionId: "sleep-\(sleep.id.uuidString)")
            }
        }
    }
    
    private func updateSessionState() {
        let hasTask = activeTaskSession != nil
        let hasTimer = activeTimerSession != nil
        let hasSchedule = sessionManager.activeScheduleSession != nil
        let hasLocation = sessionManager.activeLocationSession != nil
        let hasSteps = sessionManager.activeStepsSession != nil
        let hasSleep = sessionManager.activeSleepSession != nil
        
        let totalSessions = [hasTask, hasTimer, hasSchedule, hasLocation, hasSteps, hasSleep].filter { $0 }.count
        
        if totalSessions > 1 {
            sessionState = .both
        } else if hasTask {
            sessionState = .taskBlocking
        } else if hasTimer {
            sessionState = .timerBlocking
        } else {
            sessionState = .none
        }
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func restoreSessionsIfNeeded() {
        guard !hasRestoredSessions else { return }
        
        print("🔄 AppStateManager: Restoring sessions on app launch...")
        
        // Check if there were any persisted sessions before restoration
        let hadPersistedSessions = UserDefaults.standard.data(forKey: "activeTaskBlockingSession") != nil ||
                                 UserDefaults.standard.data(forKey: "activeTimerBlockingSession") != nil
        
        sessionManager.restoreSessionsIfNeeded(
            familyControlsManager: familyControlsManager,
            context: persistenceController.container.viewContext,
            stepsManager: stepsManager,
            locationManager: locationManager
        )
        hasRestoredSessions = true
        
        // Show session status if any were restored
        if sessionManager.isAnySessionActive && hadPersistedSessions {
            showSessionRestorationMessage()
        }
    }
    
    private func showSessionRestorationMessage() {
        print("✅ Active sessions restored: \(activeSessionDescription)")
        
        restorationMessage = "Session restored: \(activeSessionDescription)"
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showRestorationMessage = true
        }
        
        // Hide message after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.showRestorationMessage = false
            }
        }
    }
    
    func hideRestorationMessage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showRestorationMessage = false
        }
    }
    
    // MARK: - Cross-Feature Coordination
    
    func handleTaskCompletion(context: NSManagedObjectContext) {
        // Centralized task completion handling
        guard let taskSession = activeTaskSession else { return }
        
        // Check if all tasks in the session are completed
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "taskId IN %@", taskSession.taskIds)
        
        do {
            let tasks = try context.fetch(request)
            let completedTasks = tasks.filter { $0.taskIsCompleted }
            
            if completedTasks.count == tasks.count && tasks.count > 0 {
                print("🎉 AppStateManager: All tasks completed - ending session")
                sessionManager.endTaskSession(familyControlsManager: familyControlsManager)
                
                // Could trigger notification, analytics, etc.
                handleSessionCompletion(type: .taskBlocking)
            }
        } catch {
            globalError = .taskCheckFailed(error.localizedDescription)
        }
    }
    
    private func handleSessionCompletion(type: SessionState) {
        // Handle any post-completion logic
        print("✅ Session completed: \(type)")
        
        // Could add:
        // - Local notifications
        // - Analytics events
        // - Achievement unlocks
        // - Usage statistics
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        globalError = nil
    }
    
    func handleError(_ error: AppError) {
        globalError = error
        print("❌ AppStateManager Error: \(error)")
    }
    
    // MARK: - Computed Properties

    var canUseBlockingFeatures: Bool {
        return authorizationState == .granted && monitoringState == .active
    }

    /// Total time apps have been blocked today (in seconds)
    var totalBlockedTimeToday: TimeInterval {
        let key = "blockedTimeToday"
        let dateKey = "blockedTimeTodayDate"

        // Check if it's still today
        let today = Calendar.current.startOfDay(for: Date())
        if let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
           Calendar.current.isDate(storedDate, inSameDayAs: today) {
            // Add any currently active session time
            var total = UserDefaults.standard.double(forKey: key)

            // Add time from active timer session
            if let timer = activeTimerSession {
                let elapsed = timer.duration - timer.timeRemaining
                total += elapsed
            }

            return total
        } else {
            // Reset for new day
            UserDefaults.standard.set(0.0, forKey: key)
            UserDefaults.standard.set(today, forKey: dateKey)
            return 0
        }
    }

    /// Add blocked time when a session ends
    func addBlockedTime(_ seconds: TimeInterval) {
        let key = "blockedTimeToday"
        let dateKey = "blockedTimeTodayDate"
        let today = Calendar.current.startOfDay(for: Date())

        // Reset if new day
        if let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
           !Calendar.current.isDate(storedDate, inSameDayAs: today) {
            UserDefaults.standard.set(0.0, forKey: key)
            UserDefaults.standard.set(today, forKey: dateKey)
        }

        let current = UserDefaults.standard.double(forKey: key)
        UserDefaults.standard.set(current + seconds, forKey: key)
        objectWillChange.send()
    }

    /// Number of completed focus sessions today
    var completedSessionsToday: Int {
        let key = "completedSessionsToday"
        let dateKey = "completedSessionsTodayDate"
        let today = Calendar.current.startOfDay(for: Date())

        if let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
           Calendar.current.isDate(storedDate, inSameDayAs: today) {
            return UserDefaults.standard.integer(forKey: key)
        } else {
            // Reset for new day
            UserDefaults.standard.set(0, forKey: key)
            UserDefaults.standard.set(today, forKey: dateKey)
            return 0
        }
    }

    /// Increment completed sessions when a session ends successfully
    func incrementCompletedSessions() {
        let key = "completedSessionsToday"
        let dateKey = "completedSessionsTodayDate"
        let today = Calendar.current.startOfDay(for: Date())

        // Reset if new day
        if let storedDate = UserDefaults.standard.object(forKey: dateKey) as? Date,
           !Calendar.current.isDate(storedDate, inSameDayAs: today) {
            UserDefaults.standard.set(0, forKey: key)
            UserDefaults.standard.set(today, forKey: dateKey)
        }

        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        objectWillChange.send()
    }

    var hasActiveSession: Bool {
        return activeTaskSession != nil ||
               activeTimerSession != nil ||
               sessionManager.activeScheduleSession != nil ||
               sessionManager.activeLocationSession != nil ||
               sessionManager.activeStepsSession != nil ||
               sessionManager.activeSleepSession != nil
    }
    
    var activeSessionDescription: String {
        var descriptions: [String] = []
        
        if let task = activeTaskSession {
            descriptions.append("Task: \(task.taskIds.count) tasks")
        }
        if let timer = activeTimerSession {
            descriptions.append("Timer: \(timer.name)")
        }
        if let schedule = sessionManager.activeScheduleSession {
            descriptions.append("Schedule: \(schedule.name)")
        }
        if let location = sessionManager.activeLocationSession {
            descriptions.append("Location: \(location.name)")
        }
        if let steps = sessionManager.activeStepsSession {
            descriptions.append("Steps: \(steps.name)")
        }
        if let sleep = sessionManager.activeSleepSession {
            descriptions.append("Sleep: \(sleep.name)")
        }
        
        return descriptions.isEmpty ? "No active sessions" : descriptions.joined(separator: ", ")
    }
    
    var statusDescription: String {
        switch (authorizationState, monitoringState) {
        case (.granted, .active):
            return "Ready"
        case (.granted, .starting):
            return "Starting monitoring..."
        case (.granted, .restarting):
            return "Restarting..."
        case (.requesting, _):
            return "Requesting authorization..."
        case (.denied, _):
            return "Authorization denied"
        case (.unknown, _):
            return "Not setup"
        case (_, .failed(let message)):
            return "Error: \(message)"
        case (_, .stopped):
            return "Monitoring stopped"
        }
    }
}

// MARK: - Supporting Types

enum AuthorizationState {
    case unknown
    case requesting
    case granted
    case denied
}

enum MonitoringState: Equatable {
    case stopped
    case starting
    case active
    case restarting
    case failed(String)
}

enum SessionState {
    case none
    case taskBlocking
    case timerBlocking
    case both
}

enum AppError: Error, LocalizedError {
    case authorizationFailed(String)
    case monitoringFailed(String)
    case sessionFailed(String)
    case taskCheckFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        case .monitoringFailed(let message):
            return "Monitoring failed: \(message)"
        case .sessionFailed(let message):
            return "Session failed: \(message)"
        case .taskCheckFailed(let message):
            return "Task check failed: \(message)"
        }
    }
}
