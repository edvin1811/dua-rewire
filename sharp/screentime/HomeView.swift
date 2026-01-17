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

    // MARK: - Header Section (Duolingo-style vibrant header)
    private var headerSection: some View {
        ZStack {
            // Vibrant gradient background - Duolingo blue to green
            LinearGradient(
                colors: [Color.uwPrimary, Color(hex: "1A9E6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative elements - bolder, more visible
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 70, y: -50)
                    .floating(distance: 5, duration: 3.0)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .offset(x: -40, y: geo.size.height - 40)
                    .floating(distance: 4, duration: 2.5)

                Circle()
                    .fill(Color.uwAccent.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .offset(x: geo.size.width * 0.6, y: geo.size.height * 0.7)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Text("Stay focused today")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                // Streak badge - vibrant fire orange
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.streakOrange)

                    Text("\(currentStreak) day streak")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.25))
                )
                .padding(.top, 10)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .padding(.top, 8)
        }
        .frame(height: 190)
    }

    // MARK: - Today's Progress Card (Duolingo-style)
    private var todayProgressCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Text(formatDate(Date()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.uwTextSecondary)
            }

            HStack(spacing: 24) {
                // Goal Ring - vibrant lime green
                ZStack {
                    Circle()
                        .stroke(Color.uwSuccess.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: showContent ? goalProgress : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.uwSuccess, Color.uwSuccessLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(DuoAnimation.progressUpdate.delay(0.3), value: showContent)

                    VStack(spacing: 2) {
                        Text("\(Int(goalProgress * 100))%")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.uwSuccess)

                        Text("of goal")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.uwTextSecondary)
                    }
                }
                .frame(width: 110, height: 110)

                // Stats - more vibrant
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
            ZStack {
                // 3D shadow effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.uwCardShadow)
                    .offset(y: 4)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.uwCard)
            }
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

    // MARK: - Quick Stats Section (Duolingo-style cards)
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
        VStack(spacing: 10) {
            // Icon with colored background circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.uwTextPrimary)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.uwTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            ZStack {
                // 3D shadow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.uwCardShadow)
                    .offset(y: 3)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.uwCard)
            }
        )
    }

    // MARK: - Active Session Card (Duolingo-style pulsing)
    private var activeSessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Pulsing indicator
                Circle()
                    .fill(Color.uwSuccess)
                    .frame(width: 10, height: 10)
                    .pulsing(color: .uwSuccess)

                Text("Active Session")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(.uwSuccess)

                Spacer()

                if let timer = appStateManager.activeTimerSession {
                    Text(formatTimeRemaining(timer.timeRemaining))
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.uwTextPrimary)
                }
            }

            if let timer = appStateManager.activeTimerSession {
                // Progress bar - lime green
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.uwCardShadow)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.uwSuccess, Color.uwSuccessLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (1 - timer.timeRemaining / timer.duration))
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.uwSuccessDark.opacity(0.15))
                    .offset(y: 3)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.uwSuccess.opacity(0.12))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.uwSuccess.opacity(0.4), lineWidth: 2)
        )
    }

    // MARK: - Quick Actions Section (Duolingo 3D buttons)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.uwTextPrimary)

            HStack(spacing: 12) {
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
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))

                    Text(label)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(DuoPrimaryButton())
        } else {
            Button(action: {
                DuoHaptics.buttonTap()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))

                    Text(label)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.uwTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.uwCardShadow)
                            .offset(y: 4)

                        RoundedRectangle(cornerRadius: 16)
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
