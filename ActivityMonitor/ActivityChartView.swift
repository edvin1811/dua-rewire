//
//  ActivityChartView.swift
//  ActivityMonitor
//
//  Hourly activity bar chart component
//  Context: "ActivityChart"
//

import SwiftUI

struct ActivityChartView: View {
    let configuration: TotalActivityConfiguration
    @State private var animatedBars: [Bool] = Array(repeating: false, count: 24)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Activity Timeline")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassDesign.textPrimary)

                Spacer()

                Text("Today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(GlassDesign.background))
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { hour in
                    let minutes = configuration.hourlyBreakdown.first(where: { $0.hour == hour })?.totalMinutes ?? 0
                    let maxMinutes = configuration.hourlyBreakdown.map { $0.totalMinutes }.max() ?? 60
                    let height = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(max(maxMinutes, 1)) * 80 : 0

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: minutes))
                        .frame(width: 8, height: animatedBars[hour] ? max(height, 4) : 4)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(hour) * 0.02),
                            value: animatedBars[hour]
                        )
                }
            }
            .frame(height: 80)
            .padding(.vertical, 8)

            // Time labels
            HStack {
                Text("12am")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                Spacer()
                Text("6am")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                Spacer()
                Text("12pm")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                Spacer()
                Text("6pm")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
                Spacer()
                Text("Now")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(GlassDesign.brand)
            }
        }
        .padding(20)
        .glassCard()
        .onAppear {
            animateChartBars()
        }
    }

    private func barColor(for minutes: Int) -> Color {
        switch minutes {
        case 0: return Color.white.opacity(0.1)
        case 1...15: return GlassDesign.brand.opacity(0.4)
        case 16...30: return GlassDesign.brand.opacity(0.6)
        case 31...45: return GlassDesign.brand.opacity(0.8)
        default: return GlassDesign.brand
        }
    }

    private func animateChartBars() {
        for i in 0..<24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.03) {
                animatedBars[i] = true
            }
        }
    }
}
