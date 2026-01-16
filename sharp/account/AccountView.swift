//
//  AccountView.swift
//  sharp
//
//  Duolingo-Style Account Screen with Theme Toggle
//

import SwiftUI
import DeviceActivity

struct AccountView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @StateObject private var statisticsManager = StatisticsManager.shared
    @StateObject private var themeManager = ThemeManager()

    @State private var showingFeatureRequest = false
    @State private var showingBugReport = false
    @State private var showingProfileEditor = false
    @State private var headerAppeared = false
    @State private var cardsAppeared = false

    var body: some View {
        ZStack {
            ModernBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                        .padding(.top, 16)

                    // Theme Toggle Section
                    themeToggleSection

                    // Feature Request Card
                    featureRequestCard

                    // Goals Section (side by side cards)
                    goalsSection

                    // Weekly/Monthly Stats
                    weeklyMonthlyStats

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(themeManager.colorScheme)
        .sheet(isPresented: $showingFeatureRequest) {
            FeatureRequestSheet()
        }
        .sheet(isPresented: $showingBugReport) {
            BugReportSheet()
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorSheet()
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                headerAppeared = true
            }
            withAnimation(DuoAnimation.cardBounce.delay(0.2)) {
                cardsAppeared = true
            }
        }
    }

    // MARK: - Profile Header (3D Style)
    @ViewBuilder
    private var profileHeader: some View {
        HStack(spacing: 16) {
            // 3D Avatar
            ZStack {
                // Shadow layer
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 74, height: 74)
                    .offset(y: 3)

                // Main circle
                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 74, height: 74)

                // Inner circle with initials
                Circle()
                    .fill(Color.uwCard)
                    .frame(width: 64, height: 64)

                Text(getInitials())
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.uwPrimary)
            }
            .scaleEffect(headerAppeared ? 1 : 0.5)
            .opacity(headerAppeared ? 1 : 0)

            // User Info
            VStack(alignment: .leading, spacing: 6) {
                Text(getUserName())
                    .font(.duoHeadline)
                    .foregroundColor(.uwTextPrimary)

                Text("Member since \(getMemberSince())")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }
            .offset(x: headerAppeared ? 0 : -20)
            .opacity(headerAppeared ? 1 : 0)

            Spacer()

            // 3D Edit button
            Button {
                showingProfileEditor = true
                DuoHaptics.lightTap()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.uwTextTertiary.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .offset(y: 2)

                    Circle()
                        .fill(Color.uwCard)
                        .frame(width: 44, height: 44)

                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.uwTextSecondary)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(headerAppeared ? 1 : 0.5)
            .opacity(headerAppeared ? 1 : 0)
        }
    }

    // MARK: - Theme Toggle Section
    @ViewBuilder
    private var themeToggleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.uwAccent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.uwAccent)
                }

                Text("Appearance")
                    .font(.duoSubheadline)
                    .foregroundColor(.uwTextPrimary)

                Spacer()
            }

            // Theme toggle buttons with 3D effect
            HStack(spacing: 10) {
                themeButton(
                    title: "Light",
                    icon: "sun.max.fill",
                    isSelected: themeManager.selectedTheme == .light,
                    action: { themeManager.selectedTheme = .light }
                )

                themeButton(
                    title: "Dark",
                    icon: "moon.fill",
                    isSelected: themeManager.selectedTheme == .dark,
                    action: { themeManager.selectedTheme = .dark }
                )

                themeButton(
                    title: "Auto",
                    icon: "circle.lefthalf.filled",
                    isSelected: themeManager.selectedTheme == .system,
                    action: { themeManager.selectedTheme = .system }
                )
            }
        }
        .duoCard()
        .offset(y: cardsAppeared ? 0 : 20)
        .opacity(cardsAppeared ? 1 : 0)
    }

    private func themeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(DuoAnimation.tabSwitch) {
                action()
            }
            DuoHaptics.selection()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        // 3D shadow for selected
                        Circle()
                            .fill(Color.uwPrimaryDark)
                            .frame(width: 48, height: 48)
                            .offset(y: 3)

                        Circle()
                            .fill(Color.uwPrimary)
                            .frame(width: 48, height: 48)
                    } else {
                        Circle()
                            .fill(Color.uwSurface)
                            .frame(width: 48, height: 48)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .white : .uwTextSecondary)
                }

                Text(title)
                    .font(.duoCaption)
                    .foregroundColor(isSelected ? .uwPrimary : .uwTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Goals Section (3D Cards Side by Side)
    @ViewBuilder
    private var goalsSection: some View {
        HStack(spacing: 12) {
            // My Goal Card
            VStack(alignment: .leading, spacing: 12) {
                // 3D icon
                ZStack {
                    Circle()
                        .fill(Color.uwAccentDark)
                        .frame(width: 40, height: 40)
                        .offset(y: 2)

                    Circle()
                        .fill(Color.uwAccent)
                        .frame(width: 40, height: 40)

                    Text("🎯")
                        .font(.system(size: 18))
                }

                Text("My Goal")
                    .font(.duoBodyBold)
                    .foregroundColor(.uwTextPrimary)

                // 3D Progress bar
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.uwTextTertiary.opacity(0.3))
                        .frame(height: 10)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.uwAccentDark)
                                .frame(width: geometry.size.width * min(1.0 - statisticsManager.todayGoalProgress, 1.0), height: 10)
                                .offset(y: 2)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.uwAccent)
                                .frame(width: geometry.size.width * min(1.0 - statisticsManager.todayGoalProgress, 1.0), height: 8)
                        }
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("Used: \(statisticsManager.formatTimeShort(statisticsManager.todayScreenTime))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.uwTextSecondary)
                    Spacer()
                    Text(formatGoalTime(statisticsManager.dailyGoal))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.uwAccent)
                }

                // Edit goal button
                Button {
                    DuoHaptics.lightTap()
                } label: {
                    Text("Edit goal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.uwTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(Color.uwTextTertiary.opacity(0.3))
                                    .offset(y: 2)

                                Capsule()
                                    .fill(Color.uwSurface)
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            .duo3DCard(padding: 16, cornerRadius: 20, shadowOffset: 4)

            // Facing an Issue Card
            VStack(alignment: .leading, spacing: 12) {
                // 3D warning icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "CC7700"))
                        .frame(width: 40, height: 40)
                        .offset(y: 2)

                    Circle()
                        .fill(Color.uwWarning)
                        .frame(width: 40, height: 40)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Facing an issue?")
                    .font(.duoBodyBold)
                    .foregroundColor(.uwTextPrimary)

                Text("Report now")
                    .font(.duoSmall)
                    .foregroundColor(.uwTextSecondary)

                Spacer()

                // Report button
                Button {
                    showingBugReport = true
                    DuoHaptics.lightTap()
                } label: {
                    Text("Report")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                Capsule()
                                    .fill(Color(hex: "CC7700"))
                                    .offset(y: 2)

                                Capsule()
                                    .fill(Color.uwWarning)
                            }
                        )
                }
                .buttonStyle(.plain)
            }
            .duo3DCard(padding: 16, cornerRadius: 20, shadowOffset: 4)
        }
        .offset(y: cardsAppeared ? 0 : 20)
        .opacity(cardsAppeared ? 1 : 0)
    }

    // MARK: - Weekly/Monthly Stats
    private var weeklyMonthlyStats: some View {
        DeviceActivityReport(
            DeviceActivityReport.Context(rawValue: "AccountStats"),
            filter: getCurrentFilter()
        )
        .frame(minHeight: 280)
        .duoCard()
        .offset(y: cardsAppeared ? 0 : 20)
        .opacity(cardsAppeared ? 1 : 0)
    }

    // MARK: - Feature Request Card (3D Style)
    @ViewBuilder
    private var featureRequestCard: some View {
        Button {
            showingFeatureRequest = true
            DuoHaptics.buttonTap()
        } label: {
            HStack(spacing: 16) {
                // 3D lightbulb icon
                ZStack {
                    Circle()
                        .fill(Color.uwPrimaryDark)
                        .frame(width: 52, height: 52)
                        .offset(y: 3)

                    Circle()
                        .fill(Color.uwPrimary)
                        .frame(width: 52, height: 52)

                    Text("💡")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Have an idea?")
                        .font(.duoBodyBold)
                        .foregroundColor(.uwTextPrimary)

                    Text("Request a feature")
                        .font(.duoSmall)
                        .foregroundColor(.uwTextSecondary)
                }

                Spacer()

                // 3D Request button
                ZStack {
                    Capsule()
                        .fill(Color.uwPrimaryDark)
                        .offset(y: 3)

                    Capsule()
                        .fill(Color.uwPrimary)

                    Text("Request")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 90, height: 36)
            }
            .padding(16)
        }
        .buttonStyle(DuoCardButtonStyle())
        .offset(y: cardsAppeared ? 0 : 20)
        .opacity(cardsAppeared ? 1 : 0)
    }

    // MARK: - Helper to get current filter
    private func getCurrentFilter() -> DeviceActivityFilter {
        guard let todayInterval = Calendar.current.dateInterval(of: .day, for: .now) else {
            fatalError("Could not create today interval")
        }

        return DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    // MARK: - Helper Functions
    private func getUserName() -> String {
        UserDefaults.standard.string(forKey: "userName") ?? "User"
    }

    private func getInitials() -> String {
        let name = getUserName()
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if !name.isEmpty {
            return String(name.prefix(2))
        }
        return "U"
    }

    private func getMemberSince() -> String {
        guard let firstLaunch = statisticsManager.firstLaunchDate else {
            return "Dec 2025"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: firstLaunch)
    }

    private func formatGoalTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if minutes == 0 {
            return "\(hours)h"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
}

// MARK: - Profile Editor Sheet (Duo Style)
struct ProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userName: String = ""
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                VStack(spacing: 24) {
                    // 3D Avatar
                    ZStack {
                        Circle()
                            .fill(Color.uwPrimaryDark)
                            .frame(width: 94, height: 94)
                            .offset(y: 4)

                        Circle()
                            .fill(Color.uwPrimary)
                            .frame(width: 94, height: 94)

                        Circle()
                            .fill(Color.uwCard)
                            .frame(width: 80, height: 80)

                        Text(getInitials())
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.uwPrimary)
                    }
                    .padding(.top, 30)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                    Text("Edit Profile")
                        .font(.duoHeadline)
                        .foregroundColor(.uwTextPrimary)
                        .offset(y: appeared ? 0 : 10)
                        .opacity(appeared ? 1 : 0)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.duoCaption)
                            .foregroundColor(.uwTextSecondary)

                        TextField("Enter your name", text: $userName)
                            .font(.duoBody)
                            .foregroundColor(.uwTextPrimary)
                            .padding(16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.uwCardShadow)
                                        .offset(y: 3)
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.uwCard)
                                }
                            )
                    }
                    .padding(.horizontal, 24)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    Button {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        dismiss()
                        DuoHaptics.success()
                    } label: {
                        Text("Save Changes")
                    }
                    .buttonStyle(DuoPrimaryButton())
                    .padding(.horizontal, 24)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.uwTextTertiary)
                }
            )
        }
        .onAppear {
            userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    private func getInitials() -> String {
        let name = userName.isEmpty ? "U" : userName
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else if !name.isEmpty {
            return String(name.prefix(2))
        }
        return "U"
    }
}

// MARK: - Feature Request Sheet (Duo Style)
struct FeatureRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var featureText: String = ""
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                VStack(spacing: 24) {
                    // 3D icon
                    ZStack {
                        Circle()
                            .fill(Color.uwPrimaryDark)
                            .frame(width: 84, height: 84)
                            .offset(y: 4)

                        Circle()
                            .fill(Color.uwPrimary)
                            .frame(width: 84, height: 84)

                        Text("💡")
                            .font(.system(size: 40))
                    }
                    .padding(.top, 30)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("Suggest a Feature")
                            .font(.duoHeadline)
                            .foregroundColor(.uwTextPrimary)

                        Text("We'd love to hear your ideas!")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)
                    }
                    .offset(y: appeared ? 0 : 10)
                    .opacity(appeared ? 1 : 0)

                    TextEditor(text: $featureText)
                        .font(.duoBody)
                        .foregroundColor(.uwTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(height: 160)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.uwCardShadow)
                                    .offset(y: 3)
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.uwCard)
                            }
                        )
                        .padding(.horizontal, 24)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    Button {
                        print("Feature request: \(featureText)")
                        dismiss()
                        DuoHaptics.success()
                    } label: {
                        Text("Submit")
                    }
                    .buttonStyle(DuoPrimaryButton())
                    .padding(.horizontal, 24)
                    .disabled(featureText.isEmpty)
                    .opacity(featureText.isEmpty ? 0.5 : 1.0)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.uwTextTertiary)
                }
            )
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Bug Report Sheet (Duo Style)
struct BugReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bugDescription: String = ""
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                VStack(spacing: 24) {
                    // 3D icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: "CC3333"))
                            .frame(width: 84, height: 84)
                            .offset(y: 4)

                        Circle()
                            .fill(Color.uwError)
                            .frame(width: 84, height: 84)

                        Image(systemName: "ant.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 30)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 8) {
                        Text("Report a Bug")
                            .font(.duoHeadline)
                            .foregroundColor(.uwTextPrimary)

                        Text("Help us fix what's broken")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)
                    }
                    .offset(y: appeared ? 0 : 10)
                    .opacity(appeared ? 1 : 0)

                    TextEditor(text: $bugDescription)
                        .font(.duoBody)
                        .foregroundColor(.uwTextPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(height: 160)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.uwCardShadow)
                                    .offset(y: 3)
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.uwCard)
                            }
                        )
                        .padding(.horizontal, 24)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)

                    Button {
                        print("Bug report: \(bugDescription)")
                        dismiss()
                        DuoHaptics.success()
                    } label: {
                        Text("Submit")
                    }
                    .buttonStyle(DuoDangerButton())
                    .padding(.horizontal, 24)
                    .disabled(bugDescription.isEmpty)
                    .opacity(bugDescription.isEmpty ? 0.5 : 1.0)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)

                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.uwTextTertiary)
                }
            )
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                appeared = true
            }
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppStateManager())
}
