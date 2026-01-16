//
//  ScreenTimeModels.swift
//  sharp
//

import Foundation
import ManagedSettings

// MARK: - App Activity with Token (for proper name/icon display using Label)
struct AppActivityData: Identifiable {
    let id = UUID()
    let token: ApplicationToken
    let totalTime: TimeInterval

    var formattedTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Enhanced Configuration with App Tokens
struct ActivityConfiguration {
    let totalScreenTime: TimeInterval
    let appActivities: [AppActivityData]  // Apps with tokens for Label display
    let hourlyBreakdown: [HourlyUsageData]

    var formattedTotalTime: String {
        let hours = Int(totalScreenTime) / 3600
        let minutes = Int(totalScreenTime) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var hasData: Bool {
        totalScreenTime > 0 || !appActivities.isEmpty
    }

    var activeHours: Int {
        hourlyBreakdown.filter { $0.hasUsage }.count
    }

    var peakUsageHour: Int? {
        hourlyBreakdown.max(by: { $0.totalMinutes < $1.totalMinutes })?.hour
    }

    static var empty: ActivityConfiguration {
        ActivityConfiguration(
            totalScreenTime: 0,
            appActivities: [],
            hourlyBreakdown: []
        )
    }
}

// MARK: - iTunes API Models
struct iTunesLookupResponse: Codable {
    let results: [iTunesApp]
}

struct iTunesApp: Codable {
    let trackName: String?
    let bundleId: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let primaryGenreName: String?
}

// MARK: - Enhanced App Name Lookup
class AppNameLookup {
    static let shared = AppNameLookup()
    internal var cache: [String: String] = [:] // Changed to internal for extension access
    
    private init() {
        setupSystemApps()
    }
    
    private func setupSystemApps() {
        // Enhanced cache with more apps for better performance
        cache = [
            // System Apps
            "com.apple.weather": "Weather",
            "com.apple.mobilemail": "Mail",
            "com.apple.MobileSMS": "Messages",
            "com.apple.Preferences": "Settings",
            "com.apple.mobilephone": "Phone",
            "com.apple.mobilecal": "Calendar",
            "com.apple.mobilenotes": "Notes",
            "com.apple.Maps": "Maps",
            "com.apple.camera": "Camera",
            "com.apple.mobilesafari": "Safari",
            "com.apple.Music": "Music",
            "com.apple.tv": "Apple TV",
            "com.apple.AppStore": "App Store",
            "com.apple.Health": "Health",
            "com.apple.Fitness": "Fitness",
            "com.apple.wallet": "Wallet",
            "com.apple.facetime": "FaceTime",
            "com.apple.shortcuts": "Shortcuts",
            "com.apple.Photos": "Photos",
            "com.apple.Podcasts": "Podcasts",
            "com.apple.News": "News",
            "com.apple.stocks": "Stocks",
            "com.apple.calculator": "Calculator",
            "com.apple.compass": "Compass",
            "com.apple.measure": "Measure",
            "com.apple.findmy": "Find My",
            "com.apple.reminders": "Reminders",
            "com.apple.VoiceMemos": "Voice Memos",
            "com.apple.iBooks": "Books",
            "com.apple.clips": "Clips",
            "com.apple.garageband": "GarageBand",
            "com.apple.iMovie": "iMovie",
            "com.apple.Keynote": "Keynote",
            "com.apple.Numbers": "Numbers",
            "com.apple.Pages": "Pages",
            "com.apple.FCAuthenticationUI": "Face ID",
            "com.apple.ScreenshotServicesService": "Screenshot",
            "com.apple.CoreAuthUI": "Authentication",
            "com.apple.Translate": "Translate",
            "com.apple.tips": "Tips",
            "com.apple.accessibility.AccessibilityInspector": "Accessibility Inspector",
            "com.apple.DocumentsApp": "Files",
            "com.apple.Bridge": "Watch",
            "com.apple.Home": "Home",
            "com.apple.Magnifier": "Magnifier",
            "com.apple.CloudDocs.MobileDocumentsFileProvider": "iCloud Drive",
            
            // Popular Third-party Apps
            "com.burbn.instagram": "Instagram",
            "com.toyopagroup.picaboo": "Snapchat",
            "com.burbn.barcelona": "Threads",
            "com.facebook.Facebook": "Facebook",
            "com.facebook.Messenger": "Messenger",
            "com.spotify.client": "Spotify",
            "com.cardify.tinder": "Tinder",
            "co.hinge.mobile.ios": "Hinge",
            "com.twitter.twitter": "Twitter",
            "com.linkedin.LinkedIn": "LinkedIn",
            "com.google.Gmail": "Gmail",
            "com.google.chrome.ios": "Chrome",
            "com.google.Maps": "Google Maps",
            "com.google.GoogleMobile": "Google",
            "com.netflix.Netflix": "Netflix",
            "com.youtube.ios": "YouTube",
            "com.whatsapp.WhatsApp": "WhatsApp",
            "com.telegram.Telegraph": "Telegram",
            "com.discord": "Discord",
            "com.zhiliaoapp.musically": "TikTok",
            "com.pinterest": "Pinterest",
            "com.reddit.Reddit": "Reddit",
            "com.amazon.Amazon": "Amazon",
            "com.ubercab.UberClient": "Uber",
            "com.airbnb.app": "Airbnb",
            "com.duolingo.DuolingoMobile": "Duolingo",
            "com.microsoft.Office.Word": "Microsoft Word",
            "com.microsoft.Office.Excel": "Microsoft Excel",
            "com.microsoft.Office.PowerPoint": "PowerPoint",
            "com.microsoft.Office.Outlook": "Outlook",
            "com.microsoft.msauth": "Microsoft Authenticator",
            "com.adobe.PSMobile": "Photoshop",
            "com.adobe.LightroomCC": "Lightroom",
            "com.adobe.reader": "Adobe Acrobat Reader",
            "com.dropbox.Dropbox": "Dropbox",
            "com.getdropbox.Dropbox": "Dropbox",
            "com.slack": "Slack",
            "us.zoom.videomeetings": "Zoom",
            "com.microsoft.teams": "Microsoft Teams",
            "com.shopify.arrive": "Shopify",
            "com.paypal.PPClient": "PayPal",
            "com.venmo.touch.v2": "Venmo",
            "com.square.cash": "Cash App",
            "com.robinhood.release.Robinhood": "Robinhood",
            "com.coinbase.CBMobile": "Coinbase",
            "com.binance.BinanceIOSApp": "Binance",
            "com.coolstudio.sharp": "Sharp"
        ]
    }
    
    func getAppName(for bundleId: String) async -> String {
        // Check cache first
        if let cachedName = cache[bundleId] {
            return cachedName
        }
        
        // Try to fetch from iTunes API with timeout
        if let fetchedName = await fetchFromiTunesWithTimeout(bundleId: bundleId) {
            cache[bundleId] = fetchedName
            return fetchedName
        }
        
        // Fallback to bundle ID parsing
        let fallbackName = bundleIdToAppName(bundleId)
        cache[bundleId] = fallbackName
        return fallbackName
    }
    
    private func fetchFromiTunesWithTimeout(bundleId: String) async -> String? {
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleId)") else {
            return nil
        }
        
        do {
            // Add timeout for better performance
            let request = URLRequest(url: url, timeoutInterval: 3.0)
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)
            
            if let app = response.results.first, let trackName = app.trackName {
                print("✅ iTunes API found: \(trackName)")
                return trackName
            }
        } catch {
            print("⚠️ iTunes API failed for \(bundleId): \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // Add the fetchFromiTunes method that the extension needs
    func fetchFromiTunes(bundleId: String) async -> String? {
        return await fetchFromiTunesWithTimeout(bundleId: bundleId)
    }
    
    // Make bundleIdToAppName internal so extension can access it
    internal func bundleIdToAppName(_ bundleId: String) -> String {
        // Enhanced parsing logic
        let components = bundleId.split(separator: ".")
        
        // Try to extract meaningful name from bundle ID
        if let lastComponent = components.last {
            let cleanName = String(lastComponent)
                .replacingOccurrences(of: "ios", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "mobile", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "app", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "client", with: "", options: .caseInsensitive)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !cleanName.isEmpty && cleanName.count > 1 {
                return cleanName.capitalized
            }
        }
        
        // Try second-to-last component if available
        if components.count >= 2 {
            let secondLast = String(components[components.count - 2])
            if !secondLast.isEmpty && secondLast.count > 2 {
                return secondLast.capitalized
            }
        }
        
        // Extract app name from bundle ID
        for component in components.reversed() {
            let comp = String(component)
            if comp.count > 3 && !["com", "org", "net", "www", "mobile", "ios", "app"].contains(comp.lowercased()) {
                return comp.capitalized
            }
        }
        
        return "Unknown App"
    }
}

// MARK: - Core Models
struct AppUsageInfo: Identifiable, Codable {
    var id = UUID()
    let name: String
    let bundleIdentifier: String
    let totalTime: TimeInterval
    let categories: [String]
    
    var productivityType: ProductivityType {
        ProductivityCategorizer.shared.classifyApp(categories: categories)
    }
    
    var isProductive: Bool {
        productivityType == .productive
    }
    
    var isNonProductive: Bool {
        productivityType == .nonProductive
    }
    
    var formattedTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var usageIntensity: Double {
        // Returns 0.0 to 1.0 based on usage time
        let maxReasonableUsage: TimeInterval = 4 * 3600 // 4 hours
        return min(totalTime / maxReasonableUsage, 1.0)
    }
    
    var isHeavyUsage: Bool {
        totalTime >= 3600 // 1+ hours
    }
}

struct HourlyUsageData: Identifiable, Codable {
    let id = UUID()
    let hour: Int // 0-23
    let totalMinutes: Int
    let apps: [AppUsageInfo]
    
    var hasUsage: Bool {
        totalMinutes > 0
    }
    
    var formattedTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var isEmpty: Bool {
        totalMinutes == 0 && apps.isEmpty
    }
}

struct DailyUsageData: Codable {
    let totalScreenTime: TimeInterval
    let appUsageData: [AppUsageInfo]
    let hourlyBreakdown: [HourlyUsageData]
    
    var averageSessionDuration: TimeInterval {
        let activeSessions = hourlyBreakdown.filter { $0.hasUsage }.count
        guard activeSessions > 0 else { return 0 }
        return totalScreenTime / Double(activeSessions)
    }
    
    var peakUsageHour: Int? {
        hourlyBreakdown.max(by: { $0.totalMinutes < $1.totalMinutes })?.hour
    }
    
    var hasAnyData: Bool {
        totalScreenTime > 0 || !appUsageData.isEmpty
    }
}

// Update the existing TotalActivityConfiguration
struct TotalActivityConfiguration: Codable {
    let totalScreenTime: TimeInterval
    let appUsageData: [AppUsageInfo]
    let hourlyBreakdown: [HourlyUsageData]
    
    var formattedTotalTime: String {
        let hours = Int(totalScreenTime) / 3600
        let minutes = Int(totalScreenTime) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var hasData: Bool {
        totalScreenTime > 0 || !appUsageData.isEmpty
    }
    
    var topApp: AppUsageInfo? {
        appUsageData.first
    }
    
    var activeHours: Int {
        hourlyBreakdown.filter { $0.hasUsage }.count
    }

    var isEmpty: Bool {
        totalScreenTime == 0 && appUsageData.isEmpty && hourlyBreakdown.allSatisfy { $0.isEmpty }
    }

    var averageHourlyUsage: Double {
        guard activeHours > 0 else { return 0 }
        return totalScreenTime / Double(activeHours) / 3600
    }

    var peakUsageHour: Int? {
        hourlyBreakdown.max(by: { $0.totalMinutes < $1.totalMinutes })?.hour
    }
}
