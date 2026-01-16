//
//  HomeScreenReportView.swift
//  ActivityMonitor
//
//  Comprehensive home screen report matching Jolt style
//  Uses ApplicationToken with Label for proper app names and icons
//  Context: "HomeScreen"
//

import SwiftUI
import ManagedSettings

// MARK: - Time Frame Selection
enum TimeFrameSelection: String, CaseIterable {
    case today = "Today"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct HomeScreenReportView: View {
    // Support both old and new configuration types
    let activityConfig: ActivityConfiguration?
    let legacyConfig: TotalActivityConfiguration?

    @State private var selectedTimeFrame: TimeFrameSelection = .today
    @State private var animatedBars: [Bool] = Array(repeating: false, count: 24)

    // Initialize with new ActivityConfiguration (has app tokens)
    init(activityConfig: ActivityConfiguration) {
        self.activityConfig = activityConfig
        self.legacyConfig = nil
    }

    // Initialize with legacy TotalActivityConfiguration (no tokens)
    init(configuration: TotalActivityConfiguration) {
        self.activityConfig = nil
        self.legacyConfig = configuration
    }

    // Read goal from App Group
    private var dailyGoal: TimeInterval {
        AppGroupConfig.dailyGoal
    }

    private var totalScreenTime: TimeInterval {
        activityConfig?.totalScreenTime ?? legacyConfig?.totalScreenTime ?? 0
    }

    private var hourlyBreakdown: [HourlyUsageData] {
        activityConfig?.hourlyBreakdown ?? legacyConfig?.hourlyBreakdown ?? []
    }

    private var focusScore: Int {
        guard dailyGoal > 0 else { return 100 }
        let usagePercent = totalScreenTime / dailyGoal
        return max(0, min(100, 100 - Int(usagePercent * 100)))
    }

    private var formattedTotalTime: String {
        activityConfig?.formattedTotalTime ?? legacyConfig?.formattedTotalTime ?? "0m"
    }

    var body: some View {
        glassContent
            .onAppear {
                animateChartBars()
            }
    }

    @ViewBuilder
    private var glassContent: some View {
        // No GlassEffectContainer - each element handles its own glass effect independently
        // This prevents conflicts between multiple glass effects
        VStack(spacing: 16) {
            // Time frame selector row
            timeFrameSelector

            // Screen time report card (Jolt-style)
            screenTimeReportCard
        }
    }

    // MARK: - Time Frame Selector (Today, Weekly, Monthly) - iOS 26 Liquid Glass
    private var timeFrameSelector: some View {
        HStack(spacing: 8) {
            // Time frame pills
            ForEach(TimeFrameSelection.allCases, id: \.self) { frame in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeFrame = frame
                    }
                } label: {
                    HStack(spacing: 4) {
                        if frame == .today {
                            Image(systemName: "clock")
                                .font(.system(size: 12, weight: .medium))
                        }
                        Text(frame.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selectedTimeFrame == frame ? .black : GlassDesign.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedTimeFrame == frame ? GlassDesign.brand : Color.clear)
                    )
                    .modifier(ConditionalGlassEffect(
                        isActive: selectedTimeFrame == frame,
                        shape: Capsule()
                    ))
                }
            }

            Spacer()

            // Focus Score pill - iOS 26 glass with tint
            Text("\(focusScore)%")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(GlassDesign.brand)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .modifier(ConditionalGlassEffect(
                    isActive: true,
                    shape: Capsule(),
                    tintColor: GlassDesign.brand.opacity(0.3)
                ))
        }
    }

    // MARK: - Screen Time Report Card (Jolt Style)
    @ViewBuilder
    private var screenTimeReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My screen time report")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(GlassDesign.textPrimary)

            HStack(spacing: 0) {
                // Left side - Chart and time
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Screentime")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(GlassDesign.textSecondary)

                        Text(formattedTotalTime)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(GlassDesign.brand)
                    }

                    // Activity bar chart
                    activityBarChart
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider - use semi-transparent for glass
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 80)
                    .padding(.horizontal, 12)

                // Right side - Goal
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("My goal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(GlassDesign.textSecondary)

                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(GlassDesign.textSecondary)
                    }

                    // Goal time display
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text(formatGoalHours())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(GlassDesign.brand)

                        Text(formatGoalMinutes())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(GlassDesign.orange)
                    }

                    // Detailed report link
                    HStack(spacing: 4) {
                        Text("Detailed report")
                            .font(.system(size: 12, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(GlassDesign.textSecondary)
                }
            }
        }
        .padding(16)
        .modifier(GlassEffect(shape: RoundedRectangle(cornerRadius: 24)))
    }

    // MARK: - Activity Bar Chart
    private var activityBarChart: some View {
        VStack(spacing: 4) {
            // Bars only (simplified)
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    let minutes = hourlyBreakdown.first(where: { $0.hour == hour })?.totalMinutes ?? 0
                    let maxMinutes = max(hourlyBreakdown.map { $0.totalMinutes }.max() ?? 60, 60)
                    let height = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(maxMinutes) * 45 : 0

                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: minutes))
                        .frame(width: 4, height: animatedBars[hour] ? max(height, 2) : 2)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(hour) * 0.02),
                            value: animatedBars[hour]
                        )
                }
            }
            .frame(height: 45)

            // X-axis labels
            HStack {
                Text("12am")
                Spacer()
                Text("6am")
                Spacer()
                Text("12pm")
                Spacer()
                Text("6pm")
            }
            .font(.system(size: 8, weight: .medium))
            .foregroundColor(GlassDesign.textTertiary)
        }
    }

    // MARK: - Helpers
    private func barColor(for minutes: Int) -> Color {
        switch minutes {
        case 0: return Color.white.opacity(0.1)
        case 1...10: return GlassDesign.brand.opacity(0.4)
        case 11...25: return GlassDesign.brand.opacity(0.6)
        case 26...40: return GlassDesign.brand.opacity(0.8)
        default: return GlassDesign.brand
        }
    }

    private func formatGoalHours() -> String {
        let hours = Int(dailyGoal) / 3600
        return "\(hours)h"
    }

    private func formatGoalMinutes() -> String {
        let minutes = (Int(dailyGoal) % 3600) / 60
        return " \(minutes)m"
    }

    private func animateChartBars() {
        for i in 0..<24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                animatedBars[i] = true
            }
        }
    }
}

