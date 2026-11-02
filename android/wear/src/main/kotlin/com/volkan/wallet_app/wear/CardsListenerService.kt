package com.volkan.wallet_app.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

/** Phone → watch: a new card list arrives, even with the app closed. */
class CardsListenerService : WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            if (item.uri.path != CARDS_PATH) continue
            val json = DataMapItem.fromDataItem(item).dataMap.getString(CARDS_KEY) ?: continue
            CardStore.save(applicationContext, json)
        }
    }

    companion object {
        const val CARDS_PATH = "/cards"
        const val CARDS_KEY = "json"
    }
}
