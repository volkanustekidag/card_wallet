package com.volkan.wallet_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * Quick Settings tile that opens the user's most recently used loyalty
 * card. Same deep-link contract as the home / lock-screen widget — taps
 * fire `cardwallet://loyalty?id=<id>` (or plain `cardwallet://loyalty`
 * if no card has been opened yet), and `WidgetDeepLinkHandler` on the
 * Dart side routes past the PIN gate to the barcode page.
 *
 * Available on API 24+ (matches our minSdk).
 */
@RequiresApi(Build.VERSION_CODES.N)
class LoyaltyTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        refreshTileLabel()
    }

    override fun onClick() {
        super.onClick()
        val prefs = applicationContext.getSharedPreferences(
            "HomeWidgetPreferences",
            MODE_PRIVATE,
        )
        val id = prefs.getString("last_loyalty_id", "").orEmpty()
        val uri = if (id.isNotEmpty()) {
            "cardwallet://loyalty?id=$id"
        } else {
            "cardwallet://loyalty"
        }
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
            setPackage(applicationContext.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        // On Android 14+ tile clicks no longer auto-collapse the quick
        // settings panel before starting an activity — startActivityAndCollapse
        // takes a PendingIntent now.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = android.app.PendingIntent.getActivity(
                applicationContext,
                0,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                    android.app.PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    /**
     * Mirror the cached card's display name onto the tile when possible,
     * so the user sees which card they'd be opening. Falls back to
     * "Loyalty" when nothing is cached.
     */
    private fun refreshTileLabel() {
        val tile = qsTile ?: return
        val prefs = applicationContext.getSharedPreferences(
            "HomeWidgetPreferences",
            MODE_PRIVATE,
        )
        val name = prefs.getString("last_loyalty_name", "").orEmpty()
        val hasCard = prefs.getString("last_loyalty_id", "").orEmpty().isNotEmpty()

        tile.label = if (hasCard && name.isNotEmpty()) name else "Loyalty"
        tile.state = if (hasCard) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (hasCard) "Tap to show barcode" else "Add a card"
        }
        tile.updateTile()
    }
}
