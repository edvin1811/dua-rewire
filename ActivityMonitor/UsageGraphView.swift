//
//  UsageGraphView.swift
//  ActivityMonitor
//
//  Simple graph view with gradient bars for daily/weekly usage
//

import SwiftUI

struct UsageGraphView: View {
    let configuration: TotalActivityConfiguration
    let mode: GraphMode
    
    enum GraphMode {
        case daily
        case weekly
    }
    
    @State private var animatedBars: [Bool] = Array(repeating: false, count: 24)
    
    var body: some View {
        VStack(spacing: 12) {
            if mode == .daily {
                dailyGraph
            } else {
                weeklyGraph
            }
        }
        .onAppear {
            animateBars()
        }
    }
    
    // MARK: - Daily Graph (24 hours)
    private var dailyGraph: some View {
        VStack(spacing: 8) {
            // Bars
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { hour in
                    let minutes = configuration.hourlyBreakdown.first(where: { $0.hour == hour })?.totalMinutes ?? 0
                    let maxMinutes = max(configuration.hourlyBreakdown.map { $0.totalMinutes }.max() ?? 60, 60)
                    let height = maxMinutes > 0 ? CGFloat(minutes) / CGFloat(maxMinutes) * 120 : 0
                    
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: barGradientColors(for: minutes, maxMinutes: maxMinutes),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 8, height: animatedBars[hour] ? max(height, 4) : 4)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7)
                                .delay(Double(hour) * 0.02),
                                value: animatedBars[hour]
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            
            // X-axis labels
            HStack {
                Text("00")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textTertiary)
                Spacer()
                Text("06")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textTertiary)
                Spacer()
                Text("12")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textTertiary)
                Spacer()
                Text("18")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textTertiary)
                Spacer()
                Text("23")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GlassDesign.textTertiary)
            }
        }
    }
    
    // MARK: - Weekly Graph (7 days)
    private var weeklyGraph: some View {
        VStack(spacing: 8) {
            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { dayIndex in
                    // Placeholder - would need weekly data
                    let height: CGFloat = CGFloat.random(in: 40...100)
                    
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [GlassDesign.brand, GlassDesign.brand.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 24, height: height)
                        
                        Text(dayName(for: dayIndex))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(GlassDesign.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
    }
    
    private func barGradientColors(for minutes: Int, maxMinutes: Int) -> [Color] {
        let intensity = CGFloat(minutes) / CGFloat(maxMinutes)
        
        if intensity < 0.3 {
            return [GlassDesign.brand.opacity(0.4), GlassDesign.brand.opacity(0.2)]
        } else if intensity < 0.6 {
            return [GlassDesign.brand.opacity(0.7), GlassDesign.brand.opacity(0.4)]
        } else {
            return [GlassDesign.brand, GlassDesign.brand.opacity(0.7)]
        }
    }
    
    private func dayName(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[index]
    }
    
    private func animateBars() {
        for i in 0..<24 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                animatedBars[i] = true
            }
        }
    }
}

