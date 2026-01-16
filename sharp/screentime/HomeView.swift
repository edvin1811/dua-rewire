//
//  HomeView.swift
//  sharp
//
//  Simple, welcoming home page with key stats at a glance
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var statisticsManager = StatisticsManager.shared
    @State private var showContent = false
    @State private var currentStreak: Int = 7

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var goalProgress: Double {
        let target = statisticsManager.dailyGoal
        let current = statisticsManager.todayScreenTime
        guard target > 0 else { return 1.0 }
        return min(max(1 - (current / target), 0), 1)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                headerSection

                VStack(spacing: 24) {
                    // Today's Progress Card
                    todayProgressCard
                        .padding(.horizontal, 20)

                    // Quick Stats
                    quickStatsSection
                        .padding(.horizontal, 20)

                    // Active Session (if any)
                    if appStateManager.activeTimerSession != nil || appStateManager.activeTaskSession != nil {
                        activeSessionCard
                            .padding(.horizontal, 20)
                    }

                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, 20)

                    Color.clear.frame(height: 120)
                }
                .padding(.top, 24)
            }
        }
        .background(Color.uwBackground)
        .onAppear {
            withAnimation(DuoAnimation.heroEntrance.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.uwPrimary, Color.uwPrimaryDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 60, y: -40)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height - 20)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Text("Stay focused today")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Streak badge
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.uwAccent)

                    Text("\(currentStreak) day streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
                .padding(.top, 8)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .padding(.top, 8)
        }
        .frame(height: 180)
    }

    // MARK: - Today's Progress Card
    private var todayProgressCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Text(formatDate(Date()))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.uwTextSecondary)
            }

            HStack(spacing: 24) {
                // Goal Ring
                ZStack {
                    Circle()
                        .stroke(Color.uwPrimary.opacity(0.15), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: showContent ? goalProgress : 0)
                        .stroke(Color.uwPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(DuoAnimation.progressUpdate.delay(0.3), value: showContent)

                    VStack(spacing: 2) {
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.uwTextPrimary)

                        Text("of goal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.uwTextSecondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    statRow(
                        icon: "hourglass",
                        label: "Screen time",
                        value: formatScreenTime(statisticsManager.todayScreenTime),
                        color: .uwPrimary
                    )

                    statRow(
                        icon: "hand.tap",
                        label: "Pickups",
                        value: "\(statisticsManager.todayPickups)",
                        color: .uwAccent
                    )
                }

                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.uwCard)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.uwBorder, lineWidth: 1)
        )
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.uwTextPrimary)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.uwTextSecondary)
            }
        }
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            quickStatCard(
                icon: "checkmark.circle.fill",
                value: "\(appStateManager.completedSessionsToday)",
                label: "Sessions",
                color: .uwSuccess
            )

            quickStatCard(
                icon: "clock.fill",
                value: formatBlockedTime(appStateManager.totalBlockedTimeToday),
                label: "Focused",
                color: .uwPrimary
            )

            quickStatCard(
                icon: "star.fill",
                value: "+\(appStateManager.completedSessionsToday * 10 + 50)",
                label: "Points",
                color: .uwAccent
            )
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(DuoAnimation.cascade(index: 1), value: showContent)
    }

    private func quickStatCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.uwTextPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.uwTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.uwCard)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.uwBorder, lineWidth: 1)
        )
    }

    // MARK: - Active Session Card
    private var activeSessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.uwAccent)
                    .frame(width: 8, height: 8)

                Text("Active Session")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.uwAccent)

                Spacer()

                if let timer = appStateManager.activeTimerSession {
                    Text(formatTimeRemaining(timer.timeRemaining))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.uwTextPrimary)
                }
            }

            if let timer = appStateManager.activeTimerSession {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.uwBorder)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.uwAccent)
                            .frame(width: geo.size.width * (1 - timer.timeRemaining / timer.duration))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.uwAccent.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.uwAccent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.uwTextPrimary)

            HStack(spacing: 12) {
                quickActionButton(
                    icon: "timer",
                    label: "Start Focus",
                    color: .uwPrimary
                )

                quickActionButton(
                    icon: "chart.bar",
                    label: "View Insights",
                    color: .uwTextSecondary
                )
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(DuoAnimation.cascade(index: 2), value: showContent)
    }

    private func quickActionButton(icon: String, label: String, color: Color) -> some View {
        Button(action: {
            DuoHaptics.lightTap()
        }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(color == .uwPrimary ? .white : .uwTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color == .uwPrimary ? color : Color.uwCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color == .uwPrimary ? Color.clear : Color.uwBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private func formatScreenTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private func formatBlockedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview
#Preview("Home - Light") {
    HomeView()
        .environmentObject(AppStateManager())
}

#Preview("Home - Dark") {
    HomeView()
        .environmentObject(AppStateManager())
        .preferredColorScheme(.dark)
}
