package com.xmsj.shouyin.shouyin_android

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var productImages: ProductImagePicker? = null
    private var terminalIdentity: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        productImages = ProductImagePicker(this, flutterEngine.dartExecutor.binaryMessenger)
        terminalIdentity = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "shouyin/terminal_identity"
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "getMachineCode") {
                    result.notImplemented()
                } else {
                    try {
                        result.success(getMachineCode())
                    } catch (_: Exception) {
                        // Never expose platform exceptions or identifiers in diagnostics.
                        result.error("terminal_identity_unavailable", "无法获取终端机器码", null)
                    }
                }
            }
        }
    }

    private fun getMachineCode(): String {
        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)?.trim()
        if (!androidId.isNullOrEmpty()) return "android:$androidId"

        // A fallback belongs to this installation, never to all devices of a model.
        val preferences = getSharedPreferences("terminal_identity", MODE_PRIVATE)
        val stored = preferences.getString("installation_uuid", null)?.trim()
        if (!stored.isNullOrEmpty()) return "android:installation:$stored"
        val installationId = UUID.randomUUID().toString()
        if (!preferences.edit().putString("installation_uuid", installationId).commit()) {
            throw IllegalStateException("Unable to persist terminal installation identity")
        }
        return "android:installation:$installationId"
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        productImages?.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        terminalIdentity?.setMethodCallHandler(null)
        terminalIdentity = null
        productImages?.dispose()
        productImages = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
