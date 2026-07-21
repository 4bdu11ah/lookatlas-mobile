package com.lookatlas

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_INFO_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != GET_DEVICE_INFO_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val androidId = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID,
            )
            if (androidId.isNullOrBlank()) {
                result.error(
                    "DEVICE_ID_UNAVAILABLE",
                    "Android ID is unavailable.",
                    null,
                )
                return@setMethodCallHandler
            }

            result.success(
                mapOf(
                    "deviceId" to androidId,
                    "identifierType" to "androidId",
                    "platform" to "android",
                    "manufacturer" to Build.MANUFACTURER,
                    "model" to Build.MODEL,
                    "systemName" to "Android",
                    "systemVersion" to Build.VERSION.RELEASE,
                    "apiLevel" to Build.VERSION.SDK_INT,
                ),
            )
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EXTERNAL_URL_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != OPEN_URL_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val rawUrl = call.argument<String>("url")
            val uri = rawUrl?.let(Uri::parse)
            val isStripeCheckout = uri?.scheme == "https" &&
                uri.host == "checkout.stripe.com"
            val isAppReturn = uri?.scheme == "lookatlas" &&
                (uri.path == "/onboarding/success" ||
                    uri.path == "/onboarding/activate")
            if (!isStripeCheckout && !isAppReturn) {
                result.error("UNTRUSTED_URL", "Checkout URL is not trusted.", null)
                return@setMethodCallHandler
            }
            startActivity(Intent(Intent.ACTION_VIEW, uri))
            result.success(null)
        }
    }

    private companion object {
        const val DEVICE_INFO_CHANNEL = "com.lookatlas/device_info"
        const val GET_DEVICE_INFO_METHOD = "getDeviceInfo"
        const val EXTERNAL_URL_CHANNEL = "com.lookatlas/external_url"
        const val OPEN_URL_METHOD = "open"
    }
}
