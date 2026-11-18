package io.github.sphaerox.unpaged

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Receives PDFs via "Open with" (ACTION_VIEW) and "Share" (ACTION_SEND),
 * copies them into the cache and reports the copy to Dart
 * (see lib/core/platform/incoming_pdf_channel.dart).
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialPdf: Map<String, String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialPdf = copyPdf(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialPdf") {
                    result.success(initialPdf)
                    initialPdf = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        copyPdf(intent)?.let { channel?.invokeMethod("pdfReceived", it) }
    }

    private fun copyPdf(intent: Intent?): Map<String, String>? {
        val uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> streamExtra(intent)
            else -> null
        } ?: return null
        return try {
            val name = displayName(uri) ?: "shared.pdf"
            val dir = File(cacheDir, "incoming").apply { mkdirs() }
            val target = File(dir, name.replace(Regex("[/\\\\]"), "_"))
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { input.copyTo(it) }
            } ?: return null
            mapOf("path" to target.absolutePath, "name" to name)
        } catch (e: Exception) {
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme == "file") return uri.lastPathSegment
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) return cursor.getString(0)
            }
        return null
    }

    companion object {
        private const val CHANNEL = "io.github.sphaerox.unpaged/incoming_pdf"
    }
}
