//
//  StatisticsManager.swift
//  sharp
//
//  Created by Claude Code on 2025-12-03.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Statistics Manager
class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    // MARK: - Published Properties
    @Published var dailyScreenTime: [String: TimeInterval] = [:] // Date string -> seconds
    @Published var dailyPickups: [String: Int] = [:]
    @Published var dailyNotifications: [String: Int] = [:]
    @Published var dailyGoal: TimeInterval = 7200 // 2 hours default (in seconds)

    // MARK: - UserDefaults Keys
    private let dailyScreenTimeKey = "dailyScreenTime"
    private let dailyPickupsKey = "dailyPickups"
    private let dailyNotificationsKey = "dailyNotifications"
    private let dailyGoalKey = "dailyGoalSeconds"
    private let baselineScreenTimeKey = "baselineScreenTime"
    private let baselinePickupsKey = "baselinePickups"
    private let firstLaunchDateKey = "firstLaunchDate"
    private let goalMetDatesKey = "goalMetDates" // Array of date strings

    // MARK: - App Group for sharing with extension
    private let appGroupSuiteName = "group.com.coolstudio.sharp"
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupSuiteName)
    }

    // MARK: - Initialization
    private init() {
        load()
        recordFirstLaunch()
    }

    // MARK: - First Launch Tracking
    private func recordFirstLaunch() {
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchDateKey)
            print("📊 First launch recorded for baseline tracking")
        }
    }

    var firstLaunchDate: Date? {
        return UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date
    }

    var daysSinceFirstLaunch: Int {
        guard let firstLaunch = firstLaunchDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
    }

    // MARK: - Today's Metrics
    var todayScreenTime: TimeInterval {
        return dailyScreenTime[todayDateString] ?? 0
    }

    var todayPickups: Int {
        return dailyPickups[todayDateString] ?? 0
    }

    var todayNotifications: Int {
        return dailyNotifications[todayDateString] ?? 0
    }

    // MARK: - Goal Tracking
    var todayGoalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayScreenTime / dailyGoal, 1.0)
    }

    var todayRemainingTime: TimeInterval {
        return max(0, dailyGoal - todayScreenTime)
    }

    var isTodayGoalMet: Bool {
        return todayScreenTime <= dailyGoal
    }

    // MARK: - Focus Score (0-100)
    var focusScore: Int {
        guard dailyGoal > 0 else { return 100 }
        let usagePercent = todayScreenTime / dailyGoal
        return max(0, 100 - Int(usagePercent * 100))
    }

    var focusScoreColor: Color {
        switch focusScore {
        case 80...100:
            return .accentGreen
        case 50...79:
            return .accentYellow
        case 20...49:
            return .accentOrange
        default:
            return .accentRed
        }
    }

    var focusScoreStatus: String {
        switch focusScore {
        case 80...100:
            return "Excellent!"
        case 50...79:
            return "Good job!"
        case 20...49:
            return "Keep trying"
        default:
            return "Needs focus"
        }
    }

    var goalMetStreak: Int {
        let goalMetDates = UserDefaults.standard.stringArray(forKey: goalMetDatesKey) ?? []
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()

        // Count backwards from today
        while true {
            let dateString = Self.dateString(from: currentDate)
            if goalMetDates.contains(dateString) {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    func updateTodayGoalStatus() {
        var goalMetDates = Set(UserDefaults.standard.stringArray(forKey: goalMetDatesKey) ?? [])

        if isTodayGoalMet {
            goalMetDates.insert(todayDateString)
        } else {
            goalMetDates.remove(todayDateString)
        }

        UserDefaults.standard.set(Array(goalMetDates), forKey: goalMetDatesKey)
    }

    // MARK: - Baseline Metrics (First 3-7 Days)
    var baselineScreenTime: TimeInterval {
        return UserDefaults.standard.double(forKey: baselineScreenTimeKey)
    }

    var baselinePickups: Int {
        return UserDefaults.standard.integer(forKey: baselinePickupsKey)
    }

    var hasBaseline: Bool {
        return baselineScreenTime > 0
    }

    func calculateAndStoreBaseline() {
        // Calculate baseline after first 3-7 days
        guard daysSinceFirstLaunch >= 3 else {
            print("📊 Not enough days for baseline (\(daysSinceFirstLaunch)/3)")
            return
        }

        // If baseline already set, don't recalculate
        guard !hasBaseline else {
            print("📊 Baseline already calculated")
            return
        }

        let calendar = Calendar.current
        var totalScreenTime: TimeInterval = 0
        var totalPickups = 0
        var dayCount = 0

        // Get first 7 days of data
        for dayOffset in 0..<min(7, daysSinceFirstLaunch) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            if let screenTime = dailyScreenTime[dateString] {
                totalScreenTime += screenTime
                totalPickups += dailyPickups[dateString] ?? 0
                dayCount += 1
            }
        }

        guard dayCount > 0 else {
            print("📊 No data available for baseline")
            return
        }

        let avgScreenTime = totalScreenTime / Double(dayCount)
        let avgPickups = totalPickups / dayCount

        UserDefaults.standard.set(avgScreenTime, forKey: baselineScreenTimeKey)
        UserDefaults.standard.set(avgPickups, forKey: baselinePickupsKey)

        print("📊 Baseline calculated: \(Int(avgScreenTime/60))min screen time, \(avgPickups) pickups")
    }

    // MARK: - Time Saved Calculations
    var timeSavedToday: TimeInterval {
        guard hasBaseline else { return 0 }
        return max(0, baselineScreenTime - todayScreenTime)
    }

    var timeSavedThisWeek: TimeInterval {
        guard hasBaseline else { return 0 }

        let calendar = Calendar.current
        var totalSaved: TimeInterval = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            if let screenTime = dailyScreenTime[dateString] {
                let saved = max(0, baselineScreenTime - screenTime)
                totalSaved += saved
            }
        }

        return totalSaved
    }

    // MARK: - Weekly Stats
    var weeklyAverage: TimeInterval {
        let calendar = Calendar.current
        var totalTime: TimeInterval = 0
        var dayCount = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            if let screenTime = dailyScreenTime[dateString] {
                totalTime += screenTime
                dayCount += 1
            }
        }

        guard dayCount > 0 else { return 0 }
        return totalTime / Double(dayCount)
    }

    var weeklyAveragePickups: Int {
        let calendar = Calendar.current
        var totalPickups = 0
        var dayCount = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            if let pickups = dailyPickups[dateString] {
                totalPickups += pickups
                dayCount += 1
            }
        }

        guard dayCount > 0 else { return 0 }
        return totalPickups / dayCount
    }

    var goalMetDaysThisWeek: Int {
        let goalMetDates = Set(UserDefaults.standard.stringArray(forKey: goalMetDatesKey) ?? [])
        let calendar = Calendar.current
        var count = 0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            if goalMetDates.contains(dateString) {
                count += 1
            }
        }

        return count
    }

    var weeklyGoalMetCount: Int {
        return goalMetDaysThisWeek
    }

    // MARK: - Update Methods
    func updateTodayScreenTime(_ seconds: TimeInterval) {
        dailyScreenTime[todayDateString] = seconds
        updateTodayGoalStatus()
        calculateAndStoreBaseline()
        save()
    }

    func updateTodayPickups(_ count: Int) {
        dailyPickups[todayDateString] = count
        save()
    }

    func updateTodayNotifications(_ count: Int) {
        dailyNotifications[todayDateString] = count
        save()
    }

    func setDailyGoal(_ seconds: TimeInterval) {
        dailyGoal = seconds
        UserDefaults.standard.set(seconds, forKey: dailyGoalKey)

        // Also save to App Group UserDefaults for DeviceActivityReport extension to read
        sharedDefaults?.set(seconds, forKey: dailyGoalKey)

        updateTodayGoalStatus()
        print("📊 Daily goal set to \(Int(seconds/3600))h \(Int((seconds.truncatingRemainder(dividingBy: 3600))/60))m")
    }

    // MARK: - Historical Data
    func getScreenTime(for date: Date) -> TimeInterval {
        let dateString = Self.dateString(from: date)
        return dailyScreenTime[dateString] ?? 0
    }

    func getPickups(for date: Date) -> Int {
        let dateString = Self.dateString(from: date)
        return dailyPickups[dateString] ?? 0
    }

    func getWeeklyScreenTime() -> [(date: Date, screenTime: TimeInterval)] {
        let calendar = Calendar.current
        var result: [(Date, TimeInterval)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let screenTime = getScreenTime(for: date)
            result.append((date, screenTime))
        }

        return result
    }

    // MARK: - Persistence
    func save() {
        // Save dictionaries as JSON
        if let screenTimeData = try? JSONEncoder().encode(dailyScreenTime) {
            UserDefaults.standard.set(screenTimeData, forKey: dailyScreenTimeKey)
        }

        if let pickupsData = try? JSONEncoder().encode(dailyPickups) {
            UserDefaults.standard.set(pickupsData, forKey: dailyPickupsKey)
        }

        if let notificationsData = try? JSONEncoder().encode(dailyNotifications) {
            UserDefaults.standard.set(notificationsData, forKey: dailyNotificationsKey)
        }
    }

    func load() {
        // Load goal
        let savedGoal = UserDefaults.standard.double(forKey: dailyGoalKey)
        if savedGoal > 0 {
            dailyGoal = savedGoal
            // Sync to App Group for extension access
            sharedDefaults?.set(savedGoal, forKey: dailyGoalKey)
        } else {
            // Set default goal in shared defaults if not set
            sharedDefaults?.set(dailyGoal, forKey: dailyGoalKey)
        }

        // Load screen time
        if let data = UserDefaults.standard.data(forKey: dailyScreenTimeKey),
           let decoded = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            dailyScreenTime = decoded
        }

        // Load pickups
        if let data = UserDefaults.standard.data(forKey: dailyPickupsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyPickups = decoded
        }

        // Load notifications
        if let data = UserDefaults.standard.data(forKey: dailyNotificationsKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyNotifications = decoded
        }

        print("📊 StatisticsManager loaded: \(dailyScreenTime.count) days of screen time data")
    }

    // MARK: - Helper Methods
    private var todayDateString: String {
        return Self.dateString(from: Date())
    }

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func dateString(from date: Date) -> String {
        return Self.dateString(from: date)
    }

    // MARK: - Formatted Strings
    func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    func formatTimeShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)min"
        }
    }

    // MARK: - Debug/Testing
    func simulateData() {
        #if DEBUG
        let calendar = Calendar.current

        // Simulate 14 days of data
        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let dateString = Self.dateString(from: date)

            // Random screen time between 1-5 hours
            let screenTime = TimeInterval.random(in: 3600...18000)
            dailyScreenTime[dateString] = screenTime

            // Random pickups between 20-100
            dailyPickups[dateString] = Int.random(in: 20...100)

            // Random notifications between 10-50
            dailyNotifications[dateString] = Int.random(in: 10...50)
        }

        // Set baseline (first 7 days average)
        UserDefaults.standard.set(14400.0, forKey: baselineScreenTimeKey) // 4 hours
        UserDefaults.standard.set(60, forKey: baselinePickupsKey)

        save()
        print("📊 DEBUG: Simulated 14 days of statistics data")
        #endif
    }
}
