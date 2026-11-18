package io.github.sphaerox.unpaged

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Shares or prints a stored PDF (see lib/core/platform/pdf_share_channel.dart).
 * Sharing goes through the system share sheet with a FileProvider URI;
 * printing streams the unchanged file to the system print dialog.
 */
class PdfShare(private val activity: Activity) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        val name = call.argument<String>("name") ?: "document.pdf"
        val file = path?.let(::File)
        if (file == null || !file.isFile) {
            result.success(false)
            return
        }
        when (call.method) {
            "share" -> result.success(share(file, name))
            "print" -> result.success(print(file, name))
            else -> result.notImplemented()
        }
    }

    private fun share(file: File, name: String): Boolean = try {
        // Copy under the book title so recipients don't see "<sha256>.pdf".
        val dir = File(activity.cacheDir, "shared").apply {
            deleteRecursively()
            mkdirs()
        }
        val copy = File(dir, name.replace(Regex("[/\\\\]"), "_"))
        file.copyTo(copy, overwrite = true)
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", copy)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            clipData = ClipData.newRawUri(name, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(send, null))
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: Exception) {
        false
    }

    private fun print(file: File, name: String): Boolean = try {
        val manager = activity.getSystemService(Context.PRINT_SERVICE) as PrintManager
        manager.print(name, FileDocumentAdapter(file, name), PrintAttributes.Builder().build())
        true
    } catch (e: Exception) {
        false
    }

    /** Hands the PDF file to the print framework as it is. */
    private class FileDocumentAdapter(
        private val file: File,
        private val name: String,
    ) : PrintDocumentAdapter() {
        override fun onLayout(
            oldAttributes: PrintAttributes?,
            newAttributes: PrintAttributes,
            cancellationSignal: CancellationSignal,
            callback: LayoutResultCallback,
            extras: Bundle?,
        ) {
            if (cancellationSignal.isCanceled) {
                callback.onLayoutCancelled()
                return
            }
            val info = PrintDocumentInfo.Builder(name)
                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                .setPageCount(PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
                .build()
            callback.onLayoutFinished(info, oldAttributes != newAttributes)
        }

        override fun onWrite(
            pages: Array<out PageRange>,
            destination: ParcelFileDescriptor,
            cancellationSignal: CancellationSignal,
            callback: WriteResultCallback,
        ) {
            try {
                file.inputStream().use { input ->
                    FileOutputStream(destination.fileDescriptor).use { input.copyTo(it) }
                }
                if (cancellationSignal.isCanceled) {
                    callback.onWriteCancelled()
                } else {
                    callback.onWriteFinished(arrayOf(PageRange.ALL_PAGES))
                }
            } catch (e: Exception) {
                callback.onWriteFailed(e.message)
            }
        }
    }

    companion object {
        const val CHANNEL = "io.github.sphaerox.unpaged/share_pdf"
    }
}
