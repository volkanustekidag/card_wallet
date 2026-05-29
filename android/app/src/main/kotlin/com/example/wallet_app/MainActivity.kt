package com.volkan.wallet_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import com.google.android.gms.pay.Pay
import com.google.android.gms.pay.PayClient
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val walletChannel = "app.cardwallet/google_wallet"
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
