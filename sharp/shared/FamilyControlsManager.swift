import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import SwiftUI

class FamilyControlsManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var activitySelection = FamilyActivitySelection() // Legacy - kept for backward compatibility
    @Published var isMonitoring = false
    
    // Separate selections for different blocking modes (kept for UI)
    @Published var timerActivitySelection = FamilyActivitySelection()
    @Published var taskActivitySelection = FamilyActivitySelection()
    
    // NEW: Single store and active selections tracking
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var activeSelections: [String: FamilyActivitySelection] = [:]
    
    // Track different types of blocking (kept for UI state)
    @Published var isQuickBlocking = false
    @Published var isTaskBasedBlocking = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    self.isAuthorized = true
                    print("✅ Family Controls authorization granted")
                }
            } catch {
                await MainActor.run {
                    self.isAuthorized = false
                    print("❌ Family Controls authorization failed: \(error)")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Screen Time Monitoring (ALL APPS)
    
    func startAutoScreenTimeMonitoring() {
        guard isAuthorized else {
            print("❌ Not authorized for Family Controls")
            return
        }
        
        guard !isMonitoring else {
            print("⚠️ Already monitoring")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("ScreenTimeTracking")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            isMonitoring = true
            print("✅ Started screen time monitoring for data collection")
            
            startDetailedUsageMonitoring()
            
        } catch {
            print("❌ Failed to start screen time monitoring: \(error)")
        }
    }
    
    private func startDetailedUsageMonitoring() {
        let detailedSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let detailedActivityName = DeviceActivityName("DetailedUsageTracking")
        
        do {
            try center.startMonitoring(detailedActivityName, during: detailedSchedule)
            print("✅ Started detailed usage monitoring")
        } catch {
            print("❌ Failed to start detailed monitoring: \(error)")
        }
    }
    
    func stopScreenTimeMonitoring() {
        let screenTimeActivity = DeviceActivityName("ScreenTimeTracking")
        let detailedActivity = DeviceActivityName("DetailedUsageTracking")
        
        center.stopMonitoring([screenTimeActivity, detailedActivity])
        isMonitoring = false
        print("🛑 Stopped all screen time monitoring")
    }
    
    func restartMonitoring() {
        print("🔄 Restarting monitoring...")
        stopScreenTimeMonitoring()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startAutoScreenTimeMonitoring()
        }
    }
    
    // MARK: - NEW UNIFIED BLOCKING SYSTEM (Token Merging)
    
    func updateBlocking(sessionId: String, selection: FamilyActivitySelection) {
        guard isAuthorized else {
            print("❌ Not authorized for Family Controls")
            return
        }
        
        activeSelections[sessionId] = selection
        print("📋 Registered session \(sessionId): \(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
        
        applyMergedBlocking()
    }
    
    func removeBlocking(sessionId: String) {
        activeSelections.removeValue(forKey: sessionId)
        print("🗑️ Unregistered session \(sessionId)")
        
        applyMergedBlocking()
    }
    
    private func applyMergedBlocking() {
        guard isAuthorized else { return }
        
        // Merge ALL active session tokens using Set.union()
        var allApps: Set<ApplicationToken> = []
        var allCategories: Set<ActivityCategoryToken> = []
        var allWebDomains: Set<WebDomainToken> = []
        
        for (sessionId, selection) in activeSelections {
            allApps.formUnion(selection.applicationTokens)
            allCategories.formUnion(selection.categoryTokens)
            allWebDomains.formUnion(selection.webDomainTokens)
            print("  → Merging \(sessionId): \(selection.applicationTokens.count) apps")
        }
        
        // Apply merged tokens to SINGLE store
        store.shield.applications = allApps.isEmpty ? nil : allApps
        store.shield.applicationCategories = allCategories.isEmpty ? nil :
            ShieldSettings.ActivityCategoryPolicy.specific(allCategories)
        store.shield.webDomains = allWebDomains.isEmpty ? nil : allWebDomains
        
        print("✅ Applied merged blocking: \(allApps.count) apps, \(allCategories.count) categories from \(activeSelections.count) sessions")
        
        // Update UI state
        isQuickBlocking = !allApps.isEmpty || !allCategories.isEmpty
        isTaskBasedBlocking = activeSelections.keys.contains { $0.hasPrefix("task") }
    }
    
    // MARK: - Legacy Methods (for backward compatibility with existing UI)
    
    func blockSelectedApps() {
        guard isAuthorized else { return }
        
        updateBlocking(sessionId: "legacy-quick", selection: activitySelection)
        print("🚫 Quick blocking activated (legacy method)")
    }
    
    func unblockApps() {
        // Clear all sessions
        activeSelections.removeAll()
        applyMergedBlocking()
        
        print("✅ All apps unblocked")
    }
    
    func blockSpecificApps(selection: FamilyActivitySelection) {
        guard isAuthorized else {
            print("❌ Not authorized for Family Controls")
            return
        }
        
        updateBlocking(sessionId: "legacy-specific", selection: selection)
        print("🚫 Specific blocking applied (legacy method)")
    }
    
    func startTimedBlocking(duration: TimeInterval, sessionName: String) {
        guard isAuthorized else { return }
        
        BlockingSessionManager.shared.startTimerSession(
            duration: duration,
            sessionName: sessionName,
            familyControlsManager: self
        )
    }
    
    // MARK: - Convenience Properties
    
    var hasTimerAppsSelected: Bool {
        return !timerActivitySelection.applicationTokens.isEmpty || !timerActivitySelection.categoryTokens.isEmpty
    }
    
    var hasTaskAppsSelected: Bool {
        return !taskActivitySelection.applicationTokens.isEmpty || !taskActivitySelection.categoryTokens.isEmpty
    }
    
    var timerAppsCount: String {
        return "\(timerActivitySelection.applicationTokens.count) apps, \(timerActivitySelection.categoryTokens.count) categories"
    }
    
    var taskAppsCount: String {
        return "\(taskActivitySelection.applicationTokens.count) apps, \(taskActivitySelection.categoryTokens.count) categories"
    }
    
    var isAnyBlocking: Bool {
        return !activeSelections.isEmpty
    }
    
    var blockingStatusDescription: String {
        if activeSelections.isEmpty {
            return "No blocking active"
        } else if activeSelections.count == 1 {
            return "1 blocking session active"
        } else {
            return "\(activeSelections.count) blocking sessions active"
        }
    }
    
    func checkTaskCompletion(tasks: [TaskEntity]) -> Bool {
        return tasks.allSatisfy { $0.taskIsCompleted }
    }
    
    var isSessionActive: Bool {
        return BlockingSessionManager.shared.isAnySessionActive
    }

    var sessionStatusDescription: String {
        return BlockingSessionManager.shared.isAnySessionActive ? "Active sessions" : "No blocking active"
    }
}
