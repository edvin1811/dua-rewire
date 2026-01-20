package com.unwire.focus.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class WidgetModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "WidgetModule"

    /**
     * Update widget data from React Native
     */
    @ReactMethod
    fun updateWidgetData(
        focusMinutes: Int,
        streakDays: Int,
        blockedApps: Int,
        isFocusing: Boolean,
        dailyGoalMinutes: Int
    ) {
        FocusWidgetProvider.updateWidgetData(
            reactContext,
            focusMinutes,
            streakDays,
            blockedApps,
            isFocusing,
            dailyGoalMinutes
        )

        // Trigger widget update
        requestWidgetUpdate()
    }

    /**
     * Request all widgets to update
     */
    @ReactMethod
    fun requestWidgetUpdate() {
        val appWidgetManager = AppWidgetManager.getInstance(reactContext)
        val componentName = ComponentName(reactContext, FocusWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        if (appWidgetIds.isNotEmpty()) {
            val intent = Intent(reactContext, FocusWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            reactContext.sendBroadcast(intent)
        }
    }
}
