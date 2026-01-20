package com.unwire.focus.usagestats

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import com.facebook.react.bridge.*
import java.util.*

class UsageStatsModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private val usageStatsManager: UsageStatsManager by lazy {
        reactContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }

    override fun getName(): String = "UsageStatsModule"

    /**
     * Check if usage stats permission is granted
     */
    @ReactMethod
    fun hasPermission(promise: Promise) {
        try {
            val appOps = reactContext.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    reactContext.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    reactContext.packageName
                )
            }
            promise.resolve(mode == AppOpsManager.MODE_ALLOWED)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Open system settings for usage access permission
     */
    @ReactMethod
    fun requestPermission(promise: Promise) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            reactContext.startActivity(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Get usage stats for today
     */
    @ReactMethod
    fun getTodayUsage(promise: Promise) {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            val result = Arguments.createArray()
            val packageManager = reactContext.packageManager

            stats?.filter { it.totalTimeInForeground > 0 }
                ?.sortedByDescending { it.totalTimeInForeground }
                ?.forEach { stat ->
                    val appInfo = Arguments.createMap().apply {
                        putString("packageName", stat.packageName)
                        putDouble("usageTimeMs", stat.totalTimeInForeground.toDouble())
                        putDouble("usageTimeMinutes", (stat.totalTimeInForeground / 60000.0))
                        putDouble("lastUsed", stat.lastTimeUsed.toDouble())

                        // Try to get app name
                        try {
                            val appName = packageManager.getApplicationLabel(
                                packageManager.getApplicationInfo(stat.packageName, 0)
                            ).toString()
                            putString("appName", appName)
                        } catch (e: PackageManager.NameNotFoundException) {
                            putString("appName", stat.packageName)
                        }
                    }
                    result.pushMap(appInfo)
                }

            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Get usage stats for a specific date range
     */
    @ReactMethod
    fun getUsageForRange(startTimeMs: Double, endTimeMs: Double, promise: Promise) {
        try {
            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTimeMs.toLong(),
                endTimeMs.toLong()
            )

            val result = Arguments.createArray()
            val packageManager = reactContext.packageManager

            stats?.filter { it.totalTimeInForeground > 0 }
                ?.sortedByDescending { it.totalTimeInForeground }
                ?.forEach { stat ->
                    val appInfo = Arguments.createMap().apply {
                        putString("packageName", stat.packageName)
                        putDouble("usageTimeMs", stat.totalTimeInForeground.toDouble())
                        putDouble("usageTimeMinutes", (stat.totalTimeInForeground / 60000.0))
                        putDouble("lastUsed", stat.lastTimeUsed.toDouble())

                        try {
                            val appName = packageManager.getApplicationLabel(
                                packageManager.getApplicationInfo(stat.packageName, 0)
                            ).toString()
                            putString("appName", appName)
                        } catch (e: PackageManager.NameNotFoundException) {
                            putString("appName", stat.packageName)
                        }
                    }
                    result.pushMap(appInfo)
                }

            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Get total screen time for today in minutes
     */
    @ReactMethod
    fun getTodayScreenTime(promise: Promise) {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            var totalTimeMs = 0L
            stats?.forEach { stat ->
                totalTimeMs += stat.totalTimeInForeground
            }

            val result = Arguments.createMap().apply {
                putDouble("totalTimeMs", totalTimeMs.toDouble())
                putDouble("totalTimeMinutes", (totalTimeMs / 60000.0))
                putDouble("totalTimeHours", (totalTimeMs / 3600000.0))
            }

            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Get app launch count for today
     */
    @ReactMethod
    fun getTodayLaunchCount(promise: Promise) {
        try {
            val calendar = Calendar.getInstance()
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()

            val events = usageStatsManager.queryEvents(startTime, endTime)
            val launchCounts = mutableMapOf<String, Int>()
            val event = UsageEvents.Event()

            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    val count = launchCounts[event.packageName] ?: 0
                    launchCounts[event.packageName] = count + 1
                }
            }

            val result = Arguments.createMap()
            launchCounts.forEach { (packageName, count) ->
                result.putInt(packageName, count)
            }

            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    /**
     * Get weekly usage summary
     */
    @ReactMethod
    fun getWeeklyUsage(promise: Promise) {
        try {
            val calendar = Calendar.getInstance()
            val endTime = System.currentTimeMillis()

            // Go back 7 days
            calendar.add(Calendar.DAY_OF_YEAR, -7)
            val startTime = calendar.timeInMillis

            val stats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            // Aggregate by day
            val dailyUsage = mutableMapOf<String, Long>()

            stats?.forEach { stat ->
                val day = Calendar.getInstance().apply {
                    timeInMillis = stat.lastTimeUsed
                }.let { cal ->
                    "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.MONTH) + 1}-${cal.get(Calendar.DAY_OF_MONTH)}"
                }

                val current = dailyUsage[day] ?: 0L
                dailyUsage[day] = current + stat.totalTimeInForeground
            }

            val result = Arguments.createArray()
            dailyUsage.toList()
                .sortedBy { it.first }
                .forEach { (day, timeMs) ->
                    val dayInfo = Arguments.createMap().apply {
                        putString("date", day)
                        putDouble("usageTimeMs", timeMs.toDouble())
                        putDouble("usageTimeMinutes", (timeMs / 60000.0))
                        putDouble("usageTimeHours", (timeMs / 3600000.0))
                    }
                    result.pushMap(dayInfo)
                }

            promise.resolve(result)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }
}
