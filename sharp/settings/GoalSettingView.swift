//
//  GoalSettingView.swift
//  sharp
//
//  Created by Claude Code on 2025-12-03.
//

import SwiftUI

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var statisticsManager: StatisticsManager

    @State private var selectedMinutes: Double = 120 // Default 2 hours in minutes

    let minMinutes: Double = 30
    let maxMinutes: Double = 360 // 6 hours

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Goal display
                        goalDisplaySection

                        // Slider
                        sliderSection

                        // Recommended section
                        recommendedSection

                        // Save button
                        saveButton

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize with current goal
            selectedMinutes = statisticsManager.dailyGoal / 60
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                    DuoHaptics.lightTap()
                } label: {
                    ZStack {
                        // Solid shadow
                        Circle()
                            .fill(Color.uwCardShadow)
                            .frame(width: 44, height: 44)
                            .offset(y: 3)

                        Circle()
                            .fill(Color.uwCard)
                            .frame(width: 44, height: 44)

                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextPrimary)
                    }
                }
            }

            VStack(spacing: 8) {
                Text("Daily Screen Time Goal")
                    .font(.duoTitle)
                    .foregroundColor(.uwTextPrimary)

                Text("Set your target for daily screen time")
                    .font(.duoBody)
                    .foregroundColor(.uwTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Goal Display
    private var goalDisplaySection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.uwPrimary)

                Text(formatGoalTime(minutes: selectedMinutes))
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)
            }

            Text("per day")
                .font(.duoBody)
                .foregroundColor(.uwTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .duo3DCard(padding: 32, cornerRadius: 24)
    }

    // MARK: - Slider Section
    private var sliderSection: some View {
        VStack(spacing: 20) {
            // Custom slider
            Slider(
                value: $selectedMinutes,
                in: minMinutes...maxMinutes,
                step: 15
            )
            .tint(.uwPrimary)
            .onChange(of: selectedMinutes) { _,_ in
                DuoHaptics.lightTap()
            }

            // Min/Max labels
            HStack {
                Text(formatGoalTime(minutes: minMinutes))
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)

                Spacer()

                Text(formatGoalTime(minutes: maxMinutes))
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }
        }
        .duoCard(padding: 24, cornerRadius: 20)
    }

    // MARK: - Recommended Section
    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.uwAccent)

                Text("Recommended")
                    .font(.duoHeadline)
                    .foregroundColor(.uwTextPrimary)
            }

            Text("Research suggests 2-3 hours of daily screen time is healthy for most adults. Start with a goal slightly below your current average.")
                .font(.duoBody)
                .foregroundColor(.uwTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Quick preset buttons
            HStack(spacing: 12) {
                presetButton(hours: 2, label: "2h")
                presetButton(hours: 3, label: "3h")
                presetButton(hours: 4, label: "4h")
            }
        }
        .duoCard(padding: 24, cornerRadius: 20)
    }

    private func presetButton(hours: Int, label: String) -> some View {
        Button {
            withAnimation(DuoAnimation.buttonPress) {
                selectedMinutes = Double(hours * 60)
            }
            DuoHaptics.buttonTap()
        } label: {
            Text(label)
        }
        .buttonStyle(DuoPillButtonStyle(isSelected: selectedMinutes == Double(hours * 60), tint: .uwAccent))
    }

    // MARK: - Action Buttons
    private var saveButton: some View {
        VStack(spacing: 12) {
            // Primary action - filled button
            Button {
                statisticsManager.setDailyGoal(selectedMinutes * 60)
                dismiss()
                DuoHaptics.success()
            } label: {
                HStack(spacing: 12) {
                    Text("Set Goal")
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .buttonStyle(DuoPrimaryButton())

            // Secondary action - outline button
            Button {
                dismiss()
                DuoHaptics.lightTap()
            } label: {
                Text("Cancel")
            }
            .buttonStyle(DuoSecondaryButtonStyle())
        }
        .padding(.top, 20)
    }

    // MARK: - Helper Functions
    private func formatGoalTime(minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

#Preview {
    GoalSettingView(statisticsManager: StatisticsManager.shared)
}
