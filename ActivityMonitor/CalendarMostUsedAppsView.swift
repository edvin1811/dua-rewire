//
//  CalendarMostUsedAppsView.swift
//  ActivityMonitor
//
//  Most used apps component for CalendarView with real app data
//  Uses ApplicationToken with Label for proper app names and icons
//  Context: "CalendarMostUsedApps"
//

import SwiftUI
import ManagedSettings

// MARK: - Calendar Most Used Apps View (Uses ApplicationToken for real icons)
struct CalendarMostUsedAppsView: View {
    let configuration: ActivityConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Most used apps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(GlassDesign.textPrimary)

            if configuration.appActivities.isEmpty {
                emptyStateView
            } else {
                // Apps list
                VStack(spacing: 0) {
                    // Show top 6 apps with real icons
                    ForEach(Array(configuration.appActivities.prefix(6).enumerated()), id: \.element.id) { index, app in
                        AppRowWithRealIcon(
                            rank: index + 1,
                            app: app,
                            maxTime: configuration.appActivities.first?.totalTime ?? 1
                        )

                        if index < min(configuration.appActivities.count - 1, 5) {
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .padding(.leading, 56)
                        }
                    }

                    // "Other" row if there are more than 6 apps
                    if configuration.appActivities.count > 6 {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.leading, 56)

                        OtherAppsRow(
                            remainingApps: Array(configuration.appActivities.dropFirst(6)),
                            rank: 7
                        )
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(GlassDesign.textTertiary)

            Text("No app usage data")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(GlassDesign.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - App Row with Real Icon using ApplicationToken Label
struct AppRowWithRealIcon: View {
    let rank: Int
    let app: AppActivityData
    let maxTime: TimeInterval

    private var progress: Double {
        maxTime > 0 ? min(app.totalTime / maxTime, 1.0) : 0
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(GlassDesign.textSecondary)
                .frame(width: 20)

            // App icon using Label with ApplicationToken - shows real app icon
            Label(app.token)
                .labelStyle(AppIconLabelStyle())
                .frame(width: 40, height: 40)

            // App name using Label with ApplicationToken - shows real app name
            Label(app.token)
                .labelStyle(AppNameLabelStyle())

            Spacer()

            // Usage time
            Text(app.formattedTime)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(GlassDesign.brand)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Custom Label Styles for ApplicationToken

// Shows only the app icon
struct AppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .font(.system(size: 28))
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Shows only the app name - force white color
struct AppNameLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.title
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Color.white) // Force white text
            .lineLimit(1)
    }
}

// MARK: - Other Apps Row (for apps beyond top 6)
struct OtherAppsRow: View {
    let remainingApps: [AppActivityData]
    let rank: Int

    private var totalOtherTime: TimeInterval {
        remainingApps.reduce(0) { $0 + $1.totalTime }
    }

    private var formattedOtherTime: String {
        let hours = Int(totalOtherTime) / 3600
        let minutes = Int(totalOtherTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(GlassDesign.textSecondary)
                .frame(width: 20)

            // Overlapping app icons (up to 3)
            ZStack {
                ForEach(Array(remainingApps.prefix(3).enumerated().reversed()), id: \.element.id) { index, app in
                    Label(app.token)
                        .labelStyle(SmallAppIconLabelStyle())
                        .offset(x: CGFloat(index - 1) * 14)
                }
            }
            .frame(width: 50, height: 40)

            // "Other" label
            Text("Other")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(GlassDesign.textPrimary)

            Spacer()

            // Combined time
            Text(formattedOtherTime)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(GlassDesign.textSecondary)
        }
        .padding(.vertical, 12)
    }
}

// Small icon style for overlapping icons
struct SmallAppIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.icon
            .font(.system(size: 14))
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.black.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
