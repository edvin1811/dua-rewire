import SwiftUI
import FamilyControls
import DeviceActivity
import CoreData

// MARK: - Insights View (Screen Time Analytics)
// Alias for backwards compatibility
typealias InsightsView = CalendarView

struct CalendarView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var statisticsManager = StatisticsManager.shared

    @State private var selectedTab: CalendarTab = .daily
    @State private var selectedDate = Date()
    @State private var selectedWeek: Date = {
        let calendar = Calendar.current
        return calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }()
    @State private var reportRefreshID = UUID()
    @State private var showContent = false
    @State private var streakDays: Int = 7

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.taskCreatedAt, ascending: false)],
        animation: .default
    ) private var tasks: FetchedResults<TaskEntity>

    var completedTasksToday: [TaskEntity] {
        let today = Calendar.current.startOfDay(for: selectedDate)
        return tasks.filter {
            $0.taskIsCompleted &&
            Calendar.current.isDate($0.taskCompletedAt ?? Date(), inSameDayAs: today)
        }
    }

    var tasksForSelectedDate: [TaskEntity] {
        let calendar = Calendar.current
        let selectedWeekday = calendar.component(.weekday, from: selectedDate)

        return tasks.filter { task in
            if let scheduledDate = task.value(forKey: "taskScheduledDate") as? Date {
                if let pattern = task.value(forKey: "taskRecurrencePattern") as? String,
                   let daysString = task.value(forKey: "taskRecurrenceDays") as? String {
                    let recurringDays = daysString.split(separator: ",").compactMap { Int($0) }
                    return recurringDays.contains(selectedWeekday)
                } else {
                    return calendar.isDate(scheduledDate, inSameDayAs: selectedDate)
                }
            }
            guard let taskDate = task.taskCreatedAt else { return false }
            return calendar.isDate(taskDate, inSameDayAs: selectedDate)
        }
    }

    private var dailyGoalProgress: Double {
        let target = statisticsManager.dailyGoal
        let current = statisticsManager.todayScreenTime
        guard target > 0 else { return 0 }
        return min(max(1 - (current / target), 0), 1)
    }

    var body: some View {
        ZStack {
            ModernBackground()

            if appStateManager.authorizationState != .granted {
                authorizationSection
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        heroHeaderSection

                        tabSelector
                            .padding(.horizontal, Spacing.lg)

                        switch selectedTab {
                        case .daily:
                            dailyContent
                        case .weekly:
                            weeklyContent
                        case .trends:
                            trendsContent
                        }

                        Color.clear.frame(height: 100)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(DuoAnimation.heroEntrance.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Hero Header Section (Duolingo-style - flat card with border)
    private var heroHeaderSection: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text("Insights")
                    .font(Typography.title1)
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Button {
                    reportRefreshID = UUID()
                    DuoHaptics.lightTap()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.uwPrimary)
                        .padding(Spacing.sm)
                        .background(
                            Circle()
                                .fill(Color.uwPrimary.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.md)

            // Summary card - flat with border (not clickable = no shadow)
            HStack(spacing: Spacing.lg) {
                // Goal Ring - Duolingo blue (flat)
                ZStack {
                    Circle()
                        .stroke(Color.uwBorder, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: showContent ? dailyGoalProgress : 0)
                        .stroke(Color.uwPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(DuoAnimation.progressUpdate.delay(0.2), value: showContent)

                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(dailyGoalProgress * 100))%")
                            .font(Typography.title2)
                            .foregroundColor(.uwTextPrimary)

                        Text("of goal")
                            .font(Typography.caption)
                            .foregroundColor(.uwTextSecondary)
                    }
                }
                .frame(width: 90, height: 90)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Screen Time")
                            .font(Typography.caption)
                            .foregroundColor(.uwTextSecondary)

                        Text(formatScreenTime())
                            .font(Typography.title1)
                            .foregroundColor(.uwTextPrimary)
                    }

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: dailyGoalProgress >= 0.5 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 11, weight: .bold))
                        Text(dailyGoalProgress >= 0.5 ? "On track" : "Keep going")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(dailyGoalProgress >= 0.5 ? .uwSuccess : .uwAccent)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(dailyGoalProgress >= 0.5 ? Color.uwSuccess.opacity(0.12) : Color.uwAccent.opacity(0.12))
                    )
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -10)

                Spacer()
            }
            .duoCard(padding: Spacing.md, cornerRadius: Radius.lg)
            .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(CalendarTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(DuoAnimation.tabSwitch) {
                        selectedTab = tab
                    }
                    DuoHaptics.selection()
                } label: {
                    Text(tab.rawValue)
                        .font(Typography.subhead)
                        .fontWeight(selectedTab == tab ? .semibold : .medium)
                        .foregroundColor(selectedTab == tab ? .uwPrimary : .uwTextSecondary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(
                            Capsule()
                                .fill(selectedTab == tab ? Color.uwPrimary.opacity(0.12) : Color.clear)
                        )
                }
            }

            Spacer()
        }
        .padding(Spacing.xs)
        .background(
            Capsule()
                .fill(Color.uwCard)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.uwBorder, lineWidth: 1)
                )
        )
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Daily Content
    private var dailyContent: some View {
        VStack(spacing: Spacing.lg) {
            dateSelector
                .padding(.horizontal, Spacing.lg)

            usageChart
                .padding(.horizontal, Spacing.lg)

            dailyUsagePattern
                .padding(.horizontal, Spacing.lg)

            mostUsedAppsSection
                .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Daily Quests Section
    private var dailyQuestsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Daily Goals")
                    .font(Typography.title3)
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .font(Typography.caption)
                        .fontWeight(.bold)
                    Text("6 HOURS")
                        .font(Typography.caption)
                        .fontWeight(.heavy)
                }
                .foregroundColor(.uwWarning)
            }

            VStack(spacing: Spacing.sm) {
                DuoQuestCard(
                    title: "Stay under screen time goal",
                    progress: dailyGoalProgress,
                    current: Int(dailyGoalProgress * 100),
                    total: 100,
                    icon: "hourglass",
                    iconColor: .accentBlue
                )

                DuoQuestCard(
                    title: "Complete your tasks",
                    progress: tasksForSelectedDate.isEmpty ? 0 : Double(completedTasksToday.count) / Double(max(tasksForSelectedDate.count, 1)),
                    current: completedTasksToday.count,
                    total: max(tasksForSelectedDate.count, 1),
                    icon: "checkmark.circle.fill",
                    iconColor: .uwSuccess
                )

                DuoQuestCard(
                    title: "Focus sessions completed",
                    progress: min(Double(appStateManager.completedSessionsToday) / 3.0, 1.0),
                    current: appStateManager.completedSessionsToday,
                    total: 3,
                    icon: "brain.head.profile",
                    iconColor: .uwPurple
                )
            }
        }
        .opacity(showContent ? 1 : 0)
        .animation(DuoAnimation.cascade(index: 3), value: showContent)
    }

    // MARK: - Helper Methods
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private func formatScreenTime() -> String {
        let total = statisticsManager.todayScreenTime
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Date Selector
    private var dateSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(formatMonthYear(selectedDate))
                .font(Typography.subhead)
                .fontWeight(.semibold)
                .foregroundColor(.uwTextSecondary)

            HStack(spacing: Spacing.sm) {
                ForEach(Array(getWeekDates().enumerated()), id: \.element) { index, date in
                    datePill(date: date, index: index)
                }
            }
        }
        .opacity(showContent ? 1 : 0)
    }

    private func datePill(date: Date, index: Int) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        return Button {
            withAnimation(DuoAnimation.tabSwitch) {
                selectedDate = date
            }
            DuoHaptics.selection()
        } label: {
            VStack(spacing: Spacing.xs) {
                Text(formatDayName(date))
                    .font(Typography.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .uwTextTertiary)

                Text(formatDayNumber(date))
                    .font(Typography.callout)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : (isToday ? .uwPrimary : .uwTextPrimary))

                // Today indicator
                Circle()
                    .fill(isToday && !isSelected ? Color.uwPrimary : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(isSelected ? Color.uwPrimary : Color.uwCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(isSelected ? Color.clear : Color.uwBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Screen Time Cards
    private var screenTimeCards: some View {
        DeviceActivityReport(
            DeviceActivityReport.Context(rawValue: "CalendarScreenTime"),
            filter: getCurrentFilter()
        )
        .frame(height: 120)
        .id(reportRefreshID)
    }

    // MARK: - Usage Chart
    private var usageChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HourlyUsageChart(selectedDate: selectedDate)
        }
    }

    // MARK: - Daily Usage Pattern (Stats Cards)
    private var dailyUsagePattern: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Today's Stats")
                .font(Typography.headline)
                .foregroundColor(.uwTextPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                statsCard(
                    icon: "sun.max.fill",
                    iconColor: .uwAccent,
                    value: formatFirstPickup(),
                    label: "First pickup"
                )

                statsCard(
                    icon: "hand.tap.fill",
                    iconColor: .uwPrimary,
                    value: "\(getTotalPickups())",
                    label: "Total pickups"
                )

                statsCard(
                    icon: "checkmark.circle.fill",
                    iconColor: .uwSuccess,
                    value: "\(completedTasksToday.count)/\(tasksForSelectedDate.count)",
                    label: "Tasks done"
                )

                statsCard(
                    icon: "clock.fill",
                    iconColor: .uwPrimary,
                    value: formatTimeBlocked(),
                    label: "Focus time"
                )
            }
        }
        .opacity(showContent ? 1 : 0)
    }

    // MARK: - Stats Card
    private func statsCard(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(value)
                    .font(Typography.headline)
                    .foregroundColor(.uwTextPrimary)

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(.uwTextSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.uwCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(Color.uwBorder, lineWidth: 1)
        )
    }

    // MARK: - Tasks Section
    @ViewBuilder
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Tasks")
                    .font(Typography.title3)
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Text("\(completedTasksToday.count)/\(tasksForSelectedDate.count)")
                    .font(Typography.headline)
                    .foregroundColor(.uwPrimary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(tasksForSelectedDate, id: \.objectID) { task in
                    taskRow(task: task)
                }
            }
        }
    }

    private func taskRow(task: TaskEntity) -> some View {
        HStack(spacing: Spacing.md) {
            Button {
                toggleTask(task)
                DuoHaptics.success()
            } label: {
                ZStack {
                    if task.taskIsCompleted {
                        Circle()
                            .fill(Color.uwPrimaryDark)
                            .frame(width: 28, height: 28)
                            .offset(y: 2)
                    }

                    Circle()
                        .fill(task.taskIsCompleted ? Color.uwPrimary : Color.uwCard)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(task.taskIsCompleted ? Color.clear : Color.uwTextTertiary, lineWidth: 2)
                        )

                    if task.taskIsCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Text(task.taskTitle ?? "Untitled")
                .font(Typography.callout)
                .fontWeight(task.taskIsCompleted ? .medium : .bold)
                .foregroundColor(task.taskIsCompleted ? .uwTextSecondary : .uwTextPrimary)
                .strikethrough(task.taskIsCompleted, color: .uwTextSecondary)

            Spacer()
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.uwCard)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(Color.uwCardShadow.opacity(0.3), lineWidth: 2)
                )
        )
    }

    // MARK: - Most Used Apps Section
    private var mostUsedAppsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Most used apps")
                .font(Typography.headline)
                .foregroundColor(.uwTextPrimary)

            DeviceActivityReport(
                DeviceActivityReport.Context(rawValue: "CalendarMostUsedApps"),
                filter: getCurrentFilter()
            )
            .frame(minHeight: 350)
            .id("\(reportRefreshID)-\(selectedDate)")
        }
    }

    // MARK: - Weekly Content
    private var weeklyContent: some View {
        VStack(spacing: Spacing.lg) {
            weekSelector
                .padding(.horizontal, Spacing.lg)

            progressChart
                .padding(.horizontal, Spacing.lg)

            weeklySummaryCards
                .padding(.horizontal, Spacing.lg)
        }
    }

    // MARK: - Week Selector
    private var weekSelector: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(getWeeks(), id: \.self) { week in
                weekPill(week: week)
            }
        }
    }

    private func weekPill(week: Date) -> some View {
        let isSelected = isSameWeek(week, as: selectedWeek)
        let weekNumber = Calendar.current.component(.weekOfYear, from: week)

        return Button {
            withAnimation(DuoAnimation.tabSwitch) {
                selectedWeek = week
            }
            DuoHaptics.selection()
        } label: {
            Text("W\(weekNumber)")
                .font(Typography.subhead)
                .fontWeight(isSelected ? .heavy : .medium)
                .foregroundColor(isSelected ? .white : .uwTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color.uwPrimaryDark)
                                .offset(y: 2)

                            Capsule()
                                .fill(Color.uwPrimary)
                        } else {
                            Capsule()
                                .fill(Color.uwCard)
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Progress Chart
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your progress")
                .font(Typography.headline)
                .foregroundColor(.uwTextPrimary)

            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.uwTextTertiary.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Text("Progress Chart")
                        .font(Typography.subhead)
                        .foregroundColor(.uwTextSecondary)
                )
        }
        .duoCard()
    }

    // MARK: - Weekly Summary Cards
    private var weeklySummaryCards: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Weekly Summary")
                .font(Typography.headline)
                .foregroundColor(.uwTextPrimary)

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Total Time Saved")
                    .font(Typography.subhead)
                    .foregroundColor(.uwTextSecondary)

                Text(formatTimeSaved())
                    .font(Typography.largeTitle)
                    .foregroundColor(.uwAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .duoCard()

            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Most Distracted")
                        .font(Typography.footnote)
                        .foregroundColor(.uwTextSecondary)

                    Text(formatMostDistractedTime())
                        .font(Typography.title1)
                        .foregroundColor(.uwTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .duoCard()

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Avg Screen Time")
                        .font(Typography.footnote)
                        .foregroundColor(.uwTextSecondary)

                    Text(formatAvgScreenTime())
                        .font(Typography.title1)
                        .foregroundColor(.uwTextPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .duoCard()
            }
        }
    }

    // MARK: - Trends Content
    private var trendsContent: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.uwTextTertiary)

                Text("Trends coming soon")
                    .font(Typography.headline)
                    .foregroundColor(.uwTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Authorization Section
    private var authorizationSection: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.uwPrimary.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.uwPrimary)
                }

                VStack(spacing: Spacing.md) {
                    Text("Screen Time Access")
                        .font(Typography.title1)
                        .foregroundColor(.uwTextPrimary)

                    Text("Track your app usage and stay focused.")
                        .font(Typography.body)
                        .foregroundColor(.uwTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    appStateManager.requestAuthorizationIfNeeded()
                    DuoHaptics.buttonTap()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Text("Grant Access")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(DuoPrimaryButton())
                .padding(.horizontal, Spacing.xxl)
            }
            .duoCard()
            .padding(.horizontal, Spacing.lg)

            Spacer()
        }
    }

    // MARK: - Helper Methods
    private func getCurrentFilter() -> DeviceActivityFilter {
        guard let todayInterval = Calendar.current.dateInterval(of: .day, for: selectedDate) else {
            fatalError("Could not create date interval")
        }

        return DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    private func toggleTask(_ task: TaskEntity) {
        withAnimation(DuoAnimation.checkboxPop) {
            task.taskIsCompleted.toggle()
            task.taskCompletedAt = task.taskIsCompleted ? Date() : nil

            do {
                try viewContext.save()
            } catch {
                print("Error saving task: \(error)")
            }
        }
    }

    private func formatFirstPickup() -> String { "7:30 AM" }
    private func getTotalPickups() -> Int { 47 }

    private func formatTimeBlocked() -> String {
        let blockedSeconds = appStateManager.totalBlockedTimeToday
        let hours = Int(blockedSeconds) / 3600
        let minutes = (Int(blockedSeconds) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        else if minutes > 0 { return "\(minutes)m" }
        else { return "0m" }
    }

    private func formatTimeSaved() -> String {
        let saved = statisticsManager.timeSavedThisWeek
        let hours = Int(saved) / 3600
        let minutes = (Int(saved) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatMostDistractedTime() -> String { "4 PM" }

    private func formatAvgScreenTime() -> String {
        let avg = statisticsManager.weeklyAverage
        let hours = Int(avg) / 3600
        let minutes = (Int(avg) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM"
        return formatter.string(from: date)
    }

    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func getWeekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func getWeeks() -> [Date] {
        let calendar = Calendar.current
        var weeks: [Date] = []
        for i in 0..<4 {
            if let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
               let week = calendar.date(byAdding: .weekOfYear, value: i - 1, to: weekStart) {
                weeks.append(week)
            }
        }
        return weeks
    }

    private func getWeekRange(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return (date, date)
        }
        return (interval.start, interval.end)
    }

    private func isSameWeek(_ date1: Date, as date2: Date) -> Bool {
        Calendar.current.isDate(date1, equalTo: date2, toGranularity: .weekOfYear)
    }
}

// MARK: - Calendar Tab Enum
enum CalendarTab: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case trends = "Trends"
}

// MARK: - Hourly Usage Chart
struct HourlyUsageChart: View {
    let selectedDate: Date
    @State private var selectedHour: Int? = nil
    @State private var animatedBars: [Bool] = Array(repeating: false, count: 24)
    @State private var chartWidth: CGFloat = 0
    @State private var showChart = false

    private var hourlyData: [Int: Int] {
        [
            0: 5, 1: 2, 2: 0, 3: 0, 4: 0, 5: 3,
            6: 12, 7: 25, 8: 35, 9: 28, 10: 22, 11: 18,
            12: 42, 13: 38, 14: 30, 15: 25, 16: 45, 17: 52,
            18: 48, 19: 55, 20: 60, 21: 45, 22: 30, 23: 15
        ]
    }

    private var maxMinutes: Int { max(hourlyData.values.max() ?? 60, 60) }
    private var totalMinutes: Int { hourlyData.values.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with title
            HStack {
                Text("Hourly Activity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                // Peak hours indicator
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Peak: 8-9 PM")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.uwAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.uwAccent.opacity(0.12))
                )
            }

            VStack(spacing: 12) {
                // Tooltip
                ZStack {
                    if let hour = selectedHour {
                        let minutes = hourlyData[hour] ?? 0
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTimeRange(hour))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.uwTextSecondary)

                                Text("\(minutes) min")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.uwPrimary)
                            }

                            Spacer()

                            // Percentage of day
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int((Double(minutes) / Double(totalMinutes)) * 100))%")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.uwTextPrimary)
                                Text("of daily")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.uwTextSecondary)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.uwSurface)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                    }
                }
                .frame(height: 52)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: selectedHour)

                // Chart bars with gradient background
                ZStack(alignment: .bottom) {
                    // Horizontal grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<4) { i in
                            Spacer()
                            if i < 3 {
                                Rectangle()
                                    .fill(Color.uwTextTertiary.opacity(0.15))
                                    .frame(height: 1)
                            }
                        }
                    }
                    .frame(height: 140)

                    // Bars
                    GeometryReader { geometry in
                        HStack(alignment: .bottom, spacing: 3) {
                            ForEach(0..<24, id: \.self) { hour in
                                let minutes = hourlyData[hour] ?? 0
                                let height = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(maxMinutes) * 140 : 0
                                let isSelected = selectedHour == hour

                                VStack(spacing: 0) {
                                    Spacer()

                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(
                                            LinearGradient(
                                                colors: barGradientColors(for: minutes, isSelected: isSelected),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: animatedBars[hour] ? max(height, 8) : 8)
                                        .overlay(
                                            // Shine effect on selected bar
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(isSelected ? 0.3 : 0),
                                                            Color.white.opacity(0)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .center
                                                    )
                                                )
                                        )
                                        .scaleEffect(x: isSelected ? 1.15 : 1.0, y: 1.0, anchor: .bottom)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7)
                                            .delay(Double(hour) * 0.02),
                                            value: animatedBars[hour]
                                        )
                                        .animation(DuoAnimation.microBounce, value: isSelected)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear { chartWidth = geo.size.width }
                            }
                        )
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let barWidth = chartWidth / 24
                                    let hour = Int(value.location.x / barWidth)
                                    let clampedHour = max(0, min(23, hour))

                                    if selectedHour != clampedHour {
                                        selectedHour = clampedHour
                                        DuoHaptics.lightTap()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(DuoAnimation.smoothSlide) {
                                        selectedHour = nil
                                    }
                                }
                        )
                    }
                    .frame(height: 140)
                }
                .padding(.horizontal, 4)

                // X-axis labels
                HStack {
                    Text("12a")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.uwTextTertiary)
                    Spacer()
                    Text("6a")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.uwTextTertiary)
                    Spacer()
                    Text("12p")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.uwTextTertiary)
                    Spacer()
                    Text("6p")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.uwTextTertiary)
                    Spacer()
                    Text("12a")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.uwTextTertiary)
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.uwCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.uwBorder, lineWidth: 1)
            )
        }
        .opacity(showChart ? 1 : 0)
        .onAppear {
            withAnimation(DuoAnimation.progressUpdate.delay(0.2)) {
                showChart = true
            }
            animateBars()
        }
        .onChange(of: selectedDate) { _, _ in
            animatedBars = Array(repeating: false, count: 24)
            selectedHour = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animateBars() }
        }
    }

    private func barGradientColors(for minutes: Int, isSelected: Bool) -> [Color] {
        if isSelected {
            return [Color.uwAccent, Color.uwAccentDark]
        }

        let intensity = CGFloat(minutes) / CGFloat(maxMinutes)

        // Duolingo-style vibrant gradient
        // Low usage: Duolingo blue, High usage: lime green (good = less usage)
        if intensity < 0.3 {
            // Low usage - vibrant green (good!)
            return [Color.uwSuccess, Color.uwSuccessDark]
        } else if intensity < 0.6 {
            // Medium usage - Duolingo blue
            return [Color.uwPrimary.opacity(0.9), Color.uwPrimaryDark.opacity(0.7)]
        } else {
            // High usage - golden yellow (warning)
            return [Color.uwAccent, Color.uwAccentDark]
        }
    }

    private func formatTimeRange(_ hour: Int) -> String {
        func format(_ h: Int) -> String {
            if h == 0 { return "12 AM" }
            if h < 12 { return "\(h) AM" }
            if h == 12 { return "12 PM" }
            return "\(h - 12) PM"
        }
        return "\(format(hour)) - \(format((hour + 1) % 24))"
    }

    private func animateBars() {
        for i in 0..<24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedBars[i] = true
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(AppStateManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
