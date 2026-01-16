//
//  BlockingActivityWidgetLiveActivity.swift
//  BlockingActivityWidget
//
//  Created for Sharp App
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
@available(iOS 16.1, *)
struct BlockingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var sessionType: String  // "timer", "schedule", "task", "location", "steps", "sleep"
        var sessionName: String
        var statusText: String

        // Type-specific data
        var timerEndDate: Date?
        var timerDuration: TimeInterval?
        var scheduleEndTime: String?
        var taskProgress: TaskProgress?
        var locationIsInside: Bool?
        var stepsProgress: StepsProgress?
        var sleepWakeTime: String?

        var blockedAppsCount: Int
        var sessionId: String
    }

    let sessionStartTime: Date
    let primaryColor: String
}

@available(iOS 16.1, *)
struct TaskProgress: Codable, Hashable {
    let completed: Int
    let total: Int

    var progressPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

@available(iOS 16.1, *)
struct StepsProgress: Codable, Hashable {
    let current: Int
    let target: Int

    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
}

// MARK: - Live Activity Widget
struct BlockingActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BlockingActivityAttributes.self) { context in
            // Lock screen/banner UI
            lockScreenView(context: context)
                .activityBackgroundTint(Color(hex: context.attributes.primaryColor).opacity(0.1))
                .activitySystemActionForegroundColor(Color(hex: context.attributes.primaryColor))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(context: context)
                }
            } compactLeading: {
                compactLeading(context: context)
            } compactTrailing: {
                compactTrailing(context: context)
            } minimal: {
                minimal(context: context)
            }
            .keylineTint(Color(hex: context.attributes.primaryColor))
        }
    }

    // MARK: - Lock Screen View
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Icon
                Image(systemName: context.state.sessionIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))

                VStack(alignment: .leading, spacing: 4) {
                    // Session name
                    Text(context.state.sessionName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)

                    // Status text
                    Text(context.state.statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Type-specific trailing content
                lockScreenTrailing(context: context)
            }

            // Progress bar for certain types
            if let progress = getProgress(for: context.state) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: context.attributes.primaryColor)))
                    .frame(height: 6)
            }

            // Blocked apps count
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("\(context.state.blockedAppsCount) apps blocked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func lockScreenTrailing(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        switch context.state.sessionType {
        case "timer":
            if let endDate = context.state.timerEndDate {
                Text(endDate, style: .timer)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
                    .monospacedDigit()
            }

        case "steps":
            if let stepsProgress = context.state.stepsProgress {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stepsProgress.current)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.primaryColor))

                    Text("/ \(stepsProgress.target)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

        case "task":
            if let taskProgress = context.state.taskProgress {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(taskProgress.completed)/\(taskProgress.total)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.primaryColor))

                    Text("tasks")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

        case "schedule":
            if let endTime = context.state.scheduleEndTime {
                Text("Until \(endTime)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
            }

        case "location":
            Image(systemName: context.state.locationIsInside == true ? "location.fill" : "location.slash.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: context.attributes.primaryColor))

        case "sleep":
            if let wakeTime = context.state.sleepWakeTime {
                Text("Until \(wakeTime)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Dynamic Island - Expanded Regions
    @ViewBuilder
    private func expandedLeading(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: context.state.sessionIcon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: context.attributes.primaryColor))

            Text(context.state.sessionName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
    }

    @ViewBuilder
    private func expandedTrailing(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        switch context.state.sessionType {
        case "timer":
            if let endDate = context.state.timerEndDate {
                Text(endDate, style: .timer)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
                    .monospacedDigit()
            }

        case "steps":
            if let stepsProgress = context.state.stepsProgress {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stepsProgress.current)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: context.attributes.primaryColor))

                    Text("/ \(stepsProgress.target)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

        default:
            Text(context.state.statusText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func expandedBottom(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Progress bar for steps/tasks
            if let progress = getProgress(for: context.state) {
                VStack(spacing: 4) {
                    HStack {
                        Text(getProgressLabel(for: context.state))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: context.attributes.primaryColor))
                    }

                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: context.attributes.primaryColor)))
                        .frame(height: 4)
                }
            }

            // Blocked apps indicator
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10))

                Text("\(context.state.blockedAppsCount) apps blocked")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Dynamic Island - Compact Views
    @ViewBuilder
    private func compactLeading(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        Image(systemName: context.state.sessionIcon)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color(hex: context.attributes.primaryColor))
    }

    @ViewBuilder
    private func compactTrailing(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        switch context.state.sessionType {
        case "timer":
            if let endDate = context.state.timerEndDate {
                Text(endDate, style: .timer)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
                    .monospacedDigit()
            }

        case "steps":
            if let stepsProgress = context.state.stepsProgress {
                Text("\(stepsProgress.current)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
            }

        case "task":
            if let taskProgress = context.state.taskProgress {
                Text("\(taskProgress.completed)/\(taskProgress.total)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: context.attributes.primaryColor))
            }

        default:
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: context.attributes.primaryColor))
        }
    }

    @ViewBuilder
    private func minimal(context: ActivityViewContext<BlockingActivityAttributes>) -> some View {
        Image(systemName: context.state.sessionIcon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(hex: context.attributes.primaryColor))
    }

    // MARK: - Helper Functions
    private func getProgress(for state: BlockingActivityAttributes.ContentState) -> Double? {
        if let stepsProgress = state.stepsProgress {
            return stepsProgress.progressPercentage
        }

        if let taskProgress = state.taskProgress {
            return taskProgress.progressPercentage
        }

        return nil
    }

    private func getProgressLabel(for state: BlockingActivityAttributes.ContentState) -> String {
        if state.stepsProgress != nil {
            return "Steps Progress"
        }

        if state.taskProgress != nil {
            return "Task Progress"
        }

        return "Progress"
    }
}

// MARK: - Color Extension for Hex (Widget Only)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ContentState Extension for Icon
extension BlockingActivityAttributes.ContentState {
    var sessionIcon: String {
        switch sessionType {
        case "timer":
            return "timer"
        case "schedule":
            return "calendar.circle.fill"
        case "task":
            return "checkmark.circle.fill"
        case "location":
            return "location.fill"
        case "steps":
            return "figure.walk"
        case "sleep":
            return "moon.fill"
        default:
            return "lock.shield.fill"
        }
    }
}

// MARK: - Preview
#Preview("Timer", as: .content, using: BlockingActivityAttributes(
    sessionStartTime: Date(),
    primaryColor: "1CB0F6"
)) {
    BlockingActivityWidgetLiveActivity()
} contentStates: {
    BlockingActivityAttributes.ContentState(
        sessionType: "timer",
        sessionName: "Deep Work",
        statusText: "Stay focused",
        timerEndDate: Date().addingTimeInterval(1800),
        timerDuration: 1800,
        scheduleEndTime: nil,
        taskProgress: nil,
        locationIsInside: nil,
        stepsProgress: nil,
        sleepWakeTime: nil,
        blockedAppsCount: 5,
        sessionId: "preview-1"
    )
}

#Preview("Steps", as: .content, using: BlockingActivityAttributes(
    sessionStartTime: Date(),
    primaryColor: "FFC800"
)) {
    BlockingActivityWidgetLiveActivity()
} contentStates: {
    BlockingActivityAttributes.ContentState(
        sessionType: "steps",
        sessionName: "Active Goal",
        statusText: "Keep walking!",
        timerEndDate: nil,
        timerDuration: nil,
        scheduleEndTime: nil,
        taskProgress: nil,
        locationIsInside: nil,
        stepsProgress: StepsProgress(current: 1250, target: 2000),
        sleepWakeTime: nil,
        blockedAppsCount: 3,
        sessionId: "preview-2"
    )
}
