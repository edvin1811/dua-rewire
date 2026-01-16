//
//  TopAppsListView.swift
//  ActivityMonitor
//
//  A compact list of most used apps
//  Context: "TopAppsList"
//

import SwiftUI

struct TopAppsListView: View {
    let configuration: TotalActivityConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Most Used")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassDesign.textPrimary)

                Spacer()

                Text("\(configuration.appUsageData.count) apps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
            }

            if configuration.appUsageData.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(configuration.appUsageData.prefix(5).enumerated()), id: \.offset) { index, app in
                        TopAppRow(
                            app: app,
                            rank: index + 1,
                            maxTime: configuration.appUsageData.first?.totalTime ?? 1
                        )
                    }
                }
            }
        }
        .padding(20)
        .glassCard()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(GlassDesign.brand.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: "apps.iphone")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(GlassDesign.brand.opacity(0.6))
            }

            VStack(spacing: 4) {
                Text("No Activity Yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassDesign.textPrimary)

                Text("Start using apps to see your usage")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Top App Row
struct TopAppRow: View {
    let app: AppUsageInfo
    let rank: Int
    let maxTime: TimeInterval

    private var progress: Double {
        maxTime > 0 ? min(app.totalTime / maxTime, 1.0) : 0
    }

    private var rankColor: Color {
        switch rank {
        case 1: return GlassDesign.gold
        case 2: return GlassDesign.silver
        case 3: return GlassDesign.bronze
        default: return GlassDesign.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
            }

            // App info and progress
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(app.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(GlassDesign.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(app.formattedTime)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(GlassDesign.brand)
                        .monospacedDigit()
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [GlassDesign.brand, GlassDesign.brand.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
