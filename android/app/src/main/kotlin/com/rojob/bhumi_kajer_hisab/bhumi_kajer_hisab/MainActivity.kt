package com.rojob.bhumi_kajer_hisab.bhumi_kajer_hisab

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    companion object {
        private const val DOWNLOAD_CHANNEL = "com.rojob.bhumi_kajer_hisab/downloads"
    }

    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    val filePath = call.argument<String>("filePath")
                    val bytes = call.argument<ByteArray>("bytes")

                    if (fileName.isNullOrBlank() || (filePath.isNullOrBlank() && bytes == null)) {
                        result.error("INVALID_ARGS", "Missing fileName or filePath/bytes", null)
                        return@setMethodCallHandler
                    }

                    ioExecutor.execute {
                        try {
                            val savedInfo = if (!filePath.isNullOrBlank()) {
                                val sourceFile = File(filePath)
                                if (!sourceFile.exists() || !sourceFile.isFile) {
                                    throw IllegalStateException("Source temp file does not exist")
                                }
                                FileInputStream(sourceFile).use { input ->
                                    saveStreamToPublicDownloads(fileName, mimeType, input)
                                }
                            } else {
                                saveBytesToPublicDownloads(fileName, mimeType, bytes!!)
                            }
                            mainHandler.post { result.success(savedInfo) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("SAVE_FAILED", e.message, null) }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        ioExecutor.shutdown()
        super.onDestroy()
    }

    private fun saveBytesToPublicDownloads(
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
    ): Map<String, Any>? {
        return bytes.inputStream().use { input ->
            saveStreamToPublicDownloads(fileName, mimeType, input)
        }
    }

    private fun saveStreamToPublicDownloads(
        fileName: String,
        mimeType: String,
        input: InputStream,
    ): Map<String, Any>? {
        val buffer = ByteArray(8192)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return null

            try {
                resolver.openOutputStream(uri)?.use { out ->
                    var read: Int
                    while (input.read(buffer).also { read = it } != -1) {
                        out.write(buffer, 0, read)
                    }
                    out.flush()
                } ?: return null

                val publishValues = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                resolver.update(uri, publishValues, null, null)

                return mapOf(
                    "savedToPublicDownloads" to true,
                    "displayPath" to "Download/$fileName",
                    "uri" to uri.toString(),
                )
            } catch (e: Exception) {
                try {
                    resolver.delete(uri, null, null)
                } catch (_: Exception) {
                }
                throw e
            }
        } else {
            @Suppress("DEPRECATION")
            val downloadsDir =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (downloadsDir == null) return null
            if (!downloadsDir.exists()) {
                downloadsDir.mkdirs()
            }
            val targetFile = uniqueTargetFile(downloadsDir, fileName)
            FileOutputStream(targetFile).use { out ->
                var read: Int
                while (input.read(buffer).also { read = it } != -1) {
                    out.write(buffer, 0, read)
                }
                out.flush()
            }
            return mapOf(
                "savedToPublicDownloads" to true,
                "displayPath" to "Download/${targetFile.name}",
                "filePath" to targetFile.absolutePath,
            )
        }
    }

    private fun uniqueTargetFile(dir: File, fileName: String): File {
        var candidate = File(dir, fileName)
        if (!candidate.exists()) return candidate

        val dotIdx = fileName.lastIndexOf('.')
        val base = if (dotIdx > 0) fileName.substring(0, dotIdx) else fileName
        val ext = if (dotIdx > 0) fileName.substring(dotIdx) else ""

        var counter = 1
        while (candidate.exists()) {
            candidate = File(dir, "${base}_$counter$ext")
            counter++
        }
        return candidate
    }
}
