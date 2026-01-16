import Foundation
import SwiftUI
import Combine
import CoreData
import DeviceActivity

// MARK: - Screen Time Data Manager (Fixed Access Levels)
class ScreenTimeDataManager: ObservableObject {
    static let shared = ScreenTimeDataManager()
    
    // Published state for UI
    @Published var todayData: TotalActivityConfiguration?
    @Published var isLoading = false
    @Published var lastUpdateTime: Date?
    @Published var dataAge: TimeInterval = 0
    @Published var error: ScreenTimeError?
    
    // Cache configuration - made internal for access
    internal let maxCacheAge: TimeInterval = 300 // 5 minutes
    private let fallbackCacheAge: TimeInterval = 3600 // 1 hour for fallback
    private let userDefaults = UserDefaults.standard
    private let cacheKey = "cached_screen_time_data"
    private let timestampKey = "screen_time_data_timestamp"
    
    // Background refresh
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // DeviceActivityReport management
    private var reportKey = UUID()
    private var currentContext = DeviceActivityReport.Context(rawValue: "TotalActivity")
    private var currentFilter: DeviceActivityFilter
    
    private init() {
        // Initialize filter for today
        guard let todayInterval = Calendar.current.dateInterval(of: .day, for: .now) else {
            fatalError("Could not create today interval")
        }
        
        currentFilter = DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
        
        loadCachedData()
        setupBackgroundRefresh()
        setupAppLifecycleObservers()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Get screen time data - returns cached data immediately, refreshes in background
    func getScreenTimeData() async -> TotalActivityConfiguration {
        // Return cached data immediately if available and recent
        if let cachedData = todayData,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < maxCacheAge {
            print("✅ ScreenTimeDataManager: Returning fresh cached data")
            return cachedData
        }
        
        // If we have old cached data, return it while refreshing in background
        if let cachedData = todayData {
            print("⏰ ScreenTimeDataManager: Returning stale cached data, refreshing in background")
            
            // Trigger background refresh
            Task {
                await refreshDataFromExtension()
            }
            
            return cachedData
        }
        
        // No cached data - force refresh and wait
        print("🔄 ScreenTimeDataManager: No cached data, forcing refresh")
        await refreshDataFromExtension()
        
        return todayData ?? createEmptyConfiguration()
    }
    
    /// Force refresh data (for user-initiated refresh)
    func forceRefresh() async {
        print("🔄 ScreenTimeDataManager: Force refresh requested")
        await refreshDataFromExtension()
    }
    
    /// Cache data received from DeviceActivityReport (called by ScreenTimeView)
    func cacheReceivedData(_ configuration: TotalActivityConfiguration) {
        print("📥 ScreenTimeDataManager: Caching received data")
        
        // Update published properties
        todayData = configuration
        lastUpdateTime = Date()
        dataAge = 0
        error = nil
        
        // Cache the data
        cacheData(configuration)
        
        print("✅ ScreenTimeDataManager: Data cached successfully")
        updateDataAge()
    }
    
    /// Check if data is stale and needs refresh
    var isDataStale: Bool {
        guard let lastUpdate = lastUpdateTime else { return true }
        return Date().timeIntervalSince(lastUpdate) > maxCacheAge
    }
    
    /// Check if we have any usable data
    var hasData: Bool {
        return todayData != nil
    }
    
    // MARK: - Data Refreshing (Made Internal for Access)
    
    @MainActor
    internal func refreshDataFromExtension() async {
        guard !isLoading else {
            print("⏸️ ScreenTimeDataManager: Already loading, skipping")
            return
        }
        
        isLoading = true
        error = nil
        
        // Update filter to ensure we're getting today's data
        updateFilterForToday()
        
        // The actual refresh will happen when ScreenTimeView creates a new DeviceActivityReport
        // with the updated filter. We just trigger the UI to refresh.
        
        // For now, we simulate a refresh trigger by updating the report key
        reportKey = UUID()
        
        print("🔄 ScreenTimeDataManager: Triggered extension refresh with new report key: \(reportKey)")
        
        // The extension will process data and return it to the view
        // The view will then call cacheReceivedData() with the result
        
        // Set a timeout in case the extension never responds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if self.isLoading {
                self.isLoading = false
                self.error = .extensionTimeout
                print("❌ ScreenTimeDataManager: Extension timeout")
            }
        }
    }
    
    // MARK: - Filter Management
    
    private func updateFilterForToday() {
        guard let todayInterval = Calendar.current.dateInterval(of: .day, for: .now) else { return }
        
        let adjustedStart = Calendar.current.startOfDay(for: todayInterval.start)
        let adjustedEnd = Calendar.current.date(byAdding: .day, value: 1, to: adjustedStart)!
        let fullDayInterval = DateInterval(start: adjustedStart, end: adjustedEnd)
        
        currentFilter = DeviceActivityFilter(
            segment: .daily(during: fullDayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
        
        print("📅 Updated filter: \(fullDayInterval.start) to \(fullDayInterval.end)")
    }
    
    /// Get current filter for DeviceActivityReport
    func getCurrentFilter() -> DeviceActivityFilter {
        updateFilterForToday() // Ensure it's current
        return currentFilter
    }
    
    /// Get current report key for forcing refresh
    func getReportKey() -> UUID {
        return reportKey
    }
    
    /// Get current context
    func getContext() -> DeviceActivityReport.Context {
        return currentContext
    }
    
    // MARK: - Data Caching Implementation
    
    private func cacheData(_ data: TotalActivityConfiguration) {
        do {
            let encoded = try JSONEncoder().encode(CachedScreenTimeData(
                configuration: data,
                timestamp: Date(),
                version: "1.0"
            ))
            
            userDefaults.set(encoded, forKey: cacheKey)
            userDefaults.set(Date(), forKey: timestampKey)
            
            print("💾 ScreenTimeDataManager: Data cached successfully")
        } catch {
            print("❌ ScreenTimeDataManager: Failed to cache data - \(error)")
        }
    }
    
    private func loadCachedData() {
        guard let data = userDefaults.data(forKey: cacheKey),
              let timestamp = userDefaults.object(forKey: timestampKey) as? Date else {
            print("📭 ScreenTimeDataManager: No cached data found")
            return
        }
        
        do {
            let cachedData = try JSONDecoder().decode(CachedScreenTimeData.self, from: data)
            
            // Check if cache is still usable (within fallback age)
            let age = Date().timeIntervalSince(timestamp)
            if age < fallbackCacheAge {
                todayData = cachedData.configuration
                lastUpdateTime = timestamp
                dataAge = age
                
                print("📦 ScreenTimeDataManager: Loaded cached data (age: \(Int(age/60)) minutes)")
            } else {
                print("🗑️ ScreenTimeDataManager: Cached data too old, discarding")
                clearCache()
            }
        } catch {
            print("❌ ScreenTimeDataManager: Failed to decode cached data - \(error)")
            clearCache()
        }
    }
    
    private func clearCache() {
        userDefaults.removeObject(forKey: cacheKey)
        userDefaults.removeObject(forKey: timestampKey)
        todayData = nil
        lastUpdateTime = nil
        dataAge = 0
    }
    
    // MARK: - Background Refresh
    
    private func setupBackgroundRefresh() {
        // Refresh every 5 minutes when app is active
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            if self.isDataStale {
                Task {
                    await self.refreshDataFromExtension()
                }
            }
        }
    }
    
    private func setupAppLifecycleObservers() {
        // Refresh when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                if self.isDataStale {
                    Task {
                        await self.refreshDataFromExtension()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Update data age timer
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateDataAge()
        }
    }
    
    private func updateDataAge() {
        if let lastUpdate = lastUpdateTime {
            dataAge = Date().timeIntervalSince(lastUpdate)
        }
    }
    
    // MARK: - Helper Methods (Made Internal)
    
    internal func createEmptyConfiguration() -> TotalActivityConfiguration {
        return TotalActivityConfiguration(
            totalScreenTime: 0,
            appUsageData: [],
            hourlyBreakdown: Array(0...23).map { hour in
                HourlyUsageData(hour: hour, totalMinutes: 0, apps: [])
            }
        )
    }
    
    // MARK: - Status Properties
    
    var statusMessage: String {
        if isLoading {
            return "Updating..."
        } else if let lastUpdate = lastUpdateTime {
            let minutes = Int(dataAge / 60)
            if minutes < 5 {
                return "Updated \(minutes) min ago"
            } else {
                return "Updated \(lastUpdate.formatted(date: .omitted, time: .shortened))"
            }
        } else {
            return "No data"
        }
    }
    
    var needsRefresh: Bool {
        return isDataStale || todayData == nil
    }
    
    func markLoadingComplete() {
        isLoading = false
    }
    
    /// Enhanced data loading with memory management
    func getScreenTimeDataOptimized() async -> TotalActivityConfiguration {
        if let cachedData = todayData,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < maxCacheAge {
            return cachedData
        }
        
        // Force a refresh through the extension
        await refreshDataFromExtension()
        
        return todayData ?? createEmptyConfiguration()
    }
    
    /// Listen for extension data updates
    func setupExtensionDataListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ScreenTimeExtensionDataReady"),
            object: nil,
            queue: .main
        ) { notification in
            if let configuration = notification.object as? TotalActivityConfiguration {
                self.cacheReceivedData(configuration)
            }
        }
    }
}

// MARK: - Supporting Types

struct CachedScreenTimeData: Codable {
    let configuration: TotalActivityConfiguration
    let timestamp: Date
    let version: String
}

enum ScreenTimeError: Error, LocalizedError {
    case extensionTimeout
    case invalidData
    case refreshFailed(String)
    case cacheCorrupted
    
    var errorDescription: String? {
        switch self {
        case .extensionTimeout:
            return "Extension took too long to respond"
        case .invalidData:
            return "Invalid data received from extension"
        case .refreshFailed(let message):
            return "Refresh failed: \(message)"
        case .cacheCorrupted:
            return "Cached data is corrupted"
        }
    }
}
