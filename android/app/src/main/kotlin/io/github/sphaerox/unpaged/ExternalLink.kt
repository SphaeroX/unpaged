package io.github.sphaerox.unpaged

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens an https link in the user's browser
 * (see lib/core/platform/external_link_channel.dart). The app needs no
 * internet permission for this; the browser loads the page.
 */
class ExternalLink(private val activity: Activity) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "open") {
            result.notImplemented()
            return
        }
        val url = call.argument<String>("url")
        if (url == null || !url.startsWith("https://")) {
            result.success(false)
            return
        }
        result.success(
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                true
            } catch (e: ActivityNotFoundException) {
                false
            },
        )
    }

    companion object {
        const val CHANNEL = "io.github.sphaerox.unpaged/links"
    }
}
