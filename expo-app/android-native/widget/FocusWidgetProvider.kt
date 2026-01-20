package com.unwire.focus.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.graphics.Color
import android.os.Build

/**
 * Focus Widget Provider for Android Home Screen
 * Displays focus time, streak, and quick actions
 */
class FocusWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Called when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
    }

    companion object {
        private const val PREFS_NAME = "com.unwire.focus.widget"
        private const val KEY_FOCUS_MINUTES = "focusMinutes"
        private const val KEY_STREAK_DAYS = "streakDays"
        private const val KEY_BLOCKED_APPS = "blockedApps"
        private const val KEY_IS_FOCUSING = "isFocusing"
        private const val KEY_DAILY_GOAL = "dailyGoal"

        /**
         * Update widget data from React Native
         */
        fun updateWidgetData(
            context: Context,
            focusMinutes: Int,
            streakDays: Int,
            blockedApps: Int,
            isFocusing: Boolean,
            dailyGoal: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putInt(KEY_FOCUS_MINUTES, focusMinutes)
                putInt(KEY_STREAK_DAYS, streakDays)
                putInt(KEY_BLOCKED_APPS, blockedApps)
                putBoolean(KEY_IS_FOCUSING, isFocusing)
                putInt(KEY_DAILY_GOAL, dailyGoal)
                apply()
            }

            // Trigger widget update
            val intent = Intent(context, FocusWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            context.sendBroadcast(intent)
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get stored data
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val focusMinutes = prefs.getInt(KEY_FOCUS_MINUTES, 0)
            val streakDays = prefs.getInt(KEY_STREAK_DAYS, 0)
            val blockedApps = prefs.getInt(KEY_BLOCKED_APPS, 0)
            val isFocusing = prefs.getBoolean(KEY_IS_FOCUSING, false)
            val dailyGoal = prefs.getInt(KEY_DAILY_GOAL, 180)

            val progress = (focusMinutes.toFloat() / dailyGoal.toFloat() * 100).toInt()

            // Create RemoteViews
            val views = RemoteViews(context.packageName, getLayoutId(context))

            // Update text views
            views.setTextViewText(getId(context, "focus_minutes"), "$focusMinutes")
            views.setTextViewText(getId(context, "streak_count"), "$streakDays")
            views.setTextViewText(getId(context, "blocked_count"), "$blockedApps")
            views.setTextViewText(getId(context, "progress_percent"), "$progress%")

            // Update focus status
            if (isFocusing) {
                views.setTextViewText(getId(context, "focus_status"), "Focusing")
                views.setInt(getId(context, "focus_status"), "setTextColor", Color.parseColor("#58CC02"))
            } else {
                views.setTextViewText(getId(context, "focus_status"), "Ready")
                views.setInt(getId(context, "focus_status"), "setTextColor", Color.parseColor("#AFAFAF"))
            }

            // Set up click intent to open app
            val pendingIntent = createOpenAppIntent(context)
            views.setOnClickPendingIntent(getId(context, "widget_container"), pendingIntent)

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun createOpenAppIntent(context: Context): PendingIntent {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent()
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            return PendingIntent.getActivity(context, 0, intent, flags)
        }

        private fun getLayoutId(context: Context): Int {
            return context.resources.getIdentifier(
                "focus_widget_layout",
                "layout",
                context.packageName
            )
        }

        private fun getId(context: Context, name: String): Int {
            return context.resources.getIdentifier(name, "id", context.packageName)
        }
    }
}
