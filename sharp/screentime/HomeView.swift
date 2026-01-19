//
//  HomeView.swift
//  sharp
//
//  Simple, welcoming home page with key stats at a glance
//  Using Duolingo design system tokens
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

                VStack(spacing: Spacing.lg) {
                    // Today's Progress Card
                    todayProgressCard
                        .padding(.horizontal, Spacing.lg)

                    // Quick Stats
                    quickStatsSection
                        .padding(.horizontal, Spacing.lg)

                    // Active Session (if any)
                    if appStateManager.activeTimerSession != nil || appStateManager.activeTaskSession != nil {
                        activeSessionCard
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Quick Actions
                    quickActionsSection
                        .padding(.horizontal, Spacing.lg)

                    Color.clear.frame(height: 120)
                }
                .padding(.top, Spacing.lg)
            }
        }
        .background(Color.uwBackground)
        .onAppear {
            withAnimation(DuoAnimation.heroEntrance.delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section (Duolingo-style vibrant header)
    private var headerSection: some View {
        ZStack {
            // Vibrant gradient background - Duolingo blue to green
            LinearGradient(
                colors: [Color.uwPrimary, Color(hex: "1899D6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements - subtle floating circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .offset(x: geo.size.width - 60, y: -40)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height - 30)
            }

            // Content
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(greeting)
                    .font(Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Text("Stay focused today")
                    .font(Typography.title1)
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Streak badge - vibrant fire orange
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.streakOrange)

                    Text("\(currentStreak) day streak")
                        .font(Typography.subhead)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.2))
                )
                .padding(.top, Spacing.sm)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xl)
            .padding(.top, Spacing.sm)
        }
        .frame(height: 180)
    }

    // MARK: - Today's Progress Card (Duolingo-style - flat card with border, no shadow)
    private var todayProgressCard: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("Today's Progress")
                    .font(Typography.headline)
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Text(formatDate(Date()))
                    .font(Typography.footnote)
                    .foregroundColor(.uwTextSecondary)
            }

            HStack(spacing: Spacing.lg) {
                // Goal Ring - Duolingo blue (flat, no gradient)
                ZStack {
                    Circle()
                        .stroke(Color.uwBorder, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: showContent ? goalProgress : 0)
                        .stroke(Color.uwPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(DuoAnimation.progressUpdate.delay(0.3), value: showContent)

                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(goalProgress * 100))%")
                            .font(Typography.title2)
                            .foregroundColor(.uwTextPrimary)

                        Text("of goal")
                            .font(Typography.caption)
                            .foregroundColor(.uwTextSecondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Stats
                VStack(alignment: .leading, spacing: Spacing.md) {
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
        .duoCard(padding: Spacing.md, cornerRadius: Radius.lg)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(value)
                    .font(Typography.headline)
                    .foregroundColor(.uwTextPrimary)

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(.uwTextSecondary)
            }
        }
    }

    // MARK: - Quick Stats Section (Duolingo-style cards)
    private var quickStatsSection: some View {
        HStack(spacing: Spacing.md) {
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
        VStack(spacing: Spacing.sm) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(Typography.headline)
                .foregroundColor(.uwTextPrimary)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(.uwTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .duoCard(padding: 0, cornerRadius: Radius.lg)
    }

    // MARK: - Active Session Card (status display - flat with green border)
    private var activeSessionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Pulsing indicator
                Circle()
                    .fill(Color.uwSuccess)
                    .frame(width: 8, height: 8)

                Text("Active Session")
                    .font(Typography.subhead)
                    .fontWeight(.bold)
                    .foregroundColor(.uwSuccess)

                Spacer()

                if let timer = appStateManager.activeTimerSession {
                    Text(formatTimeRemaining(timer.timeRemaining))
                        .font(Typography.headline)
                        .foregroundColor(.uwTextPrimary)
                }
            }

            if let timer = appStateManager.activeTimerSession {
                // Progress bar - flat, Duolingo blue
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(Color.uwBorder)

                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(Color.uwPrimary)
                            .frame(width: geo.size.width * (1 - timer.timeRemaining / timer.duration))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.uwCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(Color.uwSuccess, lineWidth: 2)
        )
    }

    // MARK: - Quick Actions Section (Duolingo 3D buttons)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Actions")
                .font(Typography.title3)
                .foregroundColor(.uwTextPrimary)

            HStack(spacing: Spacing.md) {
                // Primary action - lime green 3D button
                quickActionButton(
                    icon: "timer",
                    label: "Start Focus",
                    isPrimary: true
                )

                // Secondary action
                quickActionButton(
                    icon: "chart.bar",
                    label: "View Insights",
                    isPrimary: false
                )
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .animation(DuoAnimation.cascade(index: 2), value: showContent)
    }

    @ViewBuilder
    private func quickActionButton(icon: String, label: String, isPrimary: Bool) -> some View {
        if isPrimary {
            Button(action: {
                DuoHaptics.buttonTap()
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))

                    Text(label)
                        .font(Typography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(DuoPrimaryButton())
        } else {
            Button(action: {
                DuoHaptics.buttonTap()
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))

                    Text(label)
                        .font(Typography.headline)
                }
                .foregroundColor(.uwTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.lg)
                            .fill(Color.uwCardShadow)
                            .offset(y: 4)

                        RoundedRectangle(cornerRadius: Radius.lg)
                            .fill(Color.uwCard)
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
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
