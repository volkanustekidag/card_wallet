package com.volkan.wallet_app

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle

/**
 * Card chooser for [PinnedCardWidgetReceiver]: a plain list of the
 * loyalty cards that have a barcode, A–Z, as the app publishes them in
 * `cw_all_cards`. Opens when the widget is placed, from the widget's
 * settings, and from an empty widget.
 */
class PinnedCardConfigureActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        // Backing out of the chooser while placing cancels the widget.
        setResult(RESULT_CANCELED, resultIntent())
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val cards = parseNames(
            getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .getString("cw_all_cards", null),
        )
        val builder = AlertDialog.Builder(this, dialogTheme())
            .setOnCancelListener { finish() }
        if (cards.isEmpty()) {
            builder.setTitle(R.string.pinned_widget_none_title)
                .setMessage(R.string.pinned_widget_none_body)
                .setPositiveButton(R.string.pinned_widget_open_app) { _, _ ->
                    packageManager.getLaunchIntentForPackage(packageName)?.let {
                        startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    }
                    finish()
                }
                .setNegativeButton(android.R.string.cancel) { _, _ -> finish() }
        } else {
            val current = PinnedCardWidgetReceiver.chosenCard(this, widgetId)
            builder.setTitle(R.string.pinned_widget_choose)
                .setSingleChoiceItems(
                    cards.map { it.second }.toTypedArray(),
                    cards.indexOfFirst { it.first == current },
                ) { dialog, which ->
                    PinnedCardWidgetReceiver.choose(this, widgetId, cards[which].first)
                    setResult(RESULT_OK, resultIntent())
                    dialog.dismiss()
                    finish()
                }
                .setNegativeButton(android.R.string.cancel) { _, _ -> finish() }
        }
        builder.show()
    }

    private fun resultIntent() =
        Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)

    private fun dialogTheme(): Int {
        val night = resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        return if (night) android.R.style.Theme_DeviceDefault_Dialog_Alert
        else android.R.style.Theme_DeviceDefault_Light_Dialog_Alert
    }

    /** (id, name) pairs from the published card list. */
    private fun parseNames(raw: String?): List<Pair<String, String>> {
        if (raw.isNullOrEmpty()) return emptyList()
        return try {
            val arr = org.json.JSONArray(raw)
            (0 until arr.length()).map {
                val c = arr.getJSONObject(it)
                c.optString("id") to c.optString("name")
            }.filter { it.first.isNotEmpty() }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
