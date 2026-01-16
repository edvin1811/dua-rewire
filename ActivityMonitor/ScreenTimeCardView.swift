//
//  ScreenTimeCardView.swift
//  ActivityMonitor
//
//  A single compact card showing total screen time
//  Context: "ScreenTimeCard"
//

import SwiftUI

struct ScreenTimeCardView: View {
    let configuration: TotalActivityConfiguration

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(GlassDesign.brand.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: "iphone")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(GlassDesign.brand)
            }

            // Time display
            VStack(alignment: .leading, spacing: 4) {
                Text("Screen Time")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(configuration.formattedTotalTime)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(GlassDesign.textPrimary)
            }

            Spacer()

            // Trend indicator
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(GlassDesign.success)

                Text("12%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GlassDesign.success)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(GlassDesign.success.opacity(0.15)))
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Configuration for ScreenTimeCard
struct ScreenTimeCardConfiguration {
    let totalScreenTime: TimeInterval

    var formattedTotalTime: String {
        TimeFormatter.format(totalScreenTime)
    }

    static var empty: ScreenTimeCardConfiguration {
        ScreenTimeCardConfiguration(totalScreenTime: 0)
    }
}
