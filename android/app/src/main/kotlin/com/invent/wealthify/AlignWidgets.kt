package com.invent.wealthify

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.abs

internal fun prefs(context: Context): SharedPreferences =
    context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

internal fun launchPendingIntent(context: Context, screen: String) =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("align://widget?homeWidget=$screen"),
    )

internal fun pushUpdate(
    context: Context,
    manager: AppWidgetManager,
    ids: IntArray,
    views: RemoteViews,
) {
    ids.forEach { manager.updateAppWidget(it, views) }
}

class AlignBalanceWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = prefs(context)
        val views = RemoteViews(context.packageName, R.layout.align_balance_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_container,
                launchPendingIntent(context, "balance"),
            )
            setTextViewText(
                R.id.widget_balance,
                data.getString("align_balance_text", null) ?: "—",
            )
            setTextViewText(
                R.id.widget_balance_sub,
                data.getString("align_balance_sub", null) ?: "Open Align to sync",
            )
            setTextViewText(
                R.id.widget_spent,
                data.getString("align_spent_text", null) ?: "—",
            )
            setTextViewText(
                R.id.widget_spent_of,
                data.getString("align_spent_of", null) ?: "—",
            )
            setProgressBar(
                R.id.widget_spent_bar,
                100,
                data.getInt("align_spent_progress", 0),
                false,
            )
        }
        pushUpdate(context, appWidgetManager, appWidgetIds, views)
    }
}

class AlignBudgetWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = prefs(context)
        val rows = (data.getString("align_budget_rows", null) ?: "")
            .split(";")
            .mapNotNull { row ->
                val parts = row.split("|")
                if (parts.size != 3) null
                else Triple(parts[0], parts[1].toDoubleOrNull() ?: 0.0, parts[2].toDoubleOrNull() ?: 0.0)
            }
            .take(3)
        val views = RemoteViews(context.packageName, R.layout.align_budget_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_container,
                launchPendingIntent(context, "budgets"),
            )
            val nameIds = intArrayOf(
                R.id.widget_row_0_name, R.id.widget_row_1_name, R.id.widget_row_2_name,
            )
            val leftIds = intArrayOf(
                R.id.widget_row_0_left, R.id.widget_row_1_left, R.id.widget_row_2_left,
            )
            val barIds = intArrayOf(
                R.id.widget_row_0_bar, R.id.widget_row_1_bar, R.id.widget_row_2_bar,
            )
            val rowIds = intArrayOf(
                R.id.widget_row_0, R.id.widget_row_1, R.id.widget_row_2,
            )
            for (i in 0 until 3) {
                val row = rows.getOrNull(i)
                if (row == null) {
                    setViewVisibility(rowIds[i], android.view.View.GONE)
                    continue
                }
                setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                val (name, spent, limit) = row
                setTextViewText(nameIds[i], name)
                val remaining = limit - spent
                setTextViewText(
                    leftIds[i],
                    if (remaining < 0) "${fmt(abs(remaining))} over" else "${fmt(remaining)} left",
                )
                val pct = if (limit <= 0) 0 else ((spent / limit) * 100).toInt().coerceIn(0, 100)
                setProgressBar(barIds[i], 100, pct, false)
            }
        }
        pushUpdate(context, appWidgetManager, appWidgetIds, views)
    }

    private fun fmt(v: Double): String =
        if (v % 1.0 == 0.0) v.toLong().toString() else "%.1f".format(v)
}

class AlignCaloriesWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = prefs(context)
        val views = RemoteViews(context.packageName, R.layout.align_calories_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_container,
                launchPendingIntent(context, "calories"),
            )
            val consumed = data.getInt("align_cal_consumed", 0)
            val target = data.getInt("align_cal_target", 0)
            val left = data.getInt("align_cal_left", 0)
            setTextViewText(R.id.widget_cal_consumed, "$consumed")
            setTextViewText(
                R.id.widget_cal_left,
                if (target <= 0) "" else if (left < 0) "${-left} over" else "$left left",
            )
            setProgressBar(
                R.id.widget_cal_bar,
                100,
                data.getInt("align_cal_progress", 0),
                false,
            )
            setTextViewText(
                R.id.widget_macro_protein,
                "P ${data.getInt("align_cal_protein", 0)}/${data.getInt("align_cal_protein_target", 0)}g",
            )
            setTextViewText(
                R.id.widget_macro_carbs,
                "C ${data.getInt("align_cal_carbs", 0)}/${data.getInt("align_cal_carbs_target", 0)}g",
            )
            setTextViewText(
                R.id.widget_macro_fat,
                "F ${data.getInt("align_cal_fat", 0)}/${data.getInt("align_cal_fat_target", 0)}g",
            )
        }
        pushUpdate(context, appWidgetManager, appWidgetIds, views)
    }
}

class AlignFitnessWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = prefs(context)
        val views = RemoteViews(context.packageName, R.layout.align_fitness_widget).apply {
            setOnClickPendingIntent(
                R.id.widget_container,
                launchPendingIntent(context, "fitness"),
            )
            setTextViewText(
                R.id.widget_fit_minutes,
                "${data.getInt("align_fit_minutes", 0)}",
            )
            setTextViewText(
                R.id.widget_fit_today,
                data.getString("align_fit_today_label", null) ?: "",
            )
            setTextViewText(
                R.id.widget_fit_workouts,
                "${data.getInt("align_fit_workouts", 0)} workouts",
            )
            setTextViewText(
                R.id.widget_fit_sets,
                "${data.getInt("align_fit_sets", 0)} sets",
            )
            setTextViewText(
                R.id.widget_fit_volume,
                data.getString("align_fit_volume", null) ?: "0 kg",
            )
        }
        pushUpdate(context, appWidgetManager, appWidgetIds, views)
    }
}
