import DeviceActivity
import SwiftUI
import ManagedSettings

@main
struct TotalActivityReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Original combined views
        TotalActivityReport { configuration in
            TotalActivityView(configuration: configuration)
        }

        AccountActivityReport { configuration in
            AccountActivityView(configuration: configuration)
        }

        // NEW: Home screen with proper app icons using ApplicationToken
        HomeScreenReportWithIcons { configuration in
            HomeScreenReportView(activityConfig: configuration)
        }

        // Modular components - each can be used independently
        ScreenTimeCardReport { configuration in
            ScreenTimeCardView(configuration: configuration)
        }

        ActivityChartReport { configuration in
            ActivityChartView(configuration: configuration)
        }

        TopAppsListReport { configuration in
            TopAppsListView(configuration: configuration)
        }

        GoalProgressReport { configuration in
            GoalProgressView(configuration: configuration)
        }

        AccountStatsReport { configuration in
            AccountStatsCardView(configuration: configuration)
        }
        
        // Calendar view reports
        CalendarScreenTimeReport { configuration in
            CalendarScreenTimeCard(configuration: configuration)
        }

        CalendarUsageGraphReport { configuration in
            UsageGraphView(configuration: configuration, mode: .daily)
        }

        // Calendar Most Used Apps with real icons
        CalendarMostUsedAppsReport { configuration in
            CalendarMostUsedAppsView(configuration: configuration)
        }
    }
}

// MARK: - Calendar Most Used Apps Report (uses ApplicationToken for real icons)
struct CalendarMostUsedAppsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "CalendarMostUsedApps")
    let content: (ActivityConfiguration) -> CalendarMostUsedAppsView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityConfiguration {
        await createConfigurationWithTokens(from: data)
    }
}

// MARK: - Home Screen Report with App Icons (uses ApplicationToken)
struct HomeScreenReportWithIcons: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "HomeScreen")
    let content: (ActivityConfiguration) -> HomeScreenReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ActivityConfiguration {
        await createConfigurationWithTokens(from: data)
    }
}

// MARK: - Configuration Builder with ApplicationTokens
private func createConfigurationWithTokens(from data: DeviceActivityResults<DeviceActivityData>) async -> ActivityConfiguration {
    var totalScreenTime: TimeInterval = 0
    var appTokenUsage: [ApplicationToken: TimeInterval] = [:]
    var hourlyData: [Int: TimeInterval] = [:]

    for await activityData in data {
        for await segment in activityData.activitySegments {
            totalScreenTime += segment.totalActivityDuration

            let hour = Calendar.current.component(.hour, from: segment.dateInterval.start)
            hourlyData[hour, default: 0] += segment.totalActivityDuration

            // Extract app tokens from categories
            for await category in segment.categories {
                for await activity in category.applications {
                    guard let token = activity.application.token else { continue }
                    appTokenUsage[token, default: 0] += activity.totalActivityDuration
                }
            }
        }
    }

    // Convert to AppActivityData sorted by usage
    let appActivities = appTokenUsage
        .sorted { $0.value > $1.value }
        .prefix(8)
        .map { token, time in
            AppActivityData(token: token, totalTime: time)
        }

    // Create hourly breakdown
    let hourlyBreakdown = (0...23).map { hour in
        let seconds = hourlyData[hour] ?? 0
        let minutes = Int(seconds / 60)
        return HourlyUsageData(hour: hour, totalMinutes: minutes, apps: [])
    }

    return ActivityConfiguration(
        totalScreenTime: totalScreenTime,
        appActivities: Array(appActivities),
        hourlyBreakdown: hourlyBreakdown
    )
}

// MARK: - Modular Report Scenes

struct ScreenTimeCardReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "ScreenTimeCard")
    let content: (TotalActivityConfiguration) -> ScreenTimeCardView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

struct ActivityChartReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "ActivityChart")
    let content: (TotalActivityConfiguration) -> ActivityChartView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

struct TopAppsListReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "TopAppsList")
    let content: (TotalActivityConfiguration) -> TopAppsListView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

struct GoalProgressReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "GoalProgress")
    let content: (TotalActivityConfiguration) -> GoalProgressView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

struct AccountStatsReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "AccountStats")
    let content: (TotalActivityConfiguration) -> AccountStatsCardView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

// MARK: - Shared Configuration Builder
func createConfiguration(from data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
    var totalScreenTime: TimeInterval = 0
    var processedApps: [String: TimeInterval] = [:]
    var hourlyData: [Int: TimeInterval] = [:]

    do {
        for await deviceData in data {
            var segmentCount = 0
            for await activitySegment in deviceData.activitySegments {
                segmentCount += 1
                if segmentCount > 20 { break }

                totalScreenTime += activitySegment.totalActivityDuration

                let hour = Calendar.current.component(.hour, from: activitySegment.dateInterval.start)
                hourlyData[hour, default: 0] += activitySegment.totalActivityDuration

                let segmentApps = extractAppsFromSegment(activitySegment)
                for app in segmentApps {
                    processedApps[app.bundleIdentifier, default: 0] += app.totalTime
                }
            }
        }
    } catch {
        print("Error processing data: \(error)")
    }

    let appUsageData = processedApps
        .sorted { $0.value > $1.value }
        .prefix(8)
        .map { bundleId, totalTime in
            AppUsageInfo(
                name: getAppName(for: bundleId),
                bundleIdentifier: bundleId,
                totalTime: totalTime,
                categories: ["Apps"]
            )
        }

    let hourlyBreakdown = (0...23).map { hour in
        let seconds = hourlyData[hour] ?? 0
        let minutes = Int(seconds / 60)
        return HourlyUsageData(hour: hour, totalMinutes: minutes, apps: [])
    }

    return TotalActivityConfiguration(
        totalScreenTime: totalScreenTime,
        appUsageData: appUsageData,
        hourlyBreakdown: hourlyBreakdown
    )
}

private func extractAppsFromSegment(_ segment: DeviceActivityData.ActivitySegment) -> [AppUsageInfo] {
    var apps: [AppUsageInfo] = []
    let mirror = Mirror(reflecting: segment)

    for child in mirror.children {
        if child.label ?? "" == "categoryActivities",
           let categories = child.value as? [Any] {
            for category in categories.prefix(2) {
                let categoryMirror = Mirror(reflecting: category)
                for categoryChild in categoryMirror.children {
                    if categoryChild.label ?? "" == "applicationActivities",
                       let appActivities = categoryChild.value as? [Any] {
                        for appActivity in appActivities.prefix(3) {
                            if let app = createAppUsageFromActivity(appActivity) {
                                apps.append(app)
                            }
                        }
                    }
                }
            }
            break
        }
    }
    return apps
}

private func createAppUsageFromActivity(_ appActivity: Any) -> AppUsageInfo? {
    let mirror = Mirror(reflecting: appActivity)
    var bundleId = ""
    var duration: TimeInterval = 0

    for child in mirror.children {
        switch child.label ?? "" {
        case "totalActivityDuration":
            duration = child.value as? TimeInterval ?? 0
        case "application":
            let appMirror = Mirror(reflecting: child.value)
            for appChild in appMirror.children {
                if appChild.label ?? "" == "bundleIdentifier",
                   let id = appChild.value as? String {
                    bundleId = id
                    break
                }
            }
        default:
            break
        }
    }

    guard duration >= 30 && !bundleId.isEmpty else { return nil }

    return AppUsageInfo(
        name: getAppName(for: bundleId),
        bundleIdentifier: bundleId,
        totalTime: duration,
        categories: ["Apps"]
    )
}

private func getAppName(for bundleId: String) -> String {
    let knownApps: [String: String] = [
        "com.apple.mobilesafari": "Safari",
        "com.apple.MobileSMS": "Messages",
        "com.apple.mobilemail": "Mail",
        "com.apple.Music": "Music",
        "com.apple.Photos": "Photos",
        "com.burbn.instagram": "Instagram",
        "com.spotify.client": "Spotify",
        "com.facebook.Facebook": "Facebook",
        "com.whatsapp.WhatsApp": "WhatsApp",
        "com.google.chrome.ios": "Chrome",
        "com.netflix.Netflix": "Netflix",
        "com.youtube.ios": "YouTube",
        "com.zhiliaoapp.musically": "TikTok",
        "com.twitter.twitter": "Twitter",
        "com.reddit.Reddit": "Reddit",
        "com.snapchat.Snapchat": "Snapchat"
    ]

    if let knownName = knownApps[bundleId] {
        return knownName
    }

    let components = bundleId.split(separator: ".")
    if let lastComponent = components.last {
        let clean = String(lastComponent)
            .replacingOccurrences(of: "ios", with: "")
            .replacingOccurrences(of: "mobile", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !clean.isEmpty && clean.count > 1 {
            return clean.capitalized
        }
    }
    return "App"
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "TotalActivity")
    let content: (TotalActivityConfiguration) -> TotalActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        print("🔧 ===== makeConfiguration STARTED =====")

        var totalScreenTime: TimeInterval = 0
        var appUsageData: [AppUsageInfo] = []

        // Simple processing to avoid memory issues
        var processedApps: [String: TimeInterval] = [:]
        var hourlyData: [Int: TimeInterval] = [:]

        do {
            for await deviceData in data {
                print("📱 Processing device data")

                var segmentCount = 0
                for await activitySegment in deviceData.activitySegments {
                    segmentCount += 1
                    if segmentCount > 20 { break } // Memory limit

                    totalScreenTime += activitySegment.totalActivityDuration

                    // Get hour from segment date interval
                    let hour = Calendar.current.component(.hour, from: activitySegment.dateInterval.start)
                    hourlyData[hour, default: 0] += activitySegment.totalActivityDuration

                    // Extract apps from this segment
                    let segmentApps = extractApps(from: activitySegment)
                    for app in segmentApps {
                        processedApps[app.bundleIdentifier, default: 0] += app.totalTime
                    }
                }
            }
        } catch {
            print("❌ Error processing data: \(error)") }

        // Convert to final format
        appUsageData = processedApps
            .sorted { $0.value > $1.value }
            .prefix(8) // Limit to prevent memory issues
            .map { bundleId, totalTime in
                AppUsageInfo(
                    name: getSimpleAppName(for: bundleId),
                    bundleIdentifier: bundleId,
                    totalTime: totalTime,
                    categories: ["Apps"]
                )
            }

        // Create hourly breakdown
        let hourlyBreakdown = (0...23).map { hour in
            let seconds = hourlyData[hour] ?? 0
            let minutes = Int(seconds / 60)
            return HourlyUsageData(hour: hour, totalMinutes: minutes, apps: [])
        }

        let config = TotalActivityConfiguration(
            totalScreenTime: totalScreenTime,
            appUsageData: appUsageData,
            hourlyBreakdown: hourlyBreakdown
        )

        print("✅ Configuration complete: \(config.formattedTotalTime)")
        return config
    }

    private func extractApps(from segment: DeviceActivityData.ActivitySegment) -> [AppUsageInfo] {
        var apps: [AppUsageInfo] = []

        let mirror = Mirror(reflecting: segment)
        for child in mirror.children {
            if child.label ?? "" == "categoryActivities",
               let categories = child.value as? [Any] {

                for category in categories.prefix(2) { // Limit categories
                    let categoryMirror = Mirror(reflecting: category)
                    for categoryChild in categoryMirror.children {
                        if categoryChild.label ?? "" == "applicationActivities",
                           let appActivities = categoryChild.value as? [Any] {

                            for appActivity in appActivities.prefix(3) { // Limit apps
                                if let app = createAppUsage(from: appActivity) {
                                    apps.append(app)
                                }
                            }
                        }
                    }
                }
                break
            }
        }

        return apps
    }

    private func createAppUsage(from appActivity: Any) -> AppUsageInfo? {
        let mirror = Mirror(reflecting: appActivity)

        var bundleId = ""
        var duration: TimeInterval = 0

        for child in mirror.children {
            switch child.label ?? "" {
            case "totalActivityDuration":
                duration = child.value as? TimeInterval ?? 0
            case "application":
                let appMirror = Mirror(reflecting: child.value)
                for appChild in appMirror.children {
                    if appChild.label ?? "" == "bundleIdentifier",
                       let id = appChild.value as? String {
                        bundleId = id
                        break
                    }
                }
            default:
                break
            }
        }

        guard duration >= 30 && !bundleId.isEmpty else { return nil }

        return AppUsageInfo(
            name: getSimpleAppName(for: bundleId),
            bundleIdentifier: bundleId,
            totalTime: duration,
            categories: ["Apps"]
        )
    }

    // Simple app name extraction - no external dependencies
    private func getSimpleAppName(for bundleId: String) -> String {
        // Basic known apps
        let knownApps: [String: String] = [
            "com.apple.mobilesafari": "Safari",
            "com.apple.MobileSMS": "Messages",
            "com.apple.mobilemail": "Mail",
            "com.apple.Music": "Music",
            "com.apple.Photos": "Photos",
            "com.burbn.instagram": "Instagram",
            "com.spotify.client": "Spotify",
            "com.facebook.Facebook": "Facebook",
            "com.whatsapp.WhatsApp": "WhatsApp",
            "com.google.chrome.ios": "Chrome",
            "com.netflix.Netflix": "Netflix",
            "com.youtube.ios": "YouTube"
        ]

        if let knownName = knownApps[bundleId] {
            return knownName
        }

        // Simple parsing
        let components = bundleId.split(separator: ".")
        if let lastComponent = components.last {
            let clean = String(lastComponent)
                .replacingOccurrences(of: "ios", with: "")
                .replacingOccurrences(of: "mobile", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !clean.isEmpty && clean.count > 1 {
                return clean.capitalized
            }
        }

        return "App"
    }
}

// MARK: - Account Activity Report (for Account page)
struct AccountActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "AccountActivity")
    let content: (TotalActivityConfiguration) -> AccountActivityView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        print("🔧 ===== AccountActivityReport makeConfiguration STARTED =====")

        var totalScreenTime: TimeInterval = 0
        var appUsageData: [AppUsageInfo] = []

        // Simple processing to avoid memory issues
        var processedApps: [String: TimeInterval] = [:]
        var hourlyData: [Int: TimeInterval] = [:]

        do {
            for await deviceData in data {
                print("📱 Processing device data for account")

                var segmentCount = 0
                for await activitySegment in deviceData.activitySegments {
                    segmentCount += 1
                    if segmentCount > 20 { break } // Memory limit

                    totalScreenTime += activitySegment.totalActivityDuration

                    // Get hour from segment date interval
                    let hour = Calendar.current.component(.hour, from: activitySegment.dateInterval.start)
                    hourlyData[hour, default: 0] += activitySegment.totalActivityDuration

                    // Extract apps from this segment
                    let segmentApps = extractApps(from: activitySegment)
                    for app in segmentApps {
                        processedApps[app.bundleIdentifier, default: 0] += app.totalTime
                    }
                }
            }
        } catch {
            print("❌ Error processing account data: \(error)")
        }

        // Convert to final format
        appUsageData = processedApps
            .sorted { $0.value > $1.value }
            .prefix(8) // Limit to prevent memory issues
            .map { bundleId, totalTime in
                AppUsageInfo(
                    name: getSimpleAppName(for: bundleId),
                    bundleIdentifier: bundleId,
                    totalTime: totalTime,
                    categories: ["Apps"]
                )
            }

        // Create hourly breakdown
        let hourlyBreakdown = (0...23).map { hour in
            let seconds = hourlyData[hour] ?? 0
            let minutes = Int(seconds / 60)
            return HourlyUsageData(hour: hour, totalMinutes: minutes, apps: [])
        }

        let config = TotalActivityConfiguration(
            totalScreenTime: totalScreenTime,
            appUsageData: appUsageData,
            hourlyBreakdown: hourlyBreakdown
        )

        print("✅ Account configuration complete: \(config.formattedTotalTime)")
        return config
    }

    private func extractApps(from segment: DeviceActivityData.ActivitySegment) -> [AppUsageInfo] {
        var apps: [AppUsageInfo] = []

        let mirror = Mirror(reflecting: segment)
        for child in mirror.children {
            if child.label ?? "" == "categoryActivities",
               let categories = child.value as? [Any] {

                for category in categories.prefix(2) { // Limit categories
                    let categoryMirror = Mirror(reflecting: category)
                    for categoryChild in categoryMirror.children {
                        if categoryChild.label ?? "" == "applicationActivities",
                           let appActivities = categoryChild.value as? [Any] {

                            for appActivity in appActivities.prefix(3) { // Limit apps
                                if let app = createAppUsage(from: appActivity) {
                                    apps.append(app)
                                }
                            }
                        }
                    }
                }
                break
            }
        }

        return apps
    }

    private func createAppUsage(from appActivity: Any) -> AppUsageInfo? {
        let mirror = Mirror(reflecting: appActivity)

        var bundleId = ""
        var duration: TimeInterval = 0

        for child in mirror.children {
            switch child.label ?? "" {
            case "totalActivityDuration":
                duration = child.value as? TimeInterval ?? 0
            case "application":
                let appMirror = Mirror(reflecting: child.value)
                for appChild in appMirror.children {
                    if appChild.label ?? "" == "bundleIdentifier",
                       let id = appChild.value as? String {
                        bundleId = id
                        break
                    }
                }
            default:
                break
            }
        }

        guard duration >= 30 && !bundleId.isEmpty else { return nil }

        return AppUsageInfo(
            name: getSimpleAppName(for: bundleId),
            bundleIdentifier: bundleId,
            totalTime: duration,
            categories: ["Apps"]
        )
    }

    private func getSimpleAppName(for bundleId: String) -> String {
        let knownApps: [String: String] = [
            "com.apple.mobilesafari": "Safari",
            "com.apple.MobileSMS": "Messages",
            "com.apple.mobilemail": "Mail",
            "com.apple.Music": "Music",
            "com.apple.Photos": "Photos",
            "com.burbn.instagram": "Instagram",
            "com.spotify.client": "Spotify",
            "com.facebook.Facebook": "Facebook",
            "com.whatsapp.WhatsApp": "WhatsApp",
            "com.google.chrome.ios": "Chrome",
            "com.netflix.Netflix": "Netflix",
            "com.youtube.ios": "YouTube"
        ]

        if let knownName = knownApps[bundleId] {
            return knownName
        }

        let components = bundleId.split(separator: ".")
        if let lastComponent = components.last {
            let clean = String(lastComponent)
                .replacingOccurrences(of: "ios", with: "")
                .replacingOccurrences(of: "mobile", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !clean.isEmpty && clean.count > 1 {
                return clean.capitalized
            }
        }

        return "App"
    }
}
