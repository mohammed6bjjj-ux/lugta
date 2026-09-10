package lugta.nawl.com

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/** OS-owned transfers survive activity/process removal. No seller JWT is persisted. */
class MediaDownloads(private val context: Context, messenger: BinaryMessenger) {
    private val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val prefs = context.getSharedPreferences("media-downloads-v1", Context.MODE_PRIVATE)
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "lugta/media_downloads")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "supported" -> result.success(Build.VERSION.SDK_INT >= 29)
                "openDownloads" -> try {
                    context.startActivity(Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                } catch (_: Exception) { result.error("downloads_unavailable", "Downloads screen unavailable", null) }
                "lookup", "enqueue" -> {
                    val args = call.arguments as? Map<*, *>
                    val key = args?.get("key") as? String
                    if (key.isNullOrBlank()) { result.error("invalid_media", "Missing media key", null) }
                    else worker.execute {
                        try {
                            val hash = MessageDigest.getInstance("SHA-256").digest(key.toByteArray())
                                .joinToString("") { "%02x".format(it) }
                            val existing = lookup(hash)
                            val value = if (existing != null || call.method == "lookup") existing
                                else enqueue(hash, requireNotNull(args))
                            main.post { result.success(value) }
                        } catch (_: Exception) {
                            // Never include signed URLs, tokens, or underlying HTTP details in errors.
                            main.post { result.error("download_enqueue_failed", "Could not queue media download", null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun lookup(key: String): Map<String, Any>? {
        val id = prefs.getLong(key, -1)
        if (id < 0) return null
        var failed = false
        manager.query(DownloadManager.Query().setFilterById(id))?.use { cursor ->
            if (cursor.moveToFirst()) {
                val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                if (status == DownloadManager.STATUS_SUCCESSFUL) {
                    val uri = manager.getUriForDownloadedFile(id)
                    if (uri != null) {
                        try {
                            context.contentResolver.openFileDescriptor(uri, "r")?.use {
                                return mapOf("id" to id, "state" to "saved")
                            }
                        } catch (_: Exception) { /* User deleted the file: allow downloading again. */ }
                    }
                } else if (status != DownloadManager.STATUS_FAILED) {
                    return mapOf("id" to id, "state" to "queued")
                } else failed = true
            }
        }
        // Remove only this app's failed/missing transfer, never a successful existing file.
        if (failed) manager.remove(id)
        prefs.edit().remove(key).commit()
        return null
    }

    private fun enqueue(key: String, args: Map<*, *>): Map<String, Any> {
        check(Build.VERSION.SDK_INT >= 29)
        val uri = Uri.parse(args["url"] as? String ?: error("url"))
        require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null)
        val video = args["video"] == true
        val supplied = args["name"] as? String ?: "media"
        val extension = supplied.substringAfterLast('.', if (video) "mp4" else "jpg").lowercase()
        require(extension in setOf("jpg", "jpeg", "png", "webp", "heic", "avif", "gif", "mp4", "mov", "m4v", "webm"))
        val title = "Lugta-${key.take(16)}.$extension"
        val directory = if (video) Environment.DIRECTORY_MOVIES else Environment.DIRECTORY_PICTURES
        val request = DownloadManager.Request(uri)
            .setTitle(title)
            .setDescription("Lugta • لكطة")
            .setMimeType(MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
                ?: if (video) "video/mp4" else "image/jpeg")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(false)
            .setDestinationInExternalPublicDir(directory, "Lugta/$title")
        @Suppress("DEPRECATION")
        request.allowScanningByMediaScanner()
        // A removed DownloadManager record may leave a file. Do not overwrite it.
        @Suppress("DEPRECATION")
        val file = File(Environment.getExternalStoragePublicDirectory(directory), "Lugta/$title")
        if (file.exists()) {
            request.setDestinationInExternalPublicDir(directory, "Lugta/${key.take(16)}-${System.currentTimeMillis()}.$extension")
        }
        val id = manager.enqueue(request)
        prefs.edit().putLong(key, id).commit()
        return mapOf("id" to id, "state" to "queued")
    }

    fun dispose() { channel.setMethodCallHandler(null); worker.shutdown() }
}
