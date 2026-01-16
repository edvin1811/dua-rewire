import SwiftUI

// MARK: - Color Extension for ActivityMonitor
extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Design Constants
private enum GlassColors {
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
    static let gold = Color(hexString: "FFD700")
    static let silver = Color(hexString: "C0C0C0")
    static let bronze = Color(hexString: "CD7F32")
}

// MARK: - iOS 26 Liquid Glass Total Activity View
struct TotalActivityView: View {
    let configuration: TotalActivityConfiguration
    @State private var isViewReady = false
    @State private var animatedBars: [Bool] = Array(repeating: false, count: 24)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Screen time header with focus score
            screenTimeHeader

            // Hourly activity chart
            hourlyActivityChart

            // Most used apps
            topAppsSection
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .background(Color.clear)
        .opacity(isViewReady ? 1.0 : 0.0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isViewReady = true
                animateChartBars()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isViewReady)
    }

    // MARK: - Screen Time Header
    private var screenTimeHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Screen Time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GlassColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1)

                Text(configuration.formattedTotalTime)
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(GlassColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(GlassColors.success)

                    Text("vs yesterday")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(GlassColors.textSecondary)
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(GlassColors.background, lineWidth: 6)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: focusScoreProgress)
                    .stroke(
                        LinearGradient(
                            colors: [GlassColors.brand, GlassColors.brand.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(focusScore)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(GlassColors.textPrimary)
                    Text("%")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(GlassColors.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(GlassColors.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(
                        colors: [GlassColors.highlight, GlassColors.border, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Hourly Activity Chart
    private var hourlyActivityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity Timeline")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassColors.textPrimary)

                Spacer()

                Text("Today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(GlassColors.background))
            }

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { hour in
                    let minutes = configuration.hourlyBreakdown.first(where: { $0.hour == hour })?.totalMinutes ?? 0
                    let maxMinutes = configuration.hourlyBreakdown.map { $0.totalMinutes }.max() ?? 60
                    let height = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(max(maxMinutes, 1)) * 80 : 0

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: minutes))
                        .frame(width: 8, height: animatedBars[hour] ? max(height, 4) : 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(hour) * 0.02), value: animatedBars[hour])
                }
            }
            .frame(height: 80)
            .padding(.vertical, 8)

            HStack {
                Text("12am").font(.system(size: 10, weight: .medium)).foregroundColor(GlassColors.textSecondary)
                Spacer()
                Text("6am").font(.system(size: 10, weight: .medium)).foregroundColor(GlassColors.textSecondary)
                Spacer()
                Text("12pm").font(.system(size: 10, weight: .medium)).foregroundColor(GlassColors.textSecondary)
                Spacer()
                Text("6pm").font(.system(size: 10, weight: .medium)).foregroundColor(GlassColors.textSecondary)
                Spacer()
                Text("Now").font(.system(size: 10, weight: .semibold)).foregroundColor(GlassColors.brand)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(GlassColors.background))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(colors: [GlassColors.highlight, GlassColors.border, Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Statistics Row
    private var statisticsRow: some View {
        HStack(spacing: 12) {
            GlassStatPill(icon: "apps.iphone", value: "\(configuration.appUsageData.count)", label: "Apps", color: GlassColors.brand)
            GlassStatPill(icon: "clock.fill", value: "\(configuration.activeHours)", label: "Active Hrs", color: GlassColors.blue)
            if let peakHour = configuration.peakUsageHour {
                GlassStatPill(icon: "flame.fill", value: formatHour(peakHour), label: "Peak", color: GlassColors.orange)
            }
        }
    }

    // MARK: - Top Apps Section
    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Most Used")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassColors.textPrimary)
                Spacer()
                Text("\(configuration.appUsageData.count) apps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassColors.textSecondary)
            }

            if configuration.appUsageData.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(configuration.appUsageData.prefix(5).enumerated()), id: \.offset) { index, app in
                        GlassAppRow(app: app, rank: index + 1, maxTime: configuration.appUsageData.first?.totalTime ?? 1)
                    }
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24).fill(GlassColors.background))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    LinearGradient(colors: [GlassColors.highlight, GlassColors.border, Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(GlassColors.brand.opacity(0.1)).frame(width: 64, height: 64)
                Image(systemName: "apps.iphone").font(.system(size: 28, weight: .medium)).foregroundColor(GlassColors.brand.opacity(0.6))
            }
            VStack(spacing: 4) {
                Text("No Activity Yet").font(.system(size: 16, weight: .semibold)).foregroundColor(GlassColors.textPrimary)
                Text("Start using apps to see your usage").font(.system(size: 14, weight: .medium)).foregroundColor(GlassColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helpers
    private var focusScore: Int {
        let maxIdealTime: TimeInterval = 4 * 3600
        let score = max(0, min(100, Int((1 - configuration.totalScreenTime / maxIdealTime) * 100)))
        return max(score, 10)
    }

    private var focusScoreProgress: Double { Double(focusScore) / 100.0 }

    private func barColor(for minutes: Int) -> Color {
        switch minutes {
        case 0: return Color.white.opacity(0.1)
        case 1...15: return GlassColors.brand.opacity(0.4)
        case 16...30: return GlassColors.brand.opacity(0.6)
        case 31...45: return GlassColors.brand.opacity(0.8)
        default: return GlassColors.brand
        }
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
    }

    private func animateChartBars() {
        for i in 0..<24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) { animatedBars[i] = true }
        }
    }
}

// MARK: - Glass Stat Pill
struct GlassStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(color)
            }
            VStack(spacing: 2) {
                Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(GlassColors.textPrimary)
                Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(GlassColors.textSecondary).textCase(.uppercase).tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 20).fill(GlassColors.background))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(GlassColors.border, lineWidth: 1))
    }
}

// MARK: - Glass App Row
struct GlassAppRow: View {
    let app: AppUsageInfo
    let rank: Int
    let maxTime: TimeInterval

    private var progress: Double { maxTime > 0 ? min(app.totalTime / maxTime, 1.0) : 0 }

    private var rankColor: Color {
        switch rank {
        case 1: return GlassColors.gold
        case 2: return GlassColors.silver
        case 3: return GlassColors.bronze
        default: return GlassColors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(rankColor.opacity(0.15)).frame(width: 36, height: 36)
                Text("\(rank)").font(.system(size: 14, weight: .bold)).foregroundColor(rankColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(app.name).font(.system(size: 15, weight: .semibold)).foregroundColor(GlassColors.textPrimary).lineLimit(1)
                    Spacer()
                    Text(app.formattedTime).font(.system(size: 14, weight: .bold)).foregroundColor(GlassColors.brand).monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [GlassColors.brand, GlassColors.brand.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// Legacy compatibility
struct StatPill: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View { GlassStatPill(icon: icon, value: value, label: label, color: color) }
}

struct AppRow: View {
    let app: AppUsageInfo; let rank: Int
    var body: some View { GlassAppRow(app: app, rank: rank, maxTime: app.totalTime) }
}

struct StatColumn: View {
    let title: String; let value: String
    var body: some View {
        VStack(spacing: 8) {
            Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.6)).textCase(.uppercase).tracking(0.5)
        }
    }
}

struct ExtensionAppRow: View {
    let app: AppUsageInfo; let rank: Int
    var body: some View { GlassAppRow(app: app, rank: rank, maxTime: app.totalTime) }
}

struct ExtensionStatColumn: View {
    let title: String; let value: String
    var body: some View { StatColumn(title: title, value: value) }
}
