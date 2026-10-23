package com.volkan.wallet_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

/**
 * "Pinned card" widget: always the one card the user chose for it, where
 * the Up Next widget follows usage. The card is picked in
 * [PinnedCardConfigureActivity] when the widget is placed (and again
 * from the widget's settings on Android 12+, or by tapping it once its
 * card is gone). Cards come from `cw_all_cards`, the same list the iOS
 * pinned widget reads.
 */
class PinnedCardWidgetReceiver : LoyaltyWidgetReceiver() {

    override fun cardsFor(
        context: Context,
        prefs: SharedPreferences,
        widgetId: Int,
    ): List<WidgetCard> {
        val id = chosenCard(context, widgetId) ?: return emptyList()
        return parseCards(prefs.getString("cw_all_cards", null))
            .filter { it.id == id }
    }

    override fun label(prefs: SharedPreferences): String? = null

    override fun emptyTitle(context: Context, prefs: SharedPreferences, widgetId: Int): String =
        context.getString(R.string.pinned_widget_choose)

    override fun emptyTapIntent(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, PinnedCardConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            // One task per widget id, so two widgets don't share an intent.
            data = android.net.Uri.parse("cardwallet-widget://pinned/$widgetId")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return PendingIntent.getActivity(
            context,
            widgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val edit = choices(context).edit()
        for (id in appWidgetIds) edit.remove(key(id))
        edit.apply()
    }

    companion object {
        private fun choices(context: Context): SharedPreferences =
            context.getSharedPreferences("PinnedWidgets", Context.MODE_PRIVATE)

        private fun key(widgetId: Int) = "card_$widgetId"

        fun chosenCard(context: Context, widgetId: Int): String? =
            choices(context).getString(key(widgetId), null)

        fun choose(context: Context, widgetId: Int, cardId: String) {
            choices(context).edit().putString(key(widgetId), cardId).apply()
            val intent = Intent(context, PinnedCardWidgetReceiver::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            }
            context.sendBroadcast(intent)
        }

    }
}
