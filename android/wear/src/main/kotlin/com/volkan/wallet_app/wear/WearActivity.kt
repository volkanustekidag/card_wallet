package com.volkan.wallet_app.wear

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.foundation.lazy.ScalingLazyColumn
import androidx.wear.compose.foundation.lazy.items
import androidx.wear.compose.foundation.lazy.rememberScalingLazyListState
import androidx.wear.compose.material.Chip
import androidx.wear.compose.material.ChipDefaults
import androidx.wear.compose.material.ListHeader
import androidx.wear.compose.material.MaterialTheme
import androidx.wear.compose.material.PositionIndicator
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text
import androidx.wear.compose.material.TimeText
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable

/** Brand tangerine, as on the phone. */
private val Tangerine = Color(0xFFFF5A1F)

/**
 * Loyalty cards on the wrist: the list (usage order, as the phone sends
 * it) and, one tap away, the barcode at full brightness for the till.
 * Read-only; the phone is where cards are added and edited.
 */
class WearActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CardStore.load(this)
        pullLatestFromPhone()
        setContent { WearApp() }
    }

    /** The listener service covers updates; this covers a fresh install. */
    private fun pullLatestFromPhone() {
        Wearable.getDataClient(this).dataItems.addOnSuccessListener { buffer ->
            try {
                for (item in buffer) {
                    if (item.uri.path != CardsListenerService.CARDS_PATH) continue
                    val json = DataMapItem.fromDataItem(item).dataMap
                        .getString(CardsListenerService.CARDS_KEY) ?: continue
                    CardStore.save(applicationContext, json)
                }
            } finally {
                buffer.release()
            }
        }
    }
}

@Composable
private fun WearApp() {
    val cards by CardStore.cards.collectAsState()
    val nav = rememberSwipeDismissableNavController()
    MaterialTheme {
        SwipeDismissableNavHost(navController = nav, startDestination = "list") {
            composable("list") {
                CardList(cards) { nav.navigate("card/${it.id}") }
            }
            composable("card/{id}") { entry ->
                val id = entry.arguments?.getString("id")
                val card = cards.firstOrNull { it.id == id }
                if (card == null) {
                    Message(stringResource(R.string.card_unavailable), null)
                } else {
                    CardBarcode(card)
                }
            }
        }
    }
}

@Composable
private fun CardList(cards: List<WearCard>, onOpen: (WearCard) -> Unit) {
    val listState = rememberScalingLazyListState()
    Scaffold(
        timeText = { TimeText() },
        positionIndicator = { PositionIndicator(scalingLazyListState = listState) },
    ) {
        if (cards.isEmpty()) {
            Message(
                stringResource(R.string.empty_title),
                stringResource(R.string.empty_body),
            )
            return@Scaffold
        }
        ScalingLazyColumn(
            modifier = Modifier.fillMaxSize(),
            state = listState,
        ) {
            item { ListHeader { Text(stringResource(R.string.list_title)) } }
            items(cards, key = { it.id }) { card ->
                Chip(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = { onOpen(card) },
                    label = {
                        Text(card.displayName, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    },
                    secondaryLabel = if (card.brand.isNotBlank() && card.brand != card.name) {
                        { Text(card.brand, maxLines = 1, overflow = TextOverflow.Ellipsis) }
                    } else {
                        null
                    },
                    icon = {
                        Box(
                            Modifier
                                .size(ChipDefaults.SmallIconSize)
                                .background(
                                    Color(parseHex(card.color1, 0xFF22252C.toInt())),
                                    CircleShape,
                                ),
                        )
                    },
                    colors = ChipDefaults.secondaryChipColors(),
                )
            }
        }
    }
}

/** The till screen: card colours, a white panel with the barcode. */
@Composable
private fun CardBarcode(card: WearCard) {
    val context = LocalContext.current
    DisposableEffect(Unit) {
        val window = (context as? Activity)?.window
        val before = window?.attributes?.screenBrightness
        window?.let {
            it.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            it.attributes = it.attributes.apply { screenBrightness = 1f }
        }
        onDispose {
            window?.let {
                it.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                it.attributes = it.attributes.apply {
                    screenBrightness = before
                        ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                }
            }
        }
    }
    val square = isSquare(card.format)
    val bitmap = remember(card.barcode, card.format) {
        if (square) renderBarcode(card.barcode, card.format, 300, 300)
        else renderBarcode(card.barcode, card.format, 600, 220)
    }
    val fg = Color(parseHex(card.fg, android.graphics.Color.WHITE))
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    listOf(
                        Color(parseHex(card.color1, 0xFF22252C.toInt())),
                        Color(parseHex(card.color2, 0xFF0B0C0F.toInt())),
                    ),
                ),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(horizontal = 18.dp),
        ) {
            Text(
                card.displayName,
                color = fg,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(6.dp))
            Box(
                modifier = Modifier
                    .background(Color.White, RoundedCornerShape(12.dp))
                    .padding(8.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = card.barcode,
                        contentScale = ContentScale.Fit,
                        filterQuality = FilterQuality.None,
                        modifier = if (square) Modifier.size(104.dp)
                        else Modifier.fillMaxWidth().height(64.dp),
                    )
                } else {
                    Text(
                        stringResource(R.string.show_on_phone),
                        color = Color.Black,
                        fontSize = 12.sp,
                        textAlign = TextAlign.Center,
                    )
                }
            }
            Spacer(Modifier.height(6.dp))
            Text(
                card.barcode,
                color = fg.copy(alpha = 0.9f),
                fontSize = 11.sp,
                fontFamily = FontFamily.Monospace,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
private fun Message(title: String, body: String?) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 22.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Box(
            Modifier
                .size(10.dp)
                .background(Tangerine, CircleShape),
        )
        Spacer(Modifier.height(10.dp))
        Text(title, textAlign = TextAlign.Center, fontWeight = FontWeight.SemiBold)
        if (body != null) {
            Spacer(Modifier.height(4.dp))
            Text(
                body,
                textAlign = TextAlign.Center,
                fontSize = 12.sp,
                color = MaterialTheme.colors.onSurfaceVariant,
            )
        }
    }
}
