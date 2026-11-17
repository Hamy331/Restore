package com.example.restore

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ZALOPAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "isEmulator") return@setMethodCallHandler result.success(isEmulator())
                if (call.method != "pay") return@setMethodCallHandler result.notImplemented()
                val appId = call.argument<Int>("appId")
                val token = call.argument<String>("zpTransToken")
                val sandbox = call.argument<Boolean>("sandbox") ?: true
                if (appId == null || token.isNullOrEmpty()) {
                    return@setMethodCallHandler result.error("INVALID", "Missing appId or token", null)
                }
                result.success(openZaloPay(appId, token, sandbox))
            }
    }

    /**
     * Mở thẳng app ZaloPay với đơn đã tạo ở backend (app-to-app), giống cách SDK zpdk v3.1 làm:
     * link zalopay.api.v2://pay gửi tới đúng gói app (sandbox: vn.com.vng.zalopay.sb1).
     * Trả "opened", hoặc "not_installed" khi máy chưa cài app ZaloPay tương ứng.
     * Kết quả trả tiền không đọc ở đây: app hỏi backend, backend hỏi ZaloPay.
     */
    private fun openZaloPay(appId: Int, token: String, sandbox: Boolean): String {
        val uri = Uri.parse("zalopay.api.v2://pay").buildUpon()
            .appendQueryParameter("appid", appId.toString())
            .appendQueryParameter("zptranstoken", token)
            .appendQueryParameter("redirecturl", RETURN_URI)
            .appendQueryParameter("source", "app")
            .build()
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage(if (sandbox) ZALOPAY_SANDBOX_PACKAGE else ZALOPAY_PACKAGE)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            startActivity(intent)
            "opened"
        } catch (_: ActivityNotFoundException) {
            "not_installed"
        }
    }

    /** Máy ảo Android (emulator): không có app ZaloPay, app hiện công cụ thử thanh toán */
    private fun isEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT.lowercase()
        val model = Build.MODEL.lowercase()
        val product = Build.PRODUCT.lowercase()
        return fingerprint.startsWith("generic") || fingerprint.contains("emulator") ||
            model.contains("emulator") || model.contains("android sdk built for") ||
            model.contains("sdk_gphone") || product.contains("sdk") ||
            Build.HARDWARE.contains("goldfish") || Build.HARDWARE.contains("ranchu")
    }

    companion object {
        private const val ZALOPAY_CHANNEL = "restore/zalopay"
        private const val ZALOPAY_PACKAGE = "vn.com.vng.zalopay"
        private const val ZALOPAY_SANDBOX_PACKAGE = "vn.com.vng.zalopay.sb1"

        /** ZaloPay mở lại ReStore qua link này sau khi trả (khai báo trong AndroidManifest) */
        private const val RETURN_URI = "restore://zalopay"
    }
}
