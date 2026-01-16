//
//  AccountActivityView.swift
//  ActivityMonitor
//
//  iOS 26 Liquid Glass Account Statistics View
//

import SwiftUI

// MARK: - Design Constants (shared with TotalActivityView)
private enum AccountGlassColors {
    static let background = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.15)
    static let highlight = Color.white.opacity(0.25)
    static let brand = Color(hexString: "A8E61D")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let appBackground = Color(hexString: "0A0A0A")
    static let success = Color(hexString: "58CC02")
    static let blue = Color(hexString: "0A84FF")
    static let orange = Color(hexString: "FF9500")
    static let red = Color(hexString: "FF453A")
    static let gold = Color(hexString: "FFD700")
    static let silver = Color(hexString: "C0C0C0")
    static let bronze = Color(hexString: "CD7F32")
}

struct AccountActivityView: View {
    let configuration: TotalActivityConfiguration
    @State private var animatedHeatmap: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Hourly heatmap - unique visualization for account page
            hourlyHeatmap

            // Top apps section - compact list
            topAppsSection
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .background(Color.clear)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.5)) { animatedHeatmap = true }
            }
        }
    }

    // MARK: - Metric Cards Row
    private var metricCardsRow: some View {
        HStack(spacing: 12) {
            AccountMetricCard(title: "TOTAL TIME", value: configuration.formattedTotalTime, icon: "clock.fill", color: AccountGlassColors.brand)
            AccountMetricCard(title: "APPS USED", value: "\(configuration.appUsageData.count)", icon: "square.grid.2x2.fill", color: AccountGlassColors.orange)
            if let peakHour = configuration.peakUsageHour {
                AccountMetricCard(title: "PEAK HOUR", value: formatHour(peakHour), icon: "flame.fill", color: AccountGlassColors.red)
            }
        }
    }

    // MARK: - Weekly Overview Chart
    private var weeklyOverviewChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AccountGlassColors.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(AccountGlassColors.brand).frame(width: 6, height: 6)
                    Text("Daily Avg").font(.system(size: 12, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                }
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                day == currentDayName
                                    ? LinearGradient(colors: [AccountGlassColors.brand, AccountGlassColors.brand.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: animatedHeatmap ? barHeight(for: day) : 8)
                        Text(String(day.prefix(1)))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(day == currentDayName ? AccountGlassColors.brand : AccountGlassColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)

            HStack {
                Text("Daily average:").font(.system(size: 13, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                Text(averageScreenTime).font(.system(size: 13, weight: .bold)).foregroundColor(AccountGlassColors.brand)
                Spacer()
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(AccountGlassColors.background))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(LinearGradient(colors: [AccountGlassColors.highlight, AccountGlassColors.border, Color.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
    }

    // MARK: - Hourly Heatmap
    private var hourlyHeatmap: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Heatmap").font(.system(size: 16, weight: .semibold)).foregroundColor(AccountGlassColors.textPrimary)
                Spacer()
                Text("Today").font(.system(size: 12, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(AccountGlassColors.background))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6), spacing: 4) {
                ForEach(0..<24, id: \.self) { hour in
                    let minutes = configuration.hourlyBreakdown.first(where: { $0.hour == hour })?.totalMinutes ?? 0
                    AccountHeatmapCell(hour: hour, minutes: minutes, isAnimated: animatedHeatmap)
                }
            }

            HStack(spacing: 8) {
                Text("Less").font(.system(size: 11, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                ForEach([0, 1, 2, 3, 4], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3).fill(heatmapColor(for: level * 15)).frame(width: 16, height: 16)
                }
                Text("More").font(.system(size: 11, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(AccountGlassColors.background))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(LinearGradient(colors: [AccountGlassColors.highlight, AccountGlassColors.border, Color.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
    }

    // MARK: - Top Apps Section
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Apps Today").font(.system(size: 16, weight: .semibold)).foregroundColor(AccountGlassColors.textPrimary)
                Spacer()
                Text("\(configuration.appUsageData.count) total").font(.system(size: 12, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(AccountGlassColors.background))
            }

            if configuration.appUsageData.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(configuration.appUsageData.prefix(6).enumerated()), id: \.offset) { index, app in
                        AccountAppProgressRow(app: app, rank: index + 1, maxTime: configuration.appUsageData.first?.totalTime ?? 1)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(AccountGlassColors.background))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(LinearGradient(colors: [AccountGlassColors.highlight, AccountGlassColors.border, Color.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(AccountGlassColors.brand.opacity(0.1)).frame(width: 72, height: 72)
                Image(systemName: "apps.iphone").font(.system(size: 32, weight: .medium)).foregroundColor(AccountGlassColors.brand.opacity(0.6))
            }
            VStack(spacing: 6) {
                Text("No App Data Yet").font(.system(size: 17, weight: .semibold)).foregroundColor(AccountGlassColors.textPrimary)
                Text("Start using apps to see statistics").font(.system(size: 14, weight: .medium)).foregroundColor(AccountGlassColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers
    private var weekDays: [String] { ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] }

    private var currentDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date())
    }

    private var averageScreenTime: String {
        let avgMinutes = Int(configuration.totalScreenTime / 60 / 7)
        let hours = avgMinutes / 60
        let mins = avgMinutes % 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }

    private func barHeight(for day: String) -> CGFloat {
        if day == currentDayName {
            return max(20, min(80, CGFloat(configuration.totalScreenTime / 3600) * 20))
        }
        return CGFloat.random(in: 30...70)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date).lowercased()
    }

    private func heatmapColor(for minutes: Int) -> Color {
        switch minutes {
        case 0: return Color.white.opacity(0.08)
        case 1...10: return AccountGlassColors.brand.opacity(0.25)
        case 11...30: return AccountGlassColors.brand.opacity(0.5)
        case 31...60: return AccountGlassColors.brand.opacity(0.75)
        default: return AccountGlassColors.brand
        }
    }
}

// MARK: - Account Metric Card
struct AccountMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(AccountGlassColors.textPrimary).minimumScaleFactor(0.7).lineLimit(1)
                Text(title).font(.system(size: 9, weight: .semibold)).foregroundColor(AccountGlassColors.textSecondary).textCase(.uppercase).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(AccountGlassColors.background))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

// MARK: - Account Heatmap Cell
struct AccountHeatmapCell: View {
    let hour: Int
    let minutes: Int
    let isAnimated: Bool
    @State private var isPressed = false

    private var isActive: Bool { minutes > 10 }

    private var cellColor: Color {
        guard isAnimated else { return Color.white.opacity(0.08) }
        switch minutes {
        case 0: return Color.white.opacity(0.08)
        case 1...10: return AccountGlassColors.brand.opacity(0.25)
        case 11...30: return AccountGlassColors.brand.opacity(0.5)
        case 31...60: return AccountGlassColors.brand.opacity(0.75)
        default: return AccountGlassColors.brand
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)
                .frame(height: 32)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(isActive && isAnimated ? 0.15 : 0), lineWidth: 1))
                .scaleEffect(isPressed ? 0.92 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .animation(.easeOut(duration: 0.4), value: isAnimated)

            Text(formatHour(hour)).font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.5))
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12a" }
        if hour < 12 { return "\(hour)a" }
        if hour == 12 { return "12p" }
        return "\(hour - 12)p"
    }
}

// MARK: - Account App Progress Row
struct AccountAppProgressRow: View {
    let app: AppUsageInfo
    let rank: Int
    let maxTime: TimeInterval

    private var progress: Double { maxTime > 0 ? min(app.totalTime / maxTime, 1.0) : 0 }

    private var formattedTime: String {
        let hours = Int(app.totalTime) / 3600
        let minutes = (Int(app.totalTime) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private var rankColor: Color {
        switch rank {
        case 1: return AccountGlassColors.gold
        case 2: return AccountGlassColors.silver
        case 3: return AccountGlassColors.bronze
        default: return AccountGlassColors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(rankColor.opacity(0.15)).frame(width: 32, height: 32)
                Text("\(rank)").font(.system(size: 13, weight: .bold)).foregroundColor(rankColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(app.name).font(.system(size: 15, weight: .semibold)).foregroundColor(AccountGlassColors.textPrimary).lineLimit(1)
                    Spacer()
                    Text(formattedTime).font(.system(size: 13, weight: .bold)).foregroundColor(AccountGlassColors.brand).monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [AccountGlassColors.brand, AccountGlassColors.brand.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * progress, height: 5)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Legacy Components (compatibility)
struct MetricCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View { AccountMetricCard(title: title, value: value, icon: icon, color: color) }
}

struct HeatmapCell: View {
    let hour: Int; let minutes: Int
    var body: some View { AccountHeatmapCell(hour: hour, minutes: minutes, isAnimated: true) }
}

struct AppProgressRow: View {
    let app: AppUsageInfo; let rank: Int; let maxTime: TimeInterval
    var body: some View { AccountAppProgressRow(app: app, rank: rank, maxTime: maxTime) }
}
