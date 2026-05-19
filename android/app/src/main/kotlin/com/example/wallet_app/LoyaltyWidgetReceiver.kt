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
            appWidgetManager.updateAppWidget(id, buildRemoteViews(context, prefs))
        }
    }

    private fun buildRemoteViews(
        context: Context,
        prefs: SharedPreferences,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.loyalty_widget)

        val id = prefs.getString(KEY_ID, "").orEmpty()
        val name = prefs.getString(KEY_NAME, "").orEmpty()
        val brand = prefs.getString(KEY_BRAND, "").orEmpty()
        val barcode = prefs.getString(KEY_BARCODE, "").orEmpty()
        val format = prefs.getString(KEY_FORMAT, "").orEmpty()
        val color1 = parseHex(prefs.getString(KEY_COLOR1, "")) ?: Color.parseColor("#1F2937")
        val color2 = parseHex(prefs.getString(KEY_COLOR2, "")) ?: Color.parseColor("#111827")

        // Background gradient. RemoteViews can't host arbitrary
        // drawables, but it can set a Bitmap on an ImageView — so we
        // build the gradient into a bitmap and lay it underneath the
        // content via an ImageView in the layout.
        val gradient = gradientBitmap(color1, color2, 600, 360)
        views.setImageViewBitmap(R.id.loyalty_widget_background, gradient)

        if (id.isEmpty() || barcode.isEmpty()) {
            // Empty state — user hasn't opened any loyalty card yet, or
            // the cached one was deleted.
            views.setTextViewText(R.id.loyalty_widget_title, "Loyalty")
            views.setTextViewText(R.id.loyalty_widget_subtitle, "Add a card")
            views.setTextViewText(R.id.loyalty_widget_number, "")
            views.setImageViewBitmap(R.id.loyalty_widget_barcode, placeholderBitmap())
            views.setOnClickPendingIntent(
                R.id.loyalty_widget_root,
                buildDeepLinkPendingIntent(context, "cardwallet://loyalty"),
            )
            return views
        }

        val displayName = if (name.isNotEmpty()) name else brand
        views.setTextViewText(R.id.loyalty_widget_title, displayName)
        // Brand only appears top-right when it's distinct from the
        // primary name — the barcode itself is the main affordance now,
        // no "tap to scan" hint needed.
        val showBrand = brand.isNotEmpty() && brand != name
        views.setTextViewText(
            R.id.loyalty_widget_subtitle,
            if (showBrand) brand else "",
        )
        views.setTextViewText(R.id.loyalty_widget_number, barcode)

        val barcodeBitmap = renderBarcode(barcode, format)
            ?: placeholderBitmap()
        views.setImageViewBitmap(R.id.loyalty_widget_barcode, barcodeBitmap)

        views.setOnClickPendingIntent(
            R.id.loyalty_widget_root,
            buildDeepLinkPendingIntent(context, "cardwallet://loyalty?id=$id"),
        )

        return views
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
            "PDF_417" -> BarcodeFormat.PDF_417
            "ITF" -> BarcodeFormat.ITF
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
