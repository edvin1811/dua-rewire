//
//  BlockingType.swift
//  sharp
//
//  Created by Edvin Åslund on 2025-09-29.
//


import Foundation
import CoreLocation
import FamilyControls

// MARK: - Blocking Type Enum
enum BlockingType: String, Codable, CaseIterable {
    case timer = "Timer"
    case schedule = "Schedule"
    case task = "Task"
    case location = "Location"
    case steps = "Steps"
    case sleep = "Sleep"
    
    var icon: String {
        switch self {
        case .timer: return "timer"
        case .schedule: return "calendar"
        case .task: return "checklist"
        case .location: return "location.fill"
        case .steps: return "figure.walk"
        case .sleep: return "moon.stars.fill"
        }
    }
    
    var title: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .timer:
            return "Block apps for a specific duration"
        case .schedule:
            return "Block apps during certain times"
        case .task:
            return "Unlock apps by completing tasks"
        case .location:
            return "Block apps at specific locations"
        case .steps:
            return "Unlock apps after hitting step goals"
        case .sleep:
            return "Block apps during sleep hours"
        }
    }
    
    var accentColor: String {
        switch self {
        case .timer: return "accentOrange"
        case .schedule: return "accentBlue"
        case .task: return "accentGreen"
        case .location: return "accentPurple"
        case .steps: return "accentYellow"
        case .sleep: return "accentTeal"
        }
    }
}

// MARK: - Base Session Protocol
protocol BlockingSession: Identifiable, Codable {
    var id: UUID { get }
    var name: String { get }
    var type: BlockingType { get }
    var startTime: Date { get }
    var isActive: Bool { get set }
    var appsSelection: FamilyActivitySelection { get }
}

// MARK: - Timer Session (Already exists but updating)
struct TimerBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let startTime: Date
    var isActive: Bool
    
    var type: BlockingType { .timer }
    
    var timeRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var progressPercentage: Double {
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / duration, 1.0)
    }
}

// MARK: - Schedule Session
struct ScheduleBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let startTime: Date
    var isActive: Bool
    
    // Schedule settings
    let scheduleType: ScheduleType
    let startHour: Int  // 0-23
    let startMinute: Int  // 0-59
    let endHour: Int
    let endMinute: Int
    let selectedDays: [Int]  // 1=Monday, 7=Sunday
    
    var type: BlockingType { .schedule }
    
    enum ScheduleType: String, Codable {
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case custom = "Custom"
    }
    
    var formattedSchedule: String {
        let startTimeStr = String(format: "%02d:%02d", startHour, startMinute)
        let endTimeStr = String(format: "%02d:%02d", endHour, endMinute)
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    var isCurrentlyInSchedule: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Check if current day is in schedule
        let isDayMatch: Bool
        switch scheduleType {
        case .daily:
            isDayMatch = true
        case .weekdays:
            isDayMatch = currentWeekday >= 2 && currentWeekday <= 6
        case .weekends:
            isDayMatch = currentWeekday == 1 || currentWeekday == 7
        case .custom:
            isDayMatch = selectedDays.contains(currentWeekday)
        }
        
        guard isDayMatch else { return false }
        
        // Check if current time is in schedule
        let currentMinutes = currentHour * 60 + currentMinute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute
        
        if endMinutes > startMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Handle overnight schedules
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
}

// MARK: - Task Session (Already exists but updating)
struct TaskBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let taskIds: [UUID]
    let startTime: Date
    var isActive: Bool
    
    var type: BlockingType { .task }
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Location Session
struct LocationBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let startTime: Date
    var isActive: Bool
    
    // Location settings
    let latitude: Double
    let longitude: Double
    let radius: Double  // meters
    let locationName: String
    let triggerType: LocationTriggerType
    
    var type: BlockingType { .location }
    
    enum LocationTriggerType: String, Codable {
        case entering = "When Entering"
        case inside = "While Inside"
        case leaving = "When Leaving"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var formattedRadius: String {
        if radius >= 1000 {
            return String(format: "%.1f km", radius / 1000)
        } else {
            return String(format: "%.0f m", radius)
        }
    }
}

// MARK: - Steps Session
struct StepBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let startTime: Date
    var isActive: Bool
    
    // Steps settings
    let targetSteps: Int
    var currentSteps: Int
    let resetDaily: Bool
    
    var type: BlockingType { .steps }
    
    var progress: Double {
        return Double(currentSteps) / Double(targetSteps)
    }
    
    var progressPercentage: Double {
        return min(progress * 100, 100)
    }
    
    var isGoalReached: Bool {
        return currentSteps >= targetSteps
    }
    
    var formattedProgress: String {
        return "\(currentSteps) / \(targetSteps) steps"
    }
    
    var stepsRemaining: Int {
        return max(0, targetSteps - currentSteps)
    }
}

// MARK: - Sleep Session
struct SleepBlockingSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let startTime: Date
    var isActive: Bool
    
    // Sleep settings
    let bedtimeHour: Int  // 0-23
    let bedtimeMinute: Int  // 0-59
    let wakeupHour: Int
    let wakeupMinute: Int
    let enabledDays: [Int]  // 1=Monday, 7=Sunday
    
    var type: BlockingType { .sleep }
    
    var formattedBedtime: String {
        return String(format: "%02d:%02d", bedtimeHour, bedtimeMinute)
    }
    
    var formattedWakeup: String {
        return String(format: "%02d:%02d", wakeupHour, wakeupMinute)
    }
    
    var isCurrentlySleepTime: Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Check if today is enabled
        guard enabledDays.contains(currentWeekday) else { return false }
        
        // Check if current time is in sleep schedule
        let currentMinutes = currentHour * 60 + currentMinute
        let bedtimeMinutes = bedtimeHour * 60 + bedtimeMinute
        let wakeupMinutes = wakeupHour * 60 + wakeupMinute
        
        if wakeupMinutes > bedtimeMinutes {
            // Same day schedule (unusual but possible)
            return currentMinutes >= bedtimeMinutes && currentMinutes < wakeupMinutes
        } else {
            // Overnight schedule (normal)
            return currentMinutes >= bedtimeMinutes || currentMinutes < wakeupMinutes
        }
    }
    
    var formattedDuration: String {
        var totalMinutes = (wakeupHour * 60 + wakeupMinute) - (bedtimeHour * 60 + bedtimeMinute)
        if totalMinutes < 0 {
            totalMinutes += 24 * 60  // Add 24 hours for overnight
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Unified Session Container
enum AnyBlockingSession: Codable, Identifiable {
    case timer(TimerBlockingSession)
    case schedule(ScheduleBlockingSession)
    case task(TaskBlockingSession)
    case location(LocationBlockingSession)
    case steps(StepBlockingSession)
    case sleep(SleepBlockingSession)
    
    var id: UUID {
        switch self {
        case .timer(let session): return session.id
        case .schedule(let session): return session.id
        case .task(let session): return session.id
        case .location(let session): return session.id
        case .steps(let session): return session.id
        case .sleep(let session): return session.id
        }
    }
    
    var name: String {
        switch self {
        case .timer(let session): return session.name
        case .schedule(let session): return session.name
        case .task(let session): return session.name
        case .location(let session): return session.name
        case .steps(let session): return session.name
        case .sleep(let session): return session.name
        }
    }
    
    var type: BlockingType {
        switch self {
        case .timer: return .timer
        case .schedule: return .schedule
        case .task: return .task
        case .location: return .location
        case .steps: return .steps
        case .sleep: return .sleep
        }
    }
    
    var isActive: Bool {
        get {
            switch self {
            case .timer(let session): return session.isActive
            case .schedule(let session): return session.isActive
            case .task(let session): return session.isActive
            case .location(let session): return session.isActive
            case .steps(let session): return session.isActive
            case .sleep(let session): return session.isActive
            }
        }
    }
    
    mutating func setActive(_ active: Bool) {
        switch self {
        case .timer(var session):
            session.isActive = active
            self = .timer(session)
        case .schedule(var session):
            session.isActive = active
            self = .schedule(session)
        case .task(var session):
            session.isActive = active
            self = .task(session)
        case .location(var session):
            session.isActive = active
            self = .location(session)
        case .steps(var session):
            session.isActive = active
            self = .steps(session)
        case .sleep(var session):
            session.isActive = active
            self = .sleep(session)
        }
    }
}