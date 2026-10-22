package com.volkan.wallet_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.google.zxing.BarcodeFormat
import com.google.zxing.MultiFormatWriter
import com.google.zxing.WriterException

/**
 * AppWidgetProvider for the loyalty card home-screen widget.
 *
 * Reads the snapshot written by the Flutter side via the `home_widget`
 * plugin (which on Android persists to the default `SharedPreferences`
 * of the host app) and renders it as a [RemoteViews] tree. Tapping the
 * widget fires the `cardwallet://loyalty?id=<id>` deep link, which the
 * Dart-side `WidgetDeepLinkHandler` routes to the barcode page —
 * bypassing the PIN gate, since loyalty barcodes are designed to be
 * displayed in public anyway.
 *
 * Update lifecycle:
 *  - The widget self-updates only when [onUpdate] is invoked. The
 *    `updatePeriodMillis` in the provider XML is set to 0, so the system
 *    won't wake us periodically. The Flutter side triggers updates by
 *    calling `HomeWidget.updateWidget(...)` whenever the user opens a
 *    loyalty card or deletes the cached one.
 */
class LoyaltyWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = sharedPrefs(context)
        for (id in appWidgetIds) {
            val wide = isWide(appWidgetManager, id)
            appWidgetManager.updateAppWidget(id, buildRemoteViews(context, prefs, wide))
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle,
    ) {
        val wide = isWide(appWidgetManager, appWidgetId)
        appWidgetManager.updateAppWidget(
            appWidgetId,
            buildRemoteViews(context, sharedPrefs(context), wide),
        )
    }

    private fun isWide(manager: AppWidgetManager, id: Int): Boolean {
        val options = manager.getAppWidgetOptions(id)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        return minWidth >= 280
    }

    /** One card from the `cw_cards` JSON the app publishes. */
    private data class WidgetCard(
        val id: String,
        val name: String,
        val barcode: String,
        val format: String,
        val bg: Int,
        val bg2: Int,
        val fg: Int,
        val image: String?,
    )

    /**
     * Cards for this moment: the `cw_timeline` slot covering now (hourly,
     * published by the app for the next 24 h), best guess first. Falls back
     * to the legacy single-card keys.
     */
    private fun currentCards(prefs: SharedPreferences): List<WidgetCard> {
        try {
            val cardsRaw = prefs.getString("cw_cards", null)
            val timelineRaw = prefs.getString("cw_timeline", null)
            if (!cardsRaw.isNullOrEmpty() && !timelineRaw.isNullOrEmpty()) {
                val byId = HashMap<String, WidgetCard>()
                val cards = org.json.JSONArray(cardsRaw)
                for (i in 0 until cards.length()) {
                    val c = cards.getJSONObject(i)
                    val card = WidgetCard(
                        id = c.optString("id"),
                        name = c.optString("name"),
                        barcode = c.optString("barcode"),
                        format = c.optString("format"),
                        bg = parseHex(c.optString("bg")) ?: Color.parseColor("#22252C"),
                        bg2 = parseHex(c.optString("bg2")) ?: Color.parseColor("#0B0C0F"),
                        fg = parseHex(c.optString("fg")) ?: Color.WHITE,
                        image = c.optString("img").takeIf { it.isNotEmpty() && it != "null" },
                    )
                    byId[card.id] = card
                }
                val slots = org.json.JSONArray(timelineRaw)
                val now = System.currentTimeMillis() / 1000
                var chosen: org.json.JSONArray? = null
                for (i in 0 until slots.length()) {
                    val slot = slots.getJSONObject(i)
                    if (slot.optLong("t") <= now || chosen == null) {
                        chosen = slot.optJSONArray("ids")
                    }
                    if (slot.optLong("t") > now) break
                }
                val result = ArrayList<WidgetCard>()
                if (chosen != null) {
                    for (i in 0 until chosen.length()) {
                        byId[chosen.optString(i)]?.let { result.add(it) }
                    }
                }
                if (result.isNotEmpty()) return result
            }
        } catch (_: Exception) {
            // Malformed data: fall through to the legacy keys.
        }
        val id = prefs.getString(KEY_ID, "").orEmpty()
        val barcode = prefs.getString(KEY_BARCODE, "").orEmpty()
        if (id.isEmpty() || barcode.isEmpty()) return emptyList()
        val name = prefs.getString(KEY_NAME, "").orEmpty()
        return listOf(
            WidgetCard(
                id = id,
                name = name.ifEmpty { prefs.getString(KEY_BRAND, "").orEmpty() },
                barcode = barcode,
                format = prefs.getString(KEY_FORMAT, "").orEmpty(),
                bg = parseHex(prefs.getString(KEY_COLOR1, "")) ?: Color.parseColor("#1F2937"),
                bg2 = parseHex(prefs.getString(KEY_COLOR2, "")) ?: Color.parseColor("#111827"),
                fg = Color.WHITE,
                image = null,
            ),
        )
    }

    private fun buildRemoteViews(
        context: Context,
        prefs: SharedPreferences,
        wide: Boolean,
    ): RemoteViews {
        val layout = if (wide) R.layout.loyalty_widget_wide else R.layout.loyalty_widget
        val views = RemoteViews(context.packageName, layout)
        val cards = currentCards(prefs)
        val top = cards.firstOrNull()

        views.setImageViewBitmap(
            R.id.loyalty_widget_background,
            gradientBitmap(
                top?.bg ?: Color.parseColor("#22252C"),
                top?.bg2 ?: Color.parseColor("#0B0C0F"),
                if (wide) 800 else 400,
                400,
            ),
        )

        if (top == null) {
            views.setTextViewText(R.id.loyalty_widget_title, context.getString(R.string.loyalty_add_card))
            views.setImageViewBitmap(R.id.loyalty_widget_barcode, placeholderBitmap())
            views.setOnClickPendingIntent(
                R.id.loyalty_widget_root,
                buildDeepLinkPendingIntent(context, "cardwallet://loyalty"),
            )
            if (wide) hideRows(views)
            return views
        }

        views.setTextColor(R.id.loyalty_widget_title, top.fg)
        views.setTextColor(R.id.loyalty_widget_label, (top.fg and 0x00FFFFFF) or 0xB3000000.toInt())
        views.setTextViewText(R.id.loyalty_widget_title, top.name)
        val bitmap = top.image?.let { android.graphics.BitmapFactory.decodeFile(it) }
            ?: renderBarcode(top.barcode, top.format)
            ?: placeholderBitmap()
        views.setImageViewBitmap(R.id.loyalty_widget_barcode, bitmap)
        views.setOnClickPendingIntent(
            R.id.loyalty_widget_root,
            buildDeepLinkPendingIntent(context, "cardwallet://loyalty?id=${top.id}"),
        )

        if (wide) {
            val rows = intArrayOf(
                R.id.loyalty_widget_row1,
                R.id.loyalty_widget_row2,
                R.id.loyalty_widget_row3,
            )
            val others = cards.drop(1)
            for ((i, rowId) in rows.withIndex()) {
                val card = others.getOrNull(i)
                if (card == null) {
                    views.setViewVisibility(rowId, android.view.View.INVISIBLE)
                    continue
                }
                views.setViewVisibility(rowId, android.view.View.VISIBLE)
                views.setTextViewText(rowId, card.name)
                views.setTextColor(rowId, top.fg)
                views.setOnClickPendingIntent(
                    rowId,
                    buildDeepLinkPendingIntent(context, "cardwallet://loyalty?id=${card.id}"),
                )
            }
            views.setOnClickPendingIntent(
                R.id.loyalty_widget_main,
                buildDeepLinkPendingIntent(context, "cardwallet://loyalty?id=${top.id}"),
            )
        }
        return views
    }

    private fun hideRows(views: RemoteViews) {
        for (rowId in intArrayOf(
            R.id.loyalty_widget_row1,
            R.id.loyalty_widget_row2,
            R.id.loyalty_widget_row3,
        )) {
            views.setViewVisibility(rowId, android.view.View.INVISIBLE)
        }
    }

    /**
     * Build a [PendingIntent] that launches the main activity with the
     * given deep-link URI. We use `FLAG_ACTIVITY_NEW_TASK` because the
     * widget lives outside any activity stack, and `FLAG_IMMUTABLE` per
     * Android 12+ security requirements.
     */
    private fun buildDeepLinkPendingIntent(context: Context, uri: String): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setPackage(context.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        // Use uri.hashCode as the request code so different deep-links
        // produce distinct PendingIntents — otherwise Android caches
        // the first one and ignores the rest.
        return PendingIntent.getActivity(context, uri.hashCode(), intent, flags)
    }

    /**
     * Render the barcode value into a bitmap. We support QR_CODE,
     * CODE_128, AZTEC and EAN/UPC variants — covers virtually every
     * loyalty card format we accept on the Flutter side. Returns null
     * for unknown formats; the caller falls back to a placeholder.
     */
    private fun renderBarcode(value: String, format: String): Bitmap? {
        val zxingFormat = when (format.uppercase()) {
            "QR_CODE" -> BarcodeFormat.QR_CODE
            "CODE_128" -> BarcodeFormat.CODE_128
            "CODE_39" -> BarcodeFormat.CODE_39
            "EAN_13" -> BarcodeFormat.EAN_13
            "EAN_8" -> BarcodeFormat.EAN_8
            "UPC_A" -> BarcodeFormat.UPC_A
            "UPC_E" -> BarcodeFormat.UPC_E
            "AZTEC" -> BarcodeFormat.AZTEC
            "PDF417", "PDF_417" -> BarcodeFormat.PDF_417
            "ITF" -> BarcodeFormat.ITF
            "CODE_93" -> BarcodeFormat.CODE_93
            "CODABAR" -> BarcodeFormat.CODABAR
            "DATA_MATRIX" -> BarcodeFormat.DATA_MATRIX
            else -> return null
        }
        val width = if (zxingFormat == BarcodeFormat.QR_CODE) 360 else 600
        val height = if (zxingFormat == BarcodeFormat.QR_CODE) 360 else 200
        return try {
            val matrix = MultiFormatWriter().encode(value, zxingFormat, width, height)
            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            for (x in 0 until width) {
                for (y in 0 until height) {
                    bmp.setPixel(x, y, if (matrix[x, y]) Color.BLACK else Color.WHITE)
                }
            }
            bmp
        } catch (e: WriterException) {
            null
        } catch (e: IllegalArgumentException) {
            // ZXing throws this for values that don't fit a given format
            // (e.g. non-numeric EAN). We swallow it and show the
            // placeholder bitmap instead.
            null
        }
    }

    private fun placeholderBitmap(): Bitmap {
        return Bitmap.createBitmap(200, 80, Bitmap.Config.ARGB_8888).apply {
            eraseColor(Color.parseColor("#33FFFFFF"))
        }
    }

    private fun gradientBitmap(start: Int, end: Int, width: Int, height: Int): Bitmap {
        val drawable = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(start, end),
        ).apply {
            cornerRadius = 48f
        }
        drawable.setBounds(0, 0, width, height)
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bmp)
        drawable.draw(canvas)
        return bmp
    }

    private fun parseHex(raw: String?): Int? {
        if (raw.isNullOrEmpty()) return null
        return try {
            Color.parseColor(if (raw.startsWith("#")) raw else "#$raw")
        } catch (_: IllegalArgumentException) {
            null
        }
    }

    private fun sharedPrefs(context: Context): SharedPreferences {
        // The home_widget Flutter plugin persists values under this
        // exact name on Android (see HomeWidgetPlugin.kt in the plugin).
        // Reading the same file surfaces whatever Flutter just wrote.
        return context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE,
        )
    }

    companion object {
        private const val KEY_ID = "last_loyalty_id"
        private const val KEY_NAME = "last_loyalty_name"
        private const val KEY_BRAND = "last_loyalty_brand"
        private const val KEY_BARCODE = "last_loyalty_barcode"
        private const val KEY_FORMAT = "last_loyalty_format"
        private const val KEY_COLOR1 = "last_loyalty_color1"
        private const val KEY_COLOR2 = "last_loyalty_color2"

        /** Programmatic refresh trigger — currently unused (Flutter
         * drives updates via the home_widget plugin) but kept available
         * for ad-hoc debugging. */
        fun forceUpdate(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, LoyaltyWidgetReceiver::class.java)
            val ids = manager.getAppWidgetIds(component)
            val intent = Intent(context, LoyaltyWidgetReceiver::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
