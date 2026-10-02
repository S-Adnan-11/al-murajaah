package dev.almurajaah.al_murajaah

import android.app.Activity
import android.app.ActivityManager
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val diagnosticIo = Executors.newSingleThreadExecutor()
    private val activityCreatedUptimeMs = SystemClock.uptimeMillis()
    private data class PendingSave(
        val source: File, val bytes: Long, val sha256: String,
        val result: MethodChannel.Result,
    )
    private var pendingSave: PendingSave? = null

    override fun onDestroy() {
        pendingSave?.result?.error("export_activity_closed", "Activity closed; internal export retained.", null)
        pendingSave = null
        diagnosticIo.shutdown()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.almurajaah/diagnostics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "platformEvidence" -> diagnosticIo.execute {
                        try {
                            val evidence = platformEvidence()
                            runOnUiThread { result.success(evidence) }
                        } catch (error: Exception) {
                            runOnUiThread { result.error("platform_evidence", error.toString(), null) }
                        }
                    }
                    "saveDiagnosticFile" -> {
                        if (pendingSave != null) {
                            result.error("export_busy", "A save dialog is already open.", null)
                        } else {
                            try {
                                val source = File(call.argument<String>("path")!!).canonicalFile
                                require(source.path.startsWith(filesDir.canonicalPath + File.separator))
                                require(source.name.startsWith("audio-diagnostics-") && source.extension == "json")
                                pendingSave = PendingSave(
                                    source, call.argument<Number>("bytes")!!.toLong(),
                                    call.argument<String>("sha256")!!, result,
                                )
                                startActivityForResult(
                                    Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                        addCategory(Intent.CATEGORY_OPENABLE)
                                        type = "application/json"
                                        putExtra(Intent.EXTRA_TITLE, source.name)
                                    }, 6205,
                                )
                            } catch (error: Exception) {
                                pendingSave = null
                                result.error("export_dialog", error.toString(), null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Uses the existing Activity result API supported by AudioServiceActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 6205) return
        val save = pendingSave ?: return
        pendingSave = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            save.result.success(null)
            return
        }
        diagnosticIo.execute {
            try {
                // Copy and reopen the actual saved document on the I/O worker.
                contentResolver.openOutputStream(uri, "w")!!.use { output ->
                    save.source.inputStream().use { input -> input.copyTo(output) }
                }
                val digest = MessageDigest.getInstance("SHA-256")
                var bytes = 0L
                contentResolver.openInputStream(uri)!!.use { input ->
                    val buffer = ByteArray(65536)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        digest.update(buffer, 0, count)
                        bytes += count
                    }
                }
                val hash = digest.digest().joinToString("") { "%02x".format(it) }
                check(bytes == save.bytes && hash == save.sha256) { "Saved document integrity mismatch" }
                runOnUiThread {
                    save.result.success(mapOf("bytes" to bytes, "sha256" to hash, "uri" to uri.toString()))
                }
            } catch (error: Exception) {
                runOnUiThread { save.result.error("export_write", error.toString(), null) }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun platformEvidence(): Map<String, Any?> {
        val info = packageManager.getPackageInfo(packageName, 0)
        val evidence = mutableMapOf<String, Any?>(
            "manufacturer" to Build.MANUFACTURER, "model" to Build.MODEL,
            "androidRelease" to Build.VERSION.RELEASE, "sdk" to Build.VERSION.SDK_INT,
            "versionName" to info.versionName,
            "versionCode" to if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong(),
            "activityCreatedUptimeMs" to activityCreatedUptimeMs,
            "exportUptimeMs" to SystemClock.uptimeMillis(),
        )
        if (Build.VERSION.SDK_INT >= 30) {
            val manager = getSystemService(ActivityManager::class.java)
            evidence["historicalExits"] = manager.getHistoricalProcessExitReasons(packageName, 0, 5).map { exit ->
                val row = mutableMapOf<String, Any?>(
                    "timestampEpochMs" to exit.timestamp, "reason" to exit.reason,
                    "description" to exit.description, "importance" to exit.importance,
                    "pssKiB" to exit.pss, "rssKiB" to exit.rss,
                )
                try {
                    exit.traceInputStream?.use { input ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (output.size() <= 262144) {
                            val count = input.read(buffer, 0, minOf(buffer.size, 262145 - output.size()))
                            if (count < 0) break
                            output.write(buffer, 0, count)
                        }
                        val trace = output.toByteArray()
                        row["traceTruncated"] = trace.size > 262144
                        row["traceText"] = String(trace, 0, minOf(trace.size, 262144), Charsets.UTF_8)
                    }
                } catch (error: Exception) {
                    row["traceReadError"] = error.toString()
                }
                row
            }
            evidence["exitEvidenceScope"] = "Up to 5 app exits retained by Android; traces may be absent. No trace does not disprove an ANR. Individual traces capped at 256 KiB with explicit flag."
        } else {
            evidence["exitEvidenceScope"] = "ApplicationExitInfo requires Android 11/API 30."
        }
        return evidence
    }
}
