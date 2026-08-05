package com.example.planner_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DuckWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.duck_widget).apply {
                val duckLevel = widgetData.getString("duck_level", "Lv.1")
                val duckStreak = widgetData.getString("duck_streak", "🔥 1d")
                val task1 = widgetData.getString("task_1", "🎉 Không có việc dồn!")
                val task2 = widgetData.getString("task_2", "")
                val task3 = widgetData.getString("task_3", "")

                setTextViewText(R.id.duck_level, "$duckLevel $duckStreak")
                setTextViewText(R.id.task_1, task1)
                setTextViewText(R.id.task_2, task2)
                setTextViewText(R.id.task_3, task3)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
