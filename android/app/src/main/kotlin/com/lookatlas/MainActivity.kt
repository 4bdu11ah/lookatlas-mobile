package com.lookatlas

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingImageSave: PendingImageSave? = null

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            IMAGE_SAVE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != SAVE_IMAGE_METHOD) {
                result.notImplemented()
                return@setMethodCallHandler
            }
            saveImage(call, result)
        }
    }

    private fun saveImage(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")
        val fileName = call.argument<String>("fileName")?.let { File(it).name }
        val mimeType = call.argument<String>("mimeType")
        if (bytes == null || bytes.isEmpty() || fileName.isNullOrBlank() || mimeType == null) {
            result.error("INVALID_IMAGE", "Image data is invalid.", null)
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingImageSave != null) {
                result.error("SAVE_IN_PROGRESS", "Another image is being saved.", null)
                return
            }
            pendingImageSave = PendingImageSave(bytes, fileName, mimeType, result)
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                IMAGE_SAVE_PERMISSION_REQUEST,
            )
            return
        }
        writeImage(bytes, fileName, mimeType, result)
    }

    private fun writeImage(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        Thread {
            try {
                val location = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveToMediaStore(bytes, fileName, mimeType)
                } else {
                    saveToAppPictures(bytes, fileName, mimeType)
                }
                runOnUiThread { result.success(location) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("SAVE_FAILED", "Could not save image.", error.message)
                }
            }
        }.start()
    }

    private fun saveToMediaStore(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
    ): String {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, mimeType)
            put(
                MediaStore.Images.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_PICTURES}/Look Atlas",
            )
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: error("Could not create media entry.")
        try {
            contentResolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Could not open media output.")
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToAppPictures(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
    ): String {
        val directory = File(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES,
            ),
            "Look Atlas",
        )
        check(directory.exists() || directory.mkdirs()) {
            "Could not create pictures directory."
        }
        val file = File(directory, fileName)
        file.writeBytes(bytes)
        MediaScannerConnection.scanFile(
            this,
            arrayOf(file.absolutePath),
            arrayOf(mimeType),
            null,
        )
        return file.toURI().toString()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != IMAGE_SAVE_PERMISSION_REQUEST) return
        val pending = pendingImageSave ?: return
        pendingImageSave = null
        if (grantResults.firstOrNull() != PackageManager.PERMISSION_GRANTED) {
            pending.result.error(
                "PHOTO_ACCESS_DENIED",
                "Photo library access was denied.",
                null,
            )
            return
        }
        writeImage(
            pending.bytes,
            pending.fileName,
            pending.mimeType,
            pending.result,
        )
    }

    private data class PendingImageSave(
        val bytes: ByteArray,
        val fileName: String,
        val mimeType: String,
        val result: MethodChannel.Result,
    )

    private companion object {
        const val DEVICE_INFO_CHANNEL = "com.lookatlas/device_info"
        const val GET_DEVICE_INFO_METHOD = "getDeviceInfo"
        const val EXTERNAL_URL_CHANNEL = "com.lookatlas/external_url"
        const val OPEN_URL_METHOD = "open"
        const val IMAGE_SAVE_CHANNEL = "com.lookatlas/image_save"
        const val SAVE_IMAGE_METHOD = "save"
        const val IMAGE_SAVE_PERMISSION_REQUEST = 3021
    }
}
