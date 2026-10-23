package com.volkan.wallet_app.wear

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.json.JSONObject

/**
 * A loyalty card as the phone sends it (WatchSyncService.encodePayload,
 * the same JSON the Apple Watch gets). Cards arrive in usage order, so
 * the list shows them as they come.
 */
data class WearCard(
    val id: String,
    val name: String,
    val brand: String,
    val barcode: String,
    val format: String,
    val color1: String,
    val color2: String,
    val fg: String?,
) {
    val displayName: String get() = name.ifBlank { brand }
}

/** Newest version of the payload this build understands. */
private const val PAYLOAD_VERSION = 1

/** Parses the phone's payload; null when it's unreadable or too new. */
fun parseCards(json: String): List<WearCard>? = try {
    val root = JSONObject(json)
    if (root.optInt("version", 1) > PAYLOAD_VERSION) {
        null
    } else {
        val list = root.optJSONArray("cards")
        (0 until (list?.length() ?: 0)).mapNotNull { i ->
            val c = list!!.optJSONObject(i) ?: return@mapNotNull null
            val barcode = c.optString("barcode")
            if (barcode.isBlank()) return@mapNotNull null
            WearCard(
                id = c.optString("id"),
                name = c.optString("name"),
                brand = c.optString("brand"),
                barcode = barcode,
                format = c.optString("format", "CODE_128"),
                color1 = c.optString("color1", "#22252C"),
                color2 = c.optString("color2", "#0B0C0F"),
                fg = c.optString("fg").ifBlank { null },
            )
        }
    }
} catch (_: Exception) {
    null
}

/**
 * The last payload from the phone, kept on the watch so cards open with
 * the phone out of reach.
 */
object CardStore {
    private const val PREFS = "cards"
    private const val KEY = "payload"
    private val _cards = MutableStateFlow<List<WearCard>>(emptyList())
    val cards: StateFlow<List<WearCard>> = _cards

    fun load(context: Context) {
        val json = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return
        parseCards(json)?.let { _cards.value = it }
    }

    fun save(context: Context, json: String) {
        val parsed = parseCards(json) ?: return
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, json).apply()
        _cards.value = parsed
    }
}
