package dev.almurajaah.al_murajaah

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.StatFs
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/** DownloadManager owns transfer lifetime. File hashing/copying lives in a Dart
 * I/O isolate; no transfer/database/file scan is performed on Android's UI thread. */
class AudioDownloads(private val context: Context, private val reply: (Runnable) -> Unit) {
    private val io = Executors.newSingleThreadExecutor()
    private val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val staging: File get() = File(requireNotNull(context.getExternalFilesDir(null)), "audio_staging")

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val value: Any? = when (call.method) {
                    "freeBytes" -> {
                        staging.mkdirs()
                        minOf(StatFs(context.filesDir.path).availableBytes, StatFs(staging.path).availableBytes)
                    }
                    "enqueue" -> {
                        val id = requireNotNull(call.argument<String>("assetId"))
                        require(Regex("^zarami-hafs-\\d{3}-v[1-9]\\d*$").matches(id))
                        val url = requireNotNull(call.argument<String>("url"))
                        val number = id.substring(12, 15)
                        require(Regex("^https://res\\.cloudinary\\.com/yw5eprsc/video/upload/(v[0-9]+/)?zarami-$number\\.mp3$").matches(url))
                        staging.mkdirs()
                        val target = File(staging, "$id-${System.nanoTime()}.part")
                        val request = DownloadManager.Request(Uri.parse(url))
                            .setTitle(call.argument<String>("title") ?: "Recitation")
                            .setDescription("Downloading recitation")
                            .setMimeType("audio/mpeg")
                            .setDestinationUri(Uri.fromFile(target))
                            // Keep native progress visible. The app publishes
                            // verified completion itself; DownloadManager's
                            // completion alert takes audio focus from speech.
                            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                            .setAllowedOverRoaming(false)
                        if (call.argument<Boolean>("wifiOnly") != false) {
                            request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_WIFI)
                        }
                        manager.enqueue(request).toString()
                    }
                    "status" -> {
                        val id = requireNotNull(call.argument<String>("taskId")).toLong()
                        manager.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
                            if (!cursor.moveToFirst()) mapOf("state" to "missing", "received" to 0L)
                            else {
                                val state = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                                val uri = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                                val file = uri?.let { if (Uri.parse(it).scheme == "file") File(requireNotNull(Uri.parse(it).path)).canonicalFile else null }
                                if (file != null) require(file.path.startsWith(staging.canonicalPath + File.separator))
                                mapOf(
                                    "state" to when(state) {
                                        DownloadManager.STATUS_SUCCESSFUL -> "successful"
                                        DownloadManager.STATUS_FAILED -> "failed"
                                        DownloadManager.STATUS_PAUSED -> "paused"
                                        else -> "running"
                                    },
                                    "received" to cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)),
                                    "path" to file?.path,
                                    "reason" to cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)).toString(),
                                )
                            }
                        }
                    }
                    "cancel" -> { manager.remove(requireNotNull(call.argument<String>("taskId")).toLong()); null }
                    else -> throw IllegalArgumentException("Unknown audio download method")
                }
                reply(Runnable { result.success(value) })
            } catch(error: Exception) {
                reply(Runnable { result.error("audio_download", error.toString(), null) })
            }
        }
    }
    fun close() { io.shutdown() }
}
