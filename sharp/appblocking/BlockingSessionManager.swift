import Foundation
import CoreData
import Combine
import FamilyControls
import UIKit
import SwiftUI
import ActivityKit

// MARK: - Codable Session Models for Persistence
struct PersistedTaskSession: Codable {
    let id: String
    let taskIds: [String]
    let startTime: Date
    var isActive: Bool
}

struct PersistedTimerSession: Codable {
    let id: String
    let name: String
    let duration: TimeInterval
    let startTime: Date
    var isActive: Bool
}

struct PersistedScheduleSession: Codable {
    let id: String
    let name: String
    let scheduleType: String
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let selectedDays: [Int]
    let startTime: Date
}

struct PersistedLocationSession: Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let locationName: String
    let triggerType: String
    let startTime: Date
}

struct PersistedStepsSession: Codable {
    let id: String
    let name: String
    let targetSteps: Int
    let resetDaily: Bool
    let startTime: Date
}

struct PersistedSleepSession: Codable {
    let id: String
    let name: String
    let bedtimeHour: Int
    let bedtimeMinute: Int
    let wakeupHour: Int
    let wakeupMinute: Int
    let enabledDays: [Int]
    let startTime: Date
}

// MARK: - Completed Session History
struct CompletedSession: Codable, Identifiable {
    let id: UUID
    let type: String // BlockingType rawValue
    let name: String
    let startTime: Date
    let endTime: Date
    let completed: Bool // true if ended normally, false if force-ended

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    var typeColor: Color {
        switch type {
        case "timer": return .accentOrange
        case "schedule": return .accentPurple
        case "task": return .accentGreen
        case "location": return .brandPrimary
        case "steps": return .accentYellow
        case "sleep": return Color(hex: "8B5CF6")
        default: return .textSecondary
        }
    }

    var typeIcon: String {
        switch type {
        case "timer": return "timer"
        case "schedule": return "calendar"
        case "task": return "checkmark.circle.fill"
        case "location": return "location.fill"
        case "steps": return "figure.walk"
        case "sleep": return "moon.stars.fill"
        default: return "app.badge"
        }
    }
}

// MARK: - Session Manager (Central coordinator)
class BlockingSessionManager: ObservableObject {
    static let shared = BlockingSessionManager()
    
    @Published var activeScheduleSession: ScheduleBlockingSession?
    @Published var activeLocationSession: LocationBlockingSession?
    @Published var activeStepsSession: StepBlockingSession?
    @Published var activeSleepSession: SleepBlockingSession?
    @Published var activeTaskSession: TaskBlockingSession?
    @Published var activeTimerSession: TimerBlockingSession?

    // NEW: Session history tracking
    @Published var sessionHistory: [CompletedSession] = []

    private weak var currentFamilyControlsManager: FamilyControlsManager?

    // NEW: Store app selections per session type
    private var sessionSelections: [String: FamilyActivitySelection] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private var taskObserver: NSFetchedResultsController<TaskEntity>?
    private var taskCompletionDelegate: TaskCompletionDelegate?
    private var timerWorkItem: DispatchWorkItem?
    private var scheduleTimer: Timer?
    private var scheduleFamilyControlsManager: FamilyControlsManager?
    private var sleepTimer: Timer?
    private weak var currentStepsManager: StepsManager?
    private weak var currentLocationManager: LocationManager?
    
    // UserDefaults keys for sessions
    private let taskSessionKey = "activeTaskBlockingSession"
    private let timerSessionKey = "activeTimerBlockingSession"
    private let scheduleSessionKey = "activeScheduleBlockingSession"
    private let locationSessionKey = "activeLocationBlockingSession"
    private let stepsSessionKey = "activeStepsBlockingSession"
    private let sleepSessionKey = "activeSleepBlockingSession"

    // UserDefaults keys for app selections
    private let taskSelectionKey = "taskSessionSelection"
    private let timerSelectionKey = "timerSessionSelection"
    private let scheduleSelectionKey = "scheduleSessionSelection"
    private let locationSelectionKey = "locationSessionSelection"
    private let stepsSelectionKey = "stepsSessionSelection"
    private let sleepSelectionKey = "sleepSessionSelection"

    // UserDefaults key for history
    private let sessionHistoryKey = "completedSessionHistory"

    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let wasForceQuitKey = "wasForceQuit"

    private init() {
        print("🚀 BlockingSessionManager initialized")

        // Load session history
        loadSessionHistory()

        // Check if app was force-quit
        checkForForceQuit()

        // Update timestamp when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        // Mark timestamp when app goes to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
        UserDefaults.standard.set(false, forKey: wasForceQuitKey)
    }

    @objc private func appWillResignActive() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }

    private func checkForForceQuit() {
        guard let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date else {
            print("📍 First launch - no force quit check")
            return
        }

        let timeSinceLastActive = Date().timeIntervalSince(lastActive)

        // If app was inactive for more than 5 seconds, likely was terminated
        if timeSinceLastActive > 5 {
            print("⚠️ App was likely force-quit or terminated (\(Int(timeSinceLastActive))s since last active)")
            UserDefaults.standard.set(true, forKey: wasForceQuitKey)
        } else {
            print("✅ App resumed normally (\(Int(timeSinceLastActive))s since last active)")
        }
    }

    var wasForceQuit: Bool {
        return UserDefaults.standard.bool(forKey: wasForceQuitKey)
    }
    
    // MARK: - Session Selection Management

    func setSessionSelection(_ selection: FamilyActivitySelection, for sessionType: String) {
        sessionSelections[sessionType] = selection
        persistSelection(selection, for: sessionType)
        print("💾 Stored and persisted selection for \(sessionType): \(selection.applicationTokens.count) apps")
    }

    func getSessionSelection(for sessionType: String) -> FamilyActivitySelection? {
        // First check in-memory cache
        if let cached = sessionSelections[sessionType] {
            return cached
        }
        // Then try to load from UserDefaults
        if let loaded = loadPersistedSelection(for: sessionType) {
            sessionSelections[sessionType] = loaded
            return loaded
        }
        return nil
    }

    // Persist FamilyActivitySelection to UserDefaults
    private func persistSelection(_ selection: FamilyActivitySelection, for sessionType: String) {
        let key = selectionKey(for: sessionType)

        // Encode the selection as Data using JSONEncoder
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.standard.set(data, forKey: key)
            print("💾 Persisted selection for \(sessionType)")
        } catch {
            print("❌ Failed to persist selection for \(sessionType): \(error)")
        }
    }

    // Load FamilyActivitySelection from UserDefaults
    private func loadPersistedSelection(for sessionType: String) -> FamilyActivitySelection? {
        let key = selectionKey(for: sessionType)

        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }

        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            print("📥 Loaded persisted selection for \(sessionType): \(selection.applicationTokens.count) apps")
            return selection
        } catch {
            print("❌ Failed to load selection for \(sessionType): \(error)")
        }

        return nil
    }

    // Remove persisted selection
    private func removePersistedSelection(for sessionType: String) {
        let key = selectionKey(for: sessionType)
        UserDefaults.standard.removeObject(forKey: key)
    }

    // Get the UserDefaults key for a session type
    private func selectionKey(for sessionType: String) -> String {
        switch sessionType {
        case "task": return taskSelectionKey
        case "timer": return timerSelectionKey
        case "schedule": return scheduleSelectionKey
        case "location": return locationSelectionKey
        case "steps": return stepsSelectionKey
        case "sleep": return sleepSelectionKey
        default: return "\(sessionType)Selection"
        }
    }
    
    // MARK: - Session Restoration
    
    func restoreSessionsIfNeeded(
        familyControlsManager: FamilyControlsManager,
        context: NSManagedObjectContext,
        stepsManager: StepsManager,
        locationManager: LocationManager
    ) {
        print("🔄 Checking for sessions to restore...")

        if let persisted = loadPersistedTaskSession() {
            print("📋 Found persisted task session to restore")
            restoreTaskSession(persisted, familyControlsManager: familyControlsManager, context: context)
        }

        if let persisted = loadPersistedTimerSession() {
            print("⏰ Found persisted timer session to restore")
            restoreTimerSession(persisted, familyControlsManager: familyControlsManager)
        }

        if let persisted = loadPersistedScheduleSession() {
            print("📅 Found persisted schedule session to restore")
            restoreScheduleSession(persisted, familyControlsManager: familyControlsManager)
        }

        if let persisted = loadPersistedLocationSession() {
            print("📍 Found persisted location session to restore")
            restoreLocationSession(persisted, familyControlsManager: familyControlsManager, locationManager: locationManager)
        }

        if let persisted = loadPersistedStepsSession() {
            print("🚶 Found persisted steps session to restore")
            restoreStepsSession(persisted, familyControlsManager: familyControlsManager, stepsManager: stepsManager)
        }

        if let persisted = loadPersistedSleepSession() {
            print("😴 Found persisted sleep session to restore")
            restoreSleepSession(persisted, familyControlsManager: familyControlsManager)
        }
    }
    
    private func restoreTaskSession(
        _ persisted: PersistedTaskSession,
        familyControlsManager: FamilyControlsManager,
        context: NSManagedObjectContext
    ) {
        let taskIds = persisted.taskIds.compactMap { UUID(uuidString: $0) }
        
        let session = TaskBlockingSession(
            id: UUID(uuidString: persisted.id) ?? UUID(),
            name: "Task Session",
            taskIds: taskIds,
            startTime: persisted.startTime,
            isActive: persisted.isActive
        )
        
        activeTaskSession = session
        
        startTaskMonitoring(for: session, context: context, manager: familyControlsManager)
        
        if let selection = getSessionSelection(for: "task") ?? familyControlsManager.taskActivitySelection as FamilyActivitySelection? {
            familyControlsManager.updateBlocking(
                sessionId: "task-\(session.id.uuidString)",
                selection: selection
            )
        }
        
        print("✅ Task session restored")
    }
    
    private func restoreTimerSession(
        _ persisted: PersistedTimerSession,
        familyControlsManager: FamilyControlsManager
    ) {
        let elapsed = Date().timeIntervalSince(persisted.startTime)
        let remaining = max(0, persisted.duration - elapsed)

        // Check if timer expired while app was closed
        if remaining <= 0 {
            print("⏰ Timer session expired during app downtime (elapsed: \(Int(elapsed))s, duration: \(Int(persisted.duration))s)")
            print("🔓 Auto-unlocking apps now...")

            // Create temporary session just to clean it up properly
            let session = TimerBlockingSession(
                id: UUID(uuidString: persisted.id) ?? UUID(),
                name: persisted.name,
                duration: persisted.duration,
                startTime: persisted.startTime,
                isActive: false
            )
            activeTimerSession = session

            // End session which will remove blocking and clean up
            endTimerSession(familyControlsManager: familyControlsManager)
            return
        }

        // Timer still active - restore it
        let session = TimerBlockingSession(
            id: UUID(uuidString: persisted.id) ?? UUID(),
            name: persisted.name,
            duration: persisted.duration,
            startTime: persisted.startTime,
            isActive: persisted.isActive
        )

        activeTimerSession = session
        scheduleTimerCompletion(session: session, remainingTime: remaining, familyControlsManager: familyControlsManager)

        // Try to load persisted selection
        if let selection = getSessionSelection(for: "timer") {
            print("📥 Loaded persisted timer selection: \(selection.applicationTokens.count) apps")
            familyControlsManager.updateBlocking(
                sessionId: "timer-\(session.id.uuidString)",
                selection: selection
            )
            print("✅ Timer session restored with blocking: \(Int(remaining/60)) minutes remaining")
        } else {
            print("⚠️ No persisted selection found for timer - blocking will NOT be applied")
            print("✅ Timer session restored WITHOUT blocking: \(Int(remaining/60)) minutes remaining")
        }
    }
    
    private func restoreScheduleSession(_ persisted: PersistedScheduleSession, familyControlsManager: FamilyControlsManager) {
        guard let scheduleType = ScheduleBlockingSession.ScheduleType(rawValue: persisted.scheduleType) else { return }
        
        startScheduleSession(
            name: persisted.name,
            scheduleType: scheduleType,
            startHour: persisted.startHour,
            startMinute: persisted.startMinute,
            endHour: persisted.endHour,
            endMinute: persisted.endMinute,
            selectedDays: persisted.selectedDays,
            familyControlsManager: familyControlsManager
        )
    }

    private func restoreLocationSession(
        _ persisted: PersistedLocationSession,
        familyControlsManager: FamilyControlsManager,
        locationManager: LocationManager
    ) {
        guard let triggerType = LocationBlockingSession.LocationTriggerType(rawValue: persisted.triggerType) else { return }

        let session = LocationBlockingSession(
            id: UUID(uuidString: persisted.id) ?? UUID(),
            name: persisted.name,
            startTime: persisted.startTime,
            isActive: true,
            latitude: persisted.latitude,
            longitude: persisted.longitude,
            radius: persisted.radius,
            locationName: persisted.locationName,
            triggerType: triggerType
        )

        // Start the session (will set up notification observers)
        startLocationSession(
            session: session,
            familyControlsManager: familyControlsManager,
            locationManager: locationManager
        )

        // Restart region monitoring
        locationManager.startMonitoring(
            coordinate: session.coordinate,
            radius: persisted.radius,
            identifier: session.id.uuidString
        )

        // Check current location and re-apply blocking if needed
        // This handles the case where the app was force-quit while inside the region
        locationManager.startUpdatingLocation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            let isCurrentlyInside = locationManager.isInside(
                coordinate: session.coordinate,
                radius: persisted.radius
            )

            print("📍 Location session restore check - inside: \(isCurrentlyInside), trigger: \(triggerType.rawValue)")

            // Re-apply blocking based on current state and trigger type
            if isCurrentlyInside && (session.triggerType == .inside || session.triggerType == .entering) {
                let selection = self.getSessionSelection(for: "location") ?? familyControlsManager.timerActivitySelection
                familyControlsManager.updateBlocking(
                    sessionId: "location-\(session.id.uuidString)",
                    selection: selection
                )
                print("📍 Location session restored - inside region, blocking RE-APPLIED after app restart")
            } else if !isCurrentlyInside && session.triggerType == .leaving {
                let selection = self.getSessionSelection(for: "location") ?? familyControlsManager.timerActivitySelection
                familyControlsManager.updateBlocking(
                    sessionId: "location-\(session.id.uuidString)",
                    selection: selection
                )
                print("📍 Location session restored - outside region, blocking RE-APPLIED for 'leaving' trigger")
            } else {
                print("📍 Location session restored - no blocking needed based on current location")
            }
        }
    }

    private func restoreStepsSession(
        _ persisted: PersistedStepsSession,
        familyControlsManager: FamilyControlsManager,
        stepsManager: StepsManager
    ) {
        let session = StepBlockingSession(
            id: UUID(uuidString: persisted.id) ?? UUID(),
            name: persisted.name,
            startTime: persisted.startTime,
            isActive: true,
            targetSteps: persisted.targetSteps,
            currentSteps: stepsManager.todaySteps,
            resetDaily: persisted.resetDaily
        )

        activeStepsSession = session

        // Check if goal already reached
        if stepsManager.todaySteps >= persisted.targetSteps {
            print("🎉 Steps goal already reached - ending session")
            endStepsSession(familyControlsManager: familyControlsManager)
            return
        }

        // Re-register with merge system to restore blocking
        let selection = getSessionSelection(for: "steps") ?? familyControlsManager.timerActivitySelection
        familyControlsManager.updateBlocking(
            sessionId: "steps-\(session.id.uuidString)",
            selection: selection
        )

        // Restart monitoring to continue tracking toward goal
        stepsManager.startMonitoring(targetSteps: persisted.targetSteps) { [weak self] in
            self?.endStepsSession(familyControlsManager: familyControlsManager)
        }

        print("✅ Steps session restored - \(stepsManager.todaySteps)/\(persisted.targetSteps) steps")
    }

    private func restoreSleepSession(_ persisted: PersistedSleepSession, familyControlsManager: FamilyControlsManager) {
        startSleepSession(
            name: persisted.name,
            bedtimeHour: persisted.bedtimeHour,
            bedtimeMinute: persisted.bedtimeMinute,
            wakeupHour: persisted.wakeupHour,
            wakeupMinute: persisted.wakeupMinute,
            enabledDays: persisted.enabledDays,
            familyControlsManager: familyControlsManager
        )
    }
    
    // MARK: - Persistence Methods
    
    private func saveTaskSession() {
        guard let session = activeTaskSession else {
            UserDefaults.standard.removeObject(forKey: taskSessionKey)
            return
        }
        
        let persisted = PersistedTaskSession(
            id: session.id.uuidString,
            taskIds: session.taskIds.map { $0.uuidString },
            startTime: session.startTime,
            isActive: session.isActive
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: taskSessionKey)
        }
    }
    
    private func saveTimerSession() {
        guard let session = activeTimerSession else {
            UserDefaults.standard.removeObject(forKey: timerSessionKey)
            return
        }
        
        let persisted = PersistedTimerSession(
            id: session.id.uuidString,
            name: session.name,
            duration: session.duration,
            startTime: session.startTime,
            isActive: session.isActive
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: timerSessionKey)
        }
    }
    
    private func saveScheduleSession() {
        guard let session = activeScheduleSession else {
            UserDefaults.standard.removeObject(forKey: scheduleSessionKey)
            return
        }
        
        let persisted = PersistedScheduleSession(
            id: session.id.uuidString,
            name: session.name,
            scheduleType: session.scheduleType.rawValue,
            startHour: session.startHour,
            startMinute: session.startMinute,
            endHour: session.endHour,
            endMinute: session.endMinute,
            selectedDays: session.selectedDays,
            startTime: session.startTime
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: scheduleSessionKey)
        }
    }

    private func saveLocationSession() {
        guard let session = activeLocationSession else {
            UserDefaults.standard.removeObject(forKey: locationSessionKey)
            return
        }
        
        let persisted = PersistedLocationSession(
            id: session.id.uuidString,
            name: session.name,
            latitude: session.latitude,
            longitude: session.longitude,
            radius: session.radius,
            locationName: session.locationName,
            triggerType: session.triggerType.rawValue,
            startTime: session.startTime
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: locationSessionKey)
        }
    }

    private func saveStepsSession() {
        guard let session = activeStepsSession else {
            UserDefaults.standard.removeObject(forKey: stepsSessionKey)
            return
        }
        
        let persisted = PersistedStepsSession(
            id: session.id.uuidString,
            name: session.name,
            targetSteps: session.targetSteps,
            resetDaily: session.resetDaily,
            startTime: session.startTime
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: stepsSessionKey)
        }
    }

    private func saveSleepSession() {
        guard let session = activeSleepSession else {
            UserDefaults.standard.removeObject(forKey: sleepSessionKey)
            return
        }
        
        let persisted = PersistedSleepSession(
            id: session.id.uuidString,
            name: session.name,
            bedtimeHour: session.bedtimeHour,
            bedtimeMinute: session.bedtimeMinute,
            wakeupHour: session.wakeupHour,
            wakeupMinute: session.wakeupMinute,
            enabledDays: session.enabledDays,
            startTime: session.startTime
        )
        
        if let encoded = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(encoded, forKey: sleepSessionKey)
        }
    }
    
    private func loadPersistedTaskSession() -> PersistedTaskSession? {
        guard let data = UserDefaults.standard.data(forKey: taskSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedTaskSession.self, from: data) else {
            return nil
        }
        return persisted
    }
    
    private func loadPersistedTimerSession() -> PersistedTimerSession? {
        guard let data = UserDefaults.standard.data(forKey: timerSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedTimerSession.self, from: data) else {
            return nil
        }
        return persisted
    }
    
    private func loadPersistedScheduleSession() -> PersistedScheduleSession? {
        guard let data = UserDefaults.standard.data(forKey: scheduleSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedScheduleSession.self, from: data) else {
            return nil
        }
        return persisted
    }

    private func loadPersistedLocationSession() -> PersistedLocationSession? {
        guard let data = UserDefaults.standard.data(forKey: locationSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedLocationSession.self, from: data) else {
            return nil
        }
        return persisted
    }

    private func loadPersistedStepsSession() -> PersistedStepsSession? {
        guard let data = UserDefaults.standard.data(forKey: stepsSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedStepsSession.self, from: data) else {
            return nil
        }
        return persisted
    }

    private func loadPersistedSleepSession() -> PersistedSleepSession? {
        guard let data = UserDefaults.standard.data(forKey: sleepSessionKey),
              let persisted = try? JSONDecoder().decode(PersistedSleepSession.self, from: data) else {
            return nil
        }
        return persisted
    }

    private func clearPersistedSessions() {
        UserDefaults.standard.removeObject(forKey: taskSessionKey)
        UserDefaults.standard.removeObject(forKey: timerSessionKey)
        UserDefaults.standard.removeObject(forKey: scheduleSessionKey)
        UserDefaults.standard.removeObject(forKey: locationSessionKey)
        UserDefaults.standard.removeObject(forKey: stepsSessionKey)
        UserDefaults.standard.removeObject(forKey: sleepSessionKey)

        // Also clear persisted selections
        removePersistedSelection(for: "task")
        removePersistedSelection(for: "timer")
        removePersistedSelection(for: "schedule")
        removePersistedSelection(for: "location")
        removePersistedSelection(for: "steps")
        removePersistedSelection(for: "sleep")

        sessionSelections.removeAll()
    }
    
    // MARK: - Task-Based Blocking
    
    func startTaskSession(
        tasks: [TaskEntity],
        familyControlsManager: FamilyControlsManager,
        context: NSManagedObjectContext
    ) {
        guard activeTaskSession == nil else {
            print("⚠️ Task session already active")
            return
        }
        
        let taskIds = tasks.compactMap { $0.taskId }
        print("📋 Starting task session with \(taskIds.count) tasks")
        
        let session = TaskBlockingSession(
            id: UUID(),
            name: "Task Block",
            taskIds: taskIds,
            startTime: Date(),
            isActive: true
        )
        
        activeTaskSession = session
        
        // Register with merge system
        let selection = getSessionSelection(for: "task") ?? familyControlsManager.taskActivitySelection
        familyControlsManager.updateBlocking(
            sessionId: "task-\(session.id.uuidString)",
            selection: selection
        )
        
        saveTaskSession()
        startTaskMonitoring(for: session, context: context, manager: familyControlsManager)

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let blockedAppsCount = selection.applicationTokens.count
            let contentState = LiveActivityManager.shared.createTaskContentState(
                sessionName: "Task Block",
                completedTasks: 0,
                totalTasks: taskIds.count,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "task",
                    sessionName: "Task Block",
                    contentState: contentState,
                    primaryColor: "34C759" // Green for tasks
                )
                print("✅ Live Activity started for task session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("✅ Task-based blocking session started")
    }
    
    private func startTaskMonitoring(
        for session: TaskBlockingSession,
        context: NSManagedObjectContext,
        manager: FamilyControlsManager
    ) {
        taskObserver?.delegate = nil
        taskObserver = nil
        taskCompletionDelegate = nil
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "taskId IN %@", session.taskIds)
        request.sortDescriptors = [NSSortDescriptor(key: "taskCreatedAt", ascending: false)]
        
        taskObserver = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        taskCompletionDelegate = TaskCompletionDelegate(
            session: session,
            sessionManager: self,
            familyControlsManager: manager
        )
        
        taskObserver?.delegate = taskCompletionDelegate
        
        do {
            try taskObserver?.performFetch()
            
            if let tasks = taskObserver?.fetchedObjects {
                let completed = tasks.filter { $0.taskIsCompleted }.count
                print("🔍 Initial task state: \(completed)/\(tasks.count) completed")
                
                if completed == tasks.count && tasks.count > 0 {
                    print("⚠️ All tasks already completed - ending session")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.endTaskSession(familyControlsManager: manager)
                    }
                }
            }
        } catch {
            print("❌ Failed to setup task monitoring: \(error)")
        }
    }
    
    func endTaskSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeTaskSession else {
            print("⚠️ No active task session to end")
            return
        }

        print("🛑 Ending task session: \(session.id)")

        // Add to history
        addCompletedSession(
            type: "task",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "task-\(session.id.uuidString)")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .default
                )
                print("✅ Live Activity ended for task session")
            }
        }

        activeTaskSession = nil
        taskObserver?.delegate = nil
        taskObserver = nil
        taskCompletionDelegate = nil

        UserDefaults.standard.removeObject(forKey: taskSessionKey)
        removePersistedSelection(for: "task")
        sessionSelections.removeValue(forKey: "task")

        print("✅ Task-based blocking session ended")
    }
    
    // MARK: - Timer-Based Blocking
    
    func startTimerSession(duration: TimeInterval, sessionName: String, familyControlsManager: FamilyControlsManager) {
        guard activeTimerSession == nil else {
            print("⚠️ Timer session already active")
            return
        }

        let session = TimerBlockingSession(
            id: UUID(),
            name: sessionName,
            duration: duration,
            startTime: Date(),
            isActive: true
        )

        activeTimerSession = session

        // Register with merge system
        let selection = getSessionSelection(for: "timer") ?? familyControlsManager.timerActivitySelection
        familyControlsManager.updateBlocking(
            sessionId: "timer-\(session.id.uuidString)",
            selection: selection
        )

        saveTimerSession()
        scheduleTimerCompletion(session: session, remainingTime: duration, familyControlsManager: familyControlsManager)

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let blockedAppsCount = selection.applicationTokens.count
            let contentState = LiveActivityManager.shared.createTimerContentState(
                sessionName: sessionName,
                endDate: Date().addingTimeInterval(duration),
                duration: duration,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "timer",
                    sessionName: sessionName,
                    contentState: contentState,
                    primaryColor: "FF9500" // Orange for timer
                )
                print("🔴 Live Activity started for timer session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("✅ Timer session '\(sessionName)' started for \(Int(duration/60)) minutes")
    }
    
    private func scheduleTimerCompletion(session: TimerBlockingSession, remainingTime: TimeInterval, familyControlsManager: FamilyControlsManager) {
        timerWorkItem?.cancel()

        timerWorkItem = DispatchWorkItem { [weak self] in
            if self?.activeTimerSession?.id == session.id {
                self?.endTimerSession(familyControlsManager: familyControlsManager)
            }
        }

        if let workItem = timerWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime, execute: workItem)
        }
    }
    
    func endTimerSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeTimerSession else {
            print("⚠️ No active timer session to end")
            return
        }

        print("🛑 Ending timer session: \(session.name)")

        // Add to history
        addCompletedSession(
            type: "timer",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "timer-\(session.id.uuidString)")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .immediate
                )
                print("🔴 Live Activity ended for timer session")
            }
        }

        timerWorkItem?.cancel()
        timerWorkItem = nil
        activeTimerSession = nil

        UserDefaults.standard.removeObject(forKey: timerSessionKey)
        removePersistedSelection(for: "timer")
        sessionSelections.removeValue(forKey: "timer")

        print("✅ Timer session ended")
    }
    
    // MARK: - Schedule-Based Blocking
    
    func startScheduleSession(
        name: String,
        scheduleType: ScheduleBlockingSession.ScheduleType,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        selectedDays: [Int],
        familyControlsManager: FamilyControlsManager
    ) {
        let session = ScheduleBlockingSession(
            id: UUID(),
            name: name,
            startTime: Date(),
            isActive: true,
            scheduleType: scheduleType,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            selectedDays: selectedDays
        )
        
        activeScheduleSession = session
        
        // Register with merge system if currently in schedule
        if session.isCurrentlyInSchedule {
            let selection = getSessionSelection(for: "schedule") ?? familyControlsManager.timerActivitySelection
            familyControlsManager.updateBlocking(
                sessionId: "schedule-\(session.id.uuidString)",
                selection: selection
            )
        }
        
        startScheduleMonitoring(session: session, familyControlsManager: familyControlsManager)
        saveScheduleSession()

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let selection = getSessionSelection(for: "schedule") ?? familyControlsManager.timerActivitySelection
            let blockedAppsCount = selection.applicationTokens.count
            let endTimeString = String(format: "%02d:%02d", endHour, endMinute)

            let contentState = LiveActivityManager.shared.createScheduleContentState(
                sessionName: name,
                endTime: endTimeString,
                isActive: session.isCurrentlyInSchedule,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "schedule",
                    sessionName: name,
                    contentState: contentState,
                    primaryColor: "AF52DE" // Purple for schedule
                )
                print("📅 Live Activity started for schedule session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("✅ Schedule session '\(name)' started")
    }

    private func startScheduleMonitoring(session: ScheduleBlockingSession, familyControlsManager: FamilyControlsManager) {
        scheduleFamilyControlsManager = familyControlsManager
        scheduleTimer?.invalidate()
        
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentSession = self.activeScheduleSession,
                  let manager = self.scheduleFamilyControlsManager,
                  currentSession.id == session.id else { return }
            
            let sessionId = "schedule-\(currentSession.id.uuidString)"
            
            if currentSession.isCurrentlyInSchedule {
                // Re-register in merge system
                let selection = self.getSessionSelection(for: "schedule") ?? manager.timerActivitySelection
                manager.updateBlocking(sessionId: sessionId, selection: selection)
                print("⏰ Schedule active - blocking maintained")
            } else {
                // Remove from merge system
                manager.removeBlocking(sessionId: sessionId)
                print("⏰ Outside schedule - removed from blocking")
            }
        }
        
        RunLoop.main.add(scheduleTimer!, forMode: .common)
        
        // Trigger immediate check
        if session.isCurrentlyInSchedule {
            let selection = getSessionSelection(for: "schedule") ?? familyControlsManager.timerActivitySelection
            familyControlsManager.updateBlocking(
                sessionId: "schedule-\(session.id.uuidString)",
                selection: selection
            )
        }
    }

    func endScheduleSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeScheduleSession else { return }

        // Add to history
        addCompletedSession(
            type: "schedule",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "schedule-\(session.id.uuidString)")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .immediate
                )
                print("📅 Live Activity ended for schedule session")
            }
        }

        scheduleTimer?.invalidate()
        scheduleTimer = nil
        activeScheduleSession = nil

        UserDefaults.standard.removeObject(forKey: scheduleSessionKey)
        removePersistedSelection(for: "schedule")
        sessionSelections.removeValue(forKey: "schedule")

        print("✅ Schedule session ended")
    }

    // MARK: - Location-Based Blocking
    
    func startLocationSession(
        session: LocationBlockingSession,
        familyControlsManager: FamilyControlsManager,
        locationManager: LocationManager
    ) {
        activeLocationSession = session
        currentFamilyControlsManager = familyControlsManager
        currentLocationManager = locationManager

        // DON'T register blocking immediately - only when entering region
        // The LocationManager will trigger handleLocationEnter when user enters

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationEnter),
            name: NSNotification.Name("DidEnterRegion"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationExit),
            name: NSNotification.Name("DidExitRegion"),
            object: nil
        )

        saveLocationSession()

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let blockedAppsCount = familyControlsManager.timerActivitySelection.applicationTokens.count
            let contentState = LiveActivityManager.shared.createLocationContentState(
                sessionName: session.name,
                triggerType: session.triggerType.rawValue,
                isInside: false,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "location",
                    sessionName: session.name,
                    contentState: contentState,
                    primaryColor: "1CB0F6" // Blue for location
                )
                print("📍 Live Activity started for location session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("📍 Location session '\(session.name)' started - waiting for entry")
    }

    @objc private func handleLocationEnter(notification: Notification) {
        print("📍 handleLocationEnter called - notification object: \(String(describing: notification.object))")

        guard let session = activeLocationSession,
              let manager = currentFamilyControlsManager else {
            print("⚠️ No active location session or manager")
            return
        }

        print("📍 Active session: \(session.name), trigger type: \(session.triggerType.rawValue)")

        if session.triggerType == .entering || session.triggerType == .inside {
            let selection = getSessionSelection(for: "location") ?? manager.timerActivitySelection
            manager.updateBlocking(
                sessionId: "location-\(session.id.uuidString)",
                selection: selection
            )
            print("✅ Entered location - blocking applied for session \(session.id)")

            // Update Live Activity
            if #available(iOS 16.1, *) {
                let contentState = LiveActivityManager.shared.createLocationContentState(
                    sessionName: session.name,
                    triggerType: session.triggerType.rawValue,
                    isInside: true,
                    blockedAppsCount: selection.applicationTokens.count,
                    sessionId: session.id.uuidString
                )

                Task {
                    await LiveActivityManager.shared.updateActivity(
                        sessionId: session.id.uuidString,
                        contentState: contentState
                    )
                    print("📍 Live Activity updated - entered location")
                }
            }
        }
    }

    @objc private func handleLocationExit(notification: Notification) {
        print("📍 handleLocationExit called - notification object: \(String(describing: notification.object))")

        guard let session = activeLocationSession,
              let manager = currentFamilyControlsManager else {
            print("⚠️ No active location session or manager")
            return
        }

        print("📍 Active session: \(session.name), trigger type: \(session.triggerType.rawValue)")

        let sessionId = "location-\(session.id.uuidString)"

        if session.triggerType == .inside {
            manager.removeBlocking(sessionId: sessionId)
            print("✅ Left location - blocking removed for session \(session.id)")
        } else if session.triggerType == .leaving {
            let selection = getSessionSelection(for: "location") ?? manager.timerActivitySelection
            manager.updateBlocking(sessionId: sessionId, selection: selection)
            print("📍 Left location - blocking applied")
        }

        // Update Live Activity
        if #available(iOS 16.1, *) {
            let selection = getSessionSelection(for: "location") ?? manager.timerActivitySelection
            let contentState = LiveActivityManager.shared.createLocationContentState(
                sessionName: session.name,
                triggerType: session.triggerType.rawValue,
                isInside: false,
                blockedAppsCount: selection.applicationTokens.count,
                sessionId: session.id.uuidString
            )

            Task {
                await LiveActivityManager.shared.updateActivity(
                    sessionId: session.id.uuidString,
                    contentState: contentState
                )
                print("📍 Live Activity updated - exited location")
            }
        }
    }

    func endLocationSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeLocationSession else { return }

        // Add to history
        addCompletedSession(
            type: "location",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "location-\(session.id.uuidString)")

        // Stop location monitoring
        currentLocationManager?.stopMonitoring(identifier: session.id.uuidString)
        print("🛑 Location monitoring stopped for region: \(session.id.uuidString)")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .immediate
                )
                print("📍 Live Activity ended for location session")
            }
        }

        activeLocationSession = nil
        currentLocationManager = nil

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("DidEnterRegion"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("DidExitRegion"), object: nil)

        UserDefaults.standard.removeObject(forKey: locationSessionKey)
        removePersistedSelection(for: "location")
        sessionSelections.removeValue(forKey: "location")

        print("✅ Location session ended")
    }

    // MARK: - Steps-Based Blocking
    
    func startStepsSession(
        name: String,
        targetSteps: Int,
        resetDaily: Bool,
        familyControlsManager: FamilyControlsManager,
        stepsManager: StepsManager
    ) {
        let session = StepBlockingSession(
            id: UUID(),
            name: name,
            startTime: Date(),
            isActive: true,
            targetSteps: targetSteps,
            currentSteps: stepsManager.todaySteps,
            resetDaily: resetDaily
        )
        
        activeStepsSession = session
        currentStepsManager = stepsManager

        // Register with merge system
        let selection = getSessionSelection(for: "steps") ?? familyControlsManager.timerActivitySelection
        familyControlsManager.updateBlocking(
            sessionId: "steps-\(session.id.uuidString)",
            selection: selection
        )

        stepsManager.startMonitoring(targetSteps: targetSteps) { [weak self] in
            self?.endStepsSession(familyControlsManager: familyControlsManager)
        }

        saveStepsSession()

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let blockedAppsCount = selection.applicationTokens.count
            let contentState = LiveActivityManager.shared.createStepsContentState(
                sessionName: name,
                currentSteps: stepsManager.todaySteps,
                targetSteps: targetSteps,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "steps",
                    sessionName: name,
                    contentState: contentState,
                    primaryColor: "FFC800" // Yellow for steps
                )
                print("👟 Live Activity started for steps session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("✅ Steps session '\(name)' started - target: \(targetSteps)")
    }

    func endStepsSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeStepsSession else { return }

        // Add to history
        addCompletedSession(
            type: "steps",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "steps-\(session.id.uuidString)")

        // Stop steps monitoring
        currentStepsManager?.stopMonitoring()
        print("🛑 Steps monitoring stopped")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .default
                )
                print("👟 Live Activity ended for steps session")
            }
        }

        activeStepsSession = nil
        currentStepsManager = nil
        UserDefaults.standard.removeObject(forKey: stepsSessionKey)
        removePersistedSelection(for: "steps")
        sessionSelections.removeValue(forKey: "steps")

        print("✅ Steps session ended - goal reached!")
    }

    // MARK: - Sleep-Based Blocking
    
    func startSleepSession(
        name: String,
        bedtimeHour: Int,
        bedtimeMinute: Int,
        wakeupHour: Int,
        wakeupMinute: Int,
        enabledDays: [Int],
        familyControlsManager: FamilyControlsManager
    ) {
        let session = SleepBlockingSession(
            id: UUID(),
            name: name,
            startTime: Date(),
            isActive: true,
            bedtimeHour: bedtimeHour,
            bedtimeMinute: bedtimeMinute,
            wakeupHour: wakeupHour,
            wakeupMinute: wakeupMinute,
            enabledDays: enabledDays
        )
        
        activeSleepSession = session
        
        // Register with merge system if currently sleep time
        if session.isCurrentlySleepTime {
            let selection = getSessionSelection(for: "sleep") ?? familyControlsManager.timerActivitySelection
            familyControlsManager.updateBlocking(
                sessionId: "sleep-\(session.id.uuidString)",
                selection: selection
            )
        }
        
        startSleepMonitoring(session: session, familyControlsManager: familyControlsManager)
        saveSleepSession()

        // Start Live Activity
        if #available(iOS 16.1, *) {
            let selection = getSessionSelection(for: "sleep") ?? familyControlsManager.timerActivitySelection
            let blockedAppsCount = selection.applicationTokens.count
            let wakeTimeString = String(format: "%02d:%02d", wakeupHour, wakeupMinute)

            let contentState = LiveActivityManager.shared.createSleepContentState(
                sessionName: name,
                wakeTime: wakeTimeString,
                isActive: session.isCurrentlySleepTime,
                blockedAppsCount: blockedAppsCount,
                sessionId: session.id.uuidString
            )

            do {
                try LiveActivityManager.shared.startActivity(
                    sessionId: session.id.uuidString,
                    sessionType: "sleep",
                    sessionName: name,
                    contentState: contentState,
                    primaryColor: "8B5CF6" // Purple/violet for sleep
                )
                print("😴 Live Activity started for sleep session")
            } catch {
                print("⚠️ Failed to start Live Activity: \(error)")
            }
        }

        print("✅ Sleep session '\(name)' started")
    }

    private func startSleepMonitoring(session: SleepBlockingSession, familyControlsManager: FamilyControlsManager) {
        sleepTimer?.invalidate()

        sleepTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentSession = self.activeSleepSession,
                  currentSession.id == session.id else { return }

            let sessionId = "sleep-\(currentSession.id.uuidString)"

            if currentSession.isCurrentlySleepTime {
                let selection = self.getSessionSelection(for: "sleep") ?? familyControlsManager.timerActivitySelection
                familyControlsManager.updateBlocking(sessionId: sessionId, selection: selection)
                print("😴 Sleep time active - blocking maintained")
            } else {
                familyControlsManager.removeBlocking(sessionId: sessionId)
                print("😴 Sleep time ended - removed from blocking")
            }
        }

        RunLoop.main.add(sleepTimer!, forMode: .common)
    }

    func endSleepSession(familyControlsManager: FamilyControlsManager) {
        guard let session = activeSleepSession else { return }

        // Add to history
        addCompletedSession(
            type: "sleep",
            name: session.name,
            startTime: session.startTime,
            completed: true
        )

        // Unregister from merge system
        familyControlsManager.removeBlocking(sessionId: "sleep-\(session.id.uuidString)")

        // Stop sleep monitoring timer
        sleepTimer?.invalidate()
        sleepTimer = nil
        print("🛑 Sleep monitoring timer stopped")

        // End Live Activity
        if #available(iOS 16.1, *) {
            Task {
                await LiveActivityManager.shared.endActivity(
                    sessionId: session.id.uuidString,
                    dismissalPolicy: .immediate
                )
                print("😴 Live Activity ended for sleep session")
            }
        }

        activeSleepSession = nil
        UserDefaults.standard.removeObject(forKey: sleepSessionKey)
        removePersistedSelection(for: "sleep")
        sessionSelections.removeValue(forKey: "sleep")

        print("✅ Sleep session ended")
    }

    // MARK: - Computed Properties
    
    var isAnySessionActive: Bool {
        return activeTaskSession != nil ||
               activeTimerSession != nil ||
               activeScheduleSession != nil ||
               activeLocationSession != nil ||
               activeStepsSession != nil ||
               activeSleepSession != nil
    }
    
    var hasAnySession: Bool {
        return isAnySessionActive
    }
    
    // MARK: - Emergency Session Cleanup

    func forceEndAllSessions(familyControlsManager: FamilyControlsManager) {
        print("🚨 Force ending all sessions")

        if activeTaskSession != nil {
            endTaskSession(familyControlsManager: familyControlsManager)
        }

        if activeTimerSession != nil {
            endTimerSession(familyControlsManager: familyControlsManager)
        }

        if activeScheduleSession != nil {
            endScheduleSession(familyControlsManager: familyControlsManager)
        }

        if activeLocationSession != nil {
            endLocationSession(familyControlsManager: familyControlsManager)
        }

        if activeStepsSession != nil {
            endStepsSession(familyControlsManager: familyControlsManager)
        }

        if activeSleepSession != nil {
            endSleepSession(familyControlsManager: familyControlsManager)
        }

        clearPersistedSessions()
        print("🚨 All sessions force ended")
    }

    // MARK: - Session History Management

    private func addCompletedSession(type: String, name: String, startTime: Date, completed: Bool) {
        let session = CompletedSession(
            id: UUID(),
            type: type,
            name: name,
            startTime: startTime,
            endTime: Date(),
            completed: completed
        )

        sessionHistory.insert(session, at: 0) // Add to beginning

        // Keep only last 50 sessions
        if sessionHistory.count > 50 {
            sessionHistory = Array(sessionHistory.prefix(50))
        }

        saveSessionHistory()
        print("📊 Session added to history: \(name) (\(type))")
    }

    func getRecentSessions(limit: Int = 10) -> [CompletedSession] {
        return Array(sessionHistory.prefix(limit))
    }

    func getTodaySessions() -> [CompletedSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return sessionHistory.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: today)
        }
    }

    private func saveSessionHistory() {
        if let data = try? JSONEncoder().encode(sessionHistory) {
            UserDefaults.standard.set(data, forKey: sessionHistoryKey)
        }
    }

    private func loadSessionHistory() {
        guard let data = UserDefaults.standard.data(forKey: sessionHistoryKey),
              let history = try? JSONDecoder().decode([CompletedSession].self, from: data) else {
            print("📊 No session history found")
            return
        }

        sessionHistory = history
        print("📊 Loaded \(history.count) completed sessions from history")
    }
}

// MARK: - Task Completion Delegate (unchanged)
class TaskCompletionDelegate: NSObject, NSFetchedResultsControllerDelegate {
    private let session: TaskBlockingSession
    private weak var sessionManager: BlockingSessionManager?
    private weak var familyControlsManager: FamilyControlsManager?
    
    init(
        session: TaskBlockingSession,
        sessionManager: BlockingSessionManager,
        familyControlsManager: FamilyControlsManager
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.familyControlsManager = familyControlsManager
        super.init()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let tasks = controller.fetchedObjects as? [TaskEntity],
              let manager = familyControlsManager,
              let sessionMgr = sessionManager else {
            return
        }
        
        let completedTasks = tasks.filter { $0.taskIsCompleted }
        let totalTasks = tasks.count

        print("📊 Task progress: \(completedTasks.count)/\(totalTasks) completed")

        // Update Live Activity
        if #available(iOS 16.1, *) {
            let contentState = LiveActivityManager.shared.createTaskContentState(
                sessionName: "Task Block",
                completedTasks: completedTasks.count,
                totalTasks: totalTasks,
                blockedAppsCount: sessionMgr.getSessionSelection(for: "task")?.applicationTokens.count ?? 0,
                sessionId: session.id.uuidString
            )

            Task {
                await LiveActivityManager.shared.updateActivity(
                    sessionId: session.id.uuidString,
                    contentState: contentState
                )
                print("✅ Live Activity updated - \(completedTasks.count)/\(totalTasks) tasks")
            }
        }

        if completedTasks.count == totalTasks && totalTasks > 0 {
            print("🎉 All tasks completed! Auto-unlocking...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                sessionMgr.endTaskSession(familyControlsManager: manager)
            }
        }
    }
}
