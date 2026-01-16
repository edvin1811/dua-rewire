//
//  CalendarScreenTimeReport.swift
//  ActivityMonitor
//
//  Report scene for Calendar view screen time data
//

import DeviceActivity
import SwiftUI

struct CalendarScreenTimeReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "CalendarScreenTime")
    let content: (TotalActivityConfiguration) -> CalendarScreenTimeCard
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

struct CalendarScreenTimeCard: View {
    let configuration: TotalActivityConfiguration
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: My Screen Time
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(configuration.formattedTotalTime)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GlassDesign.textPrimary, GlassDesign.textPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(GlassDesign.success)
                    
                    Button {
                        // Info action
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(GlassDesign.textSecondary)
                    }
                }
                
                Text("My screen time")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 20)
            
            // Clean Divider
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right: My Goal
            VStack(alignment: .leading, spacing: 8) {
                Text(formatGoalTime())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GlassDesign.brand, GlassDesign.brand.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("My goal today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
        }
        .padding(20)
        .modifier(GlassEffect(shape: RoundedRectangle(cornerRadius: 20)))
    }
    
    private func formatGoalTime() -> String {
        let goal = AppGroupConfig.dailyGoal
        let hours = Int(goal) / 3600
        let minutes = (Int(goal) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

