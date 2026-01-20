import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct FocusEntry: TimelineEntry {
    let date: Date
    let focusMinutes: Int
    let streakDays: Int
    let blockedApps: Int
    let isInFocusSession: Bool
    let dailyGoalMinutes: Int
}

// MARK: - Widget Provider
struct FocusWidgetProvider: TimelineProvider {

    // App Group for sharing data with main app
    let sharedDefaults = UserDefaults(suiteName: "group.com.unwire.focus")

    func placeholder(in context: Context) -> FocusEntry {
        FocusEntry(
            date: Date(),
            focusMinutes: 120,
            streakDays: 14,
            blockedApps: 5,
            isInFocusSession: false,
            dailyGoalMinutes: 180
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let entry = createEntry()

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func createEntry() -> FocusEntry {
        let focusMinutes = sharedDefaults?.integer(forKey: "todayFocusMinutes") ?? 0
        let streakDays = sharedDefaults?.integer(forKey: "streakDays") ?? 0
        let blockedApps = sharedDefaults?.integer(forKey: "blockedAppsCount") ?? 0
        let isInFocusSession = sharedDefaults?.bool(forKey: "isInFocusSession") ?? false
        let dailyGoalMinutes = sharedDefaults?.integer(forKey: "dailyGoalMinutes") ?? 180

        return FocusEntry(
            date: Date(),
            focusMinutes: focusMinutes,
            streakDays: streakDays,
            blockedApps: blockedApps,
            isInFocusSession: isInFocusSession,
            dailyGoalMinutes: dailyGoalMinutes
        )
    }
}

// MARK: - Widget Views

struct FocusWidgetSmallView: View {
    let entry: FocusEntry

    var progress: Double {
        min(Double(entry.focusMinutes) / Double(entry.dailyGoalMinutes), 1.0)
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.075, green: 0.122, blue: 0.141)

            VStack(spacing: 8) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: 0.345, green: 0.8, blue: 0.008),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(entry.focusMinutes)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("min")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 70, height: 70)

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(entry.streakDays)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
}

struct FocusWidgetMediumView: View {
    let entry: FocusEntry

    var progress: Double {
        min(Double(entry.focusMinutes) / Double(entry.dailyGoalMinutes), 1.0)
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.075, green: 0.122, blue: 0.141)

            HStack(spacing: 16) {
                // Left side - Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: 0.345, green: 0.8, blue: 0.008),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(entry.focusMinutes)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("minutes")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 90, height: 90)

                // Right side - Stats
                VStack(alignment: .leading, spacing: 12) {
                    // Status
                    if entry.isInFocusSession {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: 0.345, green: 0.8, blue: 0.008))
                                .frame(width: 8, height: 8)
                            Text("In Focus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.345, green: 0.8, blue: 0.008))
                        }
                    } else {
                        Text("Ready to Focus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Stats row
                    HStack(spacing: 16) {
                        // Streak
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            Text("\(entry.streakDays)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Blocked apps
                        HStack(spacing: 4) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.112, green: 0.69, blue: 0.965))
                            Text("\(entry.blockedApps)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }

                    // Goal progress
                    Text("\(entry.dailyGoalMinutes - entry.focusMinutes) min to goal")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct FocusWidgetLargeView: View {
    let entry: FocusEntry

    var progress: Double {
        min(Double(entry.focusMinutes) / Double(entry.dailyGoalMinutes), 1.0)
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.075, green: 0.122, blue: 0.141)

            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Unwire")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    if entry.isInFocusSession {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(red: 0.345, green: 0.8, blue: 0.008))
                                .frame(width: 8, height: 8)
                            Text("Focusing")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.345, green: 0.8, blue: 0.008))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.345, green: 0.8, blue: 0.008).opacity(0.2))
                        .cornerRadius(12)
                    }
                }

                // Large Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: 0.345, green: 0.8, blue: 0.008),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 4) {
                        Text("\(entry.focusMinutes)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                        Text("minutes today")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 140, height: 140)

                // Stats Grid
                HStack(spacing: 20) {
                    StatBox(
                        icon: "flame.fill",
                        iconColor: .orange,
                        value: "\(entry.streakDays)",
                        label: "Day Streak"
                    )

                    StatBox(
                        icon: "shield.fill",
                        iconColor: Color(red: 0.112, green: 0.69, blue: 0.965),
                        value: "\(entry.blockedApps)",
                        label: "Blocked"
                    )

                    StatBox(
                        icon: "target",
                        iconColor: Color(red: 0.345, green: 0.8, blue: 0.008),
                        value: "\(Int(progress * 100))%",
                        label: "Goal"
                    )
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct StatBox: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget Configuration

struct FocusWidget: Widget {
    let kind: String = "FocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Stats")
        .description("Track your daily focus time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FocusEntry

    var body: some View {
        switch family {
        case .systemSmall:
            FocusWidgetSmallView(entry: entry)
        case .systemMedium:
            FocusWidgetMediumView(entry: entry)
        case .systemLarge:
            FocusWidgetLargeView(entry: entry)
        default:
            FocusWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct UnwireWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusWidget()
    }
}

// MARK: - Previews

struct FocusWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FocusWidgetSmallView(entry: FocusEntry(
                date: Date(),
                focusMinutes: 120,
                streakDays: 14,
                blockedApps: 5,
                isInFocusSession: false,
                dailyGoalMinutes: 180
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            FocusWidgetMediumView(entry: FocusEntry(
                date: Date(),
                focusMinutes: 120,
                streakDays: 14,
                blockedApps: 5,
                isInFocusSession: true,
                dailyGoalMinutes: 180
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            FocusWidgetLargeView(entry: FocusEntry(
                date: Date(),
                focusMinutes: 120,
                streakDays: 14,
                blockedApps: 5,
                isInFocusSession: true,
                dailyGoalMinutes: 180
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
