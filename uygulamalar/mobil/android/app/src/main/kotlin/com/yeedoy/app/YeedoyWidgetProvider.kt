package com.yeedoy.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

class YeedoyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val businessName = prefs.getString("widget_business_name", null)
            val subtitle = prefs.getString("widget_subtitle", null)

            val views = RemoteViews(context.packageName, R.layout.widget_nearby)

            if (businessName != null) {
                views.setTextViewText(R.id.widget_business_name, businessName)
            }
            if (subtitle != null) {
                views.setTextViewText(R.id.widget_subtitle, subtitle)
            }

            // Tap opens the app at /discover
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/discover")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_business_name, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_subtitle, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_app_name, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
