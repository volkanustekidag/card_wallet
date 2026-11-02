package com.volkan.wallet_app

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PersistableBundle
import android.view.WindowManager
import com.google.android.gms.pay.Pay
import com.google.android.gms.pay.PayClient
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val walletChannel = "app.cardwallet/google_wallet"
    private val clipboardChannel = "app.cardwallet/sensitive_clipboard"
    // Same channel as iOS (WatchSyncService): here it feeds Wear OS.
    private val watchChannel = "app.cardwallet/watch_sync"
    private val savePassRequestCode = 4242

    private lateinit var payClient: PayClient
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Block screenshots and hide app contents from the recent-apps thumbnail.
        // Card numbers and IBANs must never appear in screenshots or the
        // Android task switcher snapshot.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
        payClient = Pay.getClient(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, walletChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToWallet" -> {
                        val jwt = call.argument<String>("jwt")
                        if (jwt.isNullOrBlank()) {
                            result.error("invalid_args", "jwt is required", null)
                            return@setMethodCallHandler
                        }
                        startSavePass(jwt, result)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, watchChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pushAllCards" -> pushCardsToWatch(call.arguments as? String, result)
                    "isPaired" -> probeWatch(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, clipboardChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copy" -> {
                        val text = call.argument<String>("text")
                        if (text == null) {
                            result.error("invalid_args", "text is required", null)
                            return@setMethodCallHandler
                        }
                        copySensitive(text)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Publishes the card list as a Data Layer item; Wear OS delivers it to
     * the watch app whenever it's connected (last write wins, like
     * WCSession's application context on iOS). Phones without Wear OS
     * just answer false.
     */
    private fun pushCardsToWatch(json: String?, result: MethodChannel.Result) {
        if (json == null) {
            result.error("invalid_args", "payload is required", null)
            return
        }
        try {
            val request = PutDataMapRequest.create("/cards").apply {
                dataMap.putString("json", json)
                dataMap.putLong("sentAt", System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()
            Wearable.getDataClient(this).putDataItem(request)
                .addOnSuccessListener { result.success(true) }
                .addOnFailureListener { result.success(false) }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    /** paired: any watch connected; installed: one has our watch app. */
    private fun probeWatch(result: MethodChannel.Result) {
        try {
            Wearable.getNodeClient(this).connectedNodes
                .addOnSuccessListener { nodes ->
                    Wearable.getCapabilityClient(this)
                        .getCapability("cardwallet_wear", CapabilityClient.FILTER_REACHABLE)
                        .addOnSuccessListener { info ->
                            result.success(mapOf(
                                "paired" to nodes.isNotEmpty(),
                                "installed" to info.nodes.isNotEmpty(),
                            ))
                        }
                        .addOnFailureListener {
                            result.success(mapOf("paired" to nodes.isNotEmpty(), "installed" to false))
                        }
                }
                .addOnFailureListener {
                    result.success(mapOf("paired" to false, "installed" to false))
                }
        } catch (e: Exception) {
            result.success(mapOf("paired" to false, "installed" to false))
        }
    }

    /**
     * Marks the clip as sensitive so Android 13+ hides it from the
     * clipboard preview overlay and keyboard suggestions. The Dart side
     * still clears it after 60 s.
     */
    private fun copySensitive(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("", text)
        val sensitiveKey = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ClipDescription.EXTRA_IS_SENSITIVE
        } else {
            "android.content.extra.IS_SENSITIVE"
        }
        clip.description.extras = PersistableBundle().apply {
            putBoolean(sensitiveKey, true)
        }
        clipboard.setPrimaryClip(clip)
    }

    private fun startSavePass(jwt: String, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A save flow is already in progress", null)
            return
        }
        pendingResult = result
        try {
            payClient.savePasses(jwt, this, savePassRequestCode)
        } catch (e: Throwable) {
            pendingResult = null
            result.error("save_failed", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == savePassRequestCode) {
            val callback = pendingResult
            pendingResult = null
            when (resultCode) {
                Activity.RESULT_OK -> callback?.success(true)
                Activity.RESULT_CANCELED -> callback?.success(false)
                PayClient.SavePassesResult.SAVE_ERROR -> {
                    val message = data?.getStringExtra(PayClient.EXTRA_API_ERROR_MESSAGE)
                    callback?.error("save_error", message, null)
                }
                else -> callback?.success(false)
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
