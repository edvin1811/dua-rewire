//
//  AccountStatsCardView.swift
//  ActivityMonitor
//
//  Weekly/Monthly overview card with bar chart - matches weeklyStatsSection style
//  Context: "AccountStats"
//

import SwiftUI

enum StatsViewMode: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct AccountStatsCardView: View {
    let configuration: TotalActivityConfiguration
    @State private var viewMode: StatsViewMode = .week
    @State private var animatedBars: Bool = false

    // Calculate daily average from today's data
    private var dailyAverage: TimeInterval {
        configuration.totalScreenTime
    }

    // Weekly total (estimated from today's data)
    private var weeklyTotal: TimeInterval {
        configuration.totalScreenTime * 7
    }

    // Monthly total (estimated)
    private var monthlyTotal: TimeInterval {
        configuration.totalScreenTime * 30
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack {
                Text(viewMode == .week ? "Weekly Overview" : "Monthly Overview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(GlassDesign.textPrimary)

                Spacer()

                
            }

            // Stats row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Avg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GlassDesign.textSecondary)

                    Text(TimeFormatter.format(dailyAverage))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(GlassDesign.brand)
                }

                Rectangle()
                    .fill(GlassDesign.border)
                    .frame(width: 1, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewMode == .week ? "Weekly Total" : "Monthly Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GlassDesign.textSecondary)

                    Text(TimeFormatter.format(viewMode == .week ? weeklyTotal : monthlyTotal))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(GlassDesign.textPrimary)
                }

                Spacer()
            }

            // Bar chart
            if viewMode == .week {
                weeklyBarChart
            } else {
                monthlyBarChart
            }

            // Average info
            HStack {
                Text("Daily average:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.textSecondary)

                Text(TimeFormatter.format(dailyAverage))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(GlassDesign.brand)

                Spacer()
            }

            // Week/Month toggle
            HStack {
                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewMode = viewMode == .week ? .month : .week
                        animatedBars = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                animatedBars = true
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(viewMode == .week ? "View Monthly" : "View Weekly")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(GlassDesign.brand)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(GlassDesign.brand)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(GlassDesign.brand.opacity(0.15))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(GlassDesign.brand.opacity(0.3), lineWidth: 1)
                    )
                }

                Spacer()
            }
        }
        .padding(20)
        .glassCard()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedBars = true
                }
            }
        }
    }

    // MARK: - Weekly Bar Chart
    private var weeklyBarChart: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                let isToday = isCurrentDay(day)
                let height = getWeeklyBarHeight(for: index, isToday: isToday)

                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            isToday
                                ? LinearGradient(
                                    colors: [GlassDesign.brand, GlassDesign.brand.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                        )
                        .frame(height: animatedBars ? height : 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isToday ? GlassDesign.brand.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )

                    Text(String(day.prefix(1)))
                        .font(.system(size: 10, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? GlassDesign.brand : GlassDesign.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 90)
    }

    // MARK: - Monthly Bar Chart
    private var monthlyBarChart: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<4, id: \.self) { weekIndex in
                let isCurrentWeek = weekIndex == getCurrentWeekOfMonth()
                let height = getMonthlyBarHeight(for: weekIndex, isCurrent: isCurrentWeek)

                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            isCurrentWeek
                                ? LinearGradient(
                                    colors: [GlassDesign.brand, GlassDesign.brand.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                  )
                        )
                        .frame(height: animatedBars ? height : 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    isCurrentWeek ? GlassDesign.brand.opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )

                    Text("W\(weekIndex + 1)")
                        .font(.system(size: 10, weight: isCurrentWeek ? .bold : .medium))
                        .foregroundColor(isCurrentWeek ? GlassDesign.brand : GlassDesign.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 90)
    }

    // MARK: - Helpers
    private var weekDays: [String] {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }

    private func isCurrentDay(_ day: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date()) == day
    }

    private func getWeeklyBarHeight(for index: Int, isToday: Bool) -> CGFloat {
        if isToday {
            // Today's bar based on actual screen time
            let todayMinutes = configuration.totalScreenTime / 60
            let maxMinutes: Double = 480 // 8 hours max
            let normalized = min(todayMinutes / maxMinutes, 1.0)
            return max(12, CGFloat(normalized) * 70)
        } else {
            // Past/future days show variation based on average
            let avgMinutes = configuration.totalScreenTime / 60
            let maxMinutes: Double = 480
            let variation = Double(abs(index - 3)) * 0.1 + 0.7
            let normalized = min((avgMinutes * variation) / maxMinutes, 1.0)
            return max(12, CGFloat(normalized) * 70)
        }
    }

    private func getCurrentWeekOfMonth() -> Int {
        let calendar = Calendar.current
        let weekOfMonth = calendar.component(.weekOfMonth, from: Date())
        return min(weekOfMonth - 1, 3)
    }

    private func getMonthlyBarHeight(for weekIndex: Int, isCurrent: Bool) -> CGFloat {
        if isCurrent {
            let todayMinutes = configuration.totalScreenTime / 60
            let maxMinutes: Double = 480
            let normalized = min(todayMinutes / maxMinutes, 1.0)
            return max(12, CGFloat(normalized) * 70)
        } else {
            let avgMinutes = configuration.totalScreenTime / 60
            let maxMinutes: Double = 480
            let variation = Double(weekIndex + 1) * 0.15 + 0.5
            let normalized = min((avgMinutes * variation) / maxMinutes, 1.0)
            return max(12, CGFloat(normalized) * 70)
        }
    }
}
