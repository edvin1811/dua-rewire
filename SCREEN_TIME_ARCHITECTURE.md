# Screen Time Data Architecture

## Understanding DeviceActivity Sandboxing

### The Problem
DeviceActivity framework data is **sandboxed** and cannot be accessed directly from the main app target. Only the ActivityMonitor extension has access to raw screen time data.

### The Solution
Use **DeviceActivityReport** to embed views from the ActivityMonitor extension into the main app.

## Architecture Flow

```
┌─────────────────────────────────────────────────────────┐
│                      Main App                           │
│  ┌────────────────────────────────────────────────┐    │
│  │  AccountView.swift                              │    │
│  │  - Profile (✅ local data)                      │    │
│  │  - Goals (✅ StatisticsManager - UserDefaults)  │    │
│  │  - DeviceActivityReport embed ───────────────┐  │    │
│  │  - Feature requests (✅ local)                │  │    │
│  └────────────────────────────────────────────────┘  │    │
└─────────────────────────────────────────────────────┼────┘
                                                       │
                                                       │ Renders
                                                       ▼
┌─────────────────────────────────────────────────────────┐
│              ActivityMonitor Extension                  │
│  ┌────────────────────────────────────────────────┐    │
│  │  AccountActivityView.swift                      │    │
│  │  - Real screen time data (✅ DeviceActivity)    │    │
│  │  - Today's usage stats                          │    │
│  │  - Hourly breakdown                             │    │
│  │  - Most used apps                               │    │
│  └────────────────────────────────────────────────┘    │
│                                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │  AccountActivityReport.swift                    │    │
│  │  makeConfiguration() → TotalActivityConfiguration│    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Files Created/Modified

### ✅ ActivityMonitor Target (Has Screen Time Access)

**Created:**
- `/ActivityMonitor/AccountActivityView.swift` - UI that displays screen time data
  - Today's usage statistics
  - Daily/Weekly/Trends insights tabs
  - Most used apps list
  - Peak hour indicator

**Modified:**
- `/ActivityMonitor/ActivityMonitor.swift` - Added `AccountActivityReport` scene
  - Processes DeviceActivity data
  - Creates hourly breakdown
  - Extracts app usage information
  - Returns `TotalActivityConfiguration`

### ✅ Main App Target (No Direct Screen Time Access)

**Modified:**
- `/sharp/account/AccountView.swift`
  - Removed local screen time stat rows (❌ won't work - no data access)
  - Removed insights tabs with local data (❌ won't work)
  - Added `DeviceActivityReport` embed (✅ works - renders from extension)
  - Kept profile, goals, and feedback features (✅ works - local data)

## What Works vs What Doesn't

### ✅ Main App CAN Access:
- **StatisticsManager data** (UserDefaults-based):
  - `dailyGoal`
  - `focusScore` (calculated from cached data)
  - `goalMetStreak`
  - `goalMetDaysThisWeek`
  - `weeklyAverage` (from cached daily totals)
  - `timeSavedThisWeek`

### ❌ Main App CANNOT Access:
- **Real-time DeviceActivity data**:
  - Current screen time breakdown
  - Hourly usage data
  - Individual app usage today
  - Peak usage hour
  - Active hours count

### ✅ ActivityMonitor Extension CAN Access:
- **Everything** via `DeviceActivityResults<DeviceActivityData>`:
  - Real-time screen time
  - Per-app usage
  - Hourly breakdown
  - Activity segments
  - Categories

## Data Flow Example

### Correct Approach (What We Did):

```swift
// 1. Main App (AccountView.swift)
DeviceActivityReport(
    DeviceActivityReport.Context(rawValue: "AccountActivity"),
    filter: getCurrentFilter()
)

// 2. ActivityMonitor (ActivityMonitor.swift)
AccountActivityReport { configuration in
    return AccountActivityView(configuration: configuration)
}

// 3. ActivityMonitor (AccountActivityView.swift)
struct AccountActivityView: View {
    let configuration: TotalActivityConfiguration
    // ✅ Has access to real screen time data!
}
```

### Wrong Approach (What We Initially Did):

```swift
// ❌ WRONG - Main app trying to access screen time directly
struct AccountView: View {
    @StateObject private var statisticsManager = StatisticsManager.shared

    var body: some View {
        Text(statisticsManager.todayScreenTime) // ❌ Only has cached data
        Text("Apps used: \(appUsageData.count)") // ❌ No access to this!
    }
}
```

## Best Practices

### 1. **Use DeviceActivityReport for Screen Time UI**
Always create views in the ActivityMonitor target and embed them using `DeviceActivityReport`.

### 2. **Use StatisticsManager for App-Wide Metrics**
Store processed data in UserDefaults for access throughout the app:
- Daily goals
- Streaks
- Historical averages
- Focus scores (calculated from cached totals)

### 3. **Cache Screen Time Data**
Use `ScreenTimeDataManager` to cache `TotalActivityConfiguration`:
```swift
// Main app can use cached data (not real-time)
screenTimeDataManager.todayData?.totalScreenTime
```

### 4. **Separate Concerns**
- **ActivityMonitor**: Real-time screen time display
- **Main App**: User profile, goals, settings, navigation
- **StatisticsManager**: Historical tracking and calculations

## Common Errors & Fixes

### Error: "No screen time data in AccountView"
**Cause**: Trying to access DeviceActivity data from main app
**Fix**: Create view in ActivityMonitor and embed with DeviceActivityReport

### Error: "Cannot infer type of DeviceActivityReport.Context"
**Cause**: Context string doesn't match extension
**Fix**: Use exact same string in both places:
```swift
// Main app
DeviceActivityReport.Context(rawValue: "AccountActivity")

// Extension
let context: DeviceActivityReport.Context = .init(rawValue: "AccountActivity")
```

### Error: "Stats show 0 even though I used my phone"
**Cause**: DeviceActivity data hasn't been processed yet
**Fix**: Data updates every 15-60 minutes. This is expected behavior.

## Future Improvements

1. **Add More Report Scenes**
   - Weekly summary report
   - Monthly trends report
   - Category-specific reports

2. **Enhance Data Processing**
   - Better hourly breakdown accuracy
   - Category classification
   - App productivity scores

3. **Optimize Performance**
   - Reduce memory usage in extension
   - Implement incremental updates
   - Add data pagination

## Summary

✅ **Screen time insights now working correctly**
- AccountView embeds DeviceActivityReport
- AccountActivityView (in ActivityMonitor) has access to real data
- Profile and goals still use app-wide StatisticsManager data
- Clean separation between sandboxed and non-sandboxed data

❌ **Previous mistake fixed**
- No longer trying to access screen time data from main app
- Removed fake statistics that had no real data
- Proper architecture following Apple's DeviceActivity framework

---

**Key Takeaway**: If you need to display screen time data, create the view in the **ActivityMonitor target** and embed it using **DeviceActivityReport**. Never try to access DeviceActivity data directly from the main app.
