//
//  GoalProgressView.swift
//  ActivityMonitor
//
//  Shows goal vs actual screen time comparison
//  Reads daily goal from App Group shared UserDefaults
//  Context: "GoalProgress"
//

import SwiftUI

struct GoalProgressView: View {
    let configuration: TotalActivityConfiguration

    // Goal is read from App Group UserDefaults (set by main app)
    private var dailyGoal: TimeInterval {
        AppGroupConfig.dailyGoal
    }

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(configuration.totalScreenTime / dailyGoal, 1.5) // Cap at 150%
    }

    private var progressColor: Color {
        let ratio = configuration.totalScreenTime / dailyGoal
        if ratio < 0.7 { return GlassDesign.success }
        if ratio < 1.0 { return GlassDesign.orange }
        return GlassDesign.red
    }

    private var statusText: String {
        let remaining = dailyGoal - configuration.totalScreenTime
        if remaining > 0 {
            return "\(TimeFormatter.format(remaining)) left"
        } else {
            return "\(TimeFormatter.format(-remaining)) over"
        }
    }

    private var statusIcon: String {
        let ratio = configuration.totalScreenTime / dailyGoal
        if ratio < 0.7 { return "checkmark.circle.fill" }
        if ratio < 1.0 { return "exclamationmark.circle.fill" }
        return "xmark.circle.fill"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Daily Goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassDesign.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(progressColor)

                    Text(statusText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(progressColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(progressColor.opacity(0.15)))
            }

            // Progress ring and stats
            HStack(spacing: 24) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: min(progress, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(Int(min(progress, 1.5) * 100))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(GlassDesign.textPrimary)

                        Text("%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(GlassDesign.textSecondary)
                    }
                }

                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("USED")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GlassDesign.textSecondary)
                            .tracking(0.5)

                        Text(configuration.formattedTotalTime)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(GlassDesign.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("GOAL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(GlassDesign.textSecondary)
                            .tracking(0.5)

                        Text(TimeFormatter.format(dailyGoal))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(GlassDesign.brand)
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .glassCard()
    }
}
