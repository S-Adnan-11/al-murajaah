package dev.almurajaah.al_murajaah

import android.app.Activity
import android.content.Intent
import android.os.PowerManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.concurrent.Executors

/** User-selected documents only. No storage permission or backup-supplied paths. */
class MetadataDocuments(private val activity: Activity) {
    private val io = Executors.newSingleThreadExecutor()
    private var pending: MethodChannel.Result? = null
    private var source: File? = null
    private val maxBytes = 32 * 1024 * 1024

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "powerSaveMode") {
            result.success((activity.getSystemService(Activity.POWER_SERVICE) as PowerManager).isPowerSaveMode)
            return
        }
        if (call.method != "saveBackup" && call.method != "openBackup") {
            result.notImplemented()
            return
        }
        if (pending != null) {
            result.error("document_busy", "A document dialog is already open.", null)
            return
        }
        try {
            val save = call.method == "saveBackup"
            val file = if (save) File(call.argument<String>("path")!!).canonicalFile else null
            if (file != null) {
                require(file.path.startsWith(activity.filesDir.canonicalPath + File.separator))
                require(file.name.startsWith("al-murajaah-backup-") && file.extension == "json")
                require(file.isFile && file.length() <= maxBytes)
            }
            source = file
            pending = result
            activity.startActivityForResult(Intent(
                if (save) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT
            ).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/json"
                if (save) putExtra(Intent.EXTRA_TITLE, file!!.name)
                else putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream"))
            }, if (save) 6206 else 6207)
        } catch (failure: Exception) {
            pending = null
            source = null
            result.error("document_dialog", "Could not open document dialog.", null)
        }
    }

    fun onResult(request: Int, resultCode: Int, data: Intent?): Boolean {
        if (request != 6206 && request != 6207) return false
        val reply = pending ?: return true
        val file = source
        pending = null
        source = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            reply.success(null)
            return true
        }
        io.execute {
            try {
                if (request == 6206) {
                    activity.contentResolver.openOutputStream(uri, "w")!!.use { output ->
                        file!!.inputStream().use { input -> input.copyTo(output) }
                    }
                    // Verify provider readback before reporting success.
                    val expected = java.security.MessageDigest.getInstance("SHA-256")
                    file!!.inputStream().use { input ->
                        val buffer = ByteArray(65536)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            expected.update(buffer, 0, count)
                        }
                    }
                    val actual = java.security.MessageDigest.getInstance("SHA-256")
                    activity.contentResolver.openInputStream(uri)!!.use { input ->
                        val buffer = ByteArray(65536)
                        var bytes = 0L
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            bytes += count
                            check(bytes <= maxBytes)
                            actual.update(buffer, 0, count)
                        }
                        check(bytes == file.length())
                    }
                    check(expected.digest().contentEquals(actual.digest()))
                    activity.runOnUiThread { reply.success(true) }
                } else {
                    val output = ByteArrayOutputStream()
                    activity.contentResolver.openInputStream(uri)!!.use { input ->
                        val buffer = ByteArray(65536)
                        while (true) {
                            val count = input.read(buffer)
                            if (count < 0) break
                            check(output.size() + count <= maxBytes) { "Backup exceeds 32 MB." }
                            output.write(buffer, 0, count)
                        }
                    }
                    val text = Charsets.UTF_8.newDecoder()
                        .onMalformedInput(CodingErrorAction.REPORT)
                        .onUnmappableCharacter(CodingErrorAction.REPORT)
                        .decode(ByteBuffer.wrap(output.toByteArray())).toString()
                    activity.runOnUiThread { reply.success(text) }
                }
            } catch (failure: Exception) {
                activity.runOnUiThread { reply.error("document_io", "Could not read or verify the metadata document.", null) }
            }
        }
        return true
    }

    fun close() {
        pending?.error("document_closed", "Document dialog closed.", null)
        pending = null
        io.shutdown()
    }
}
