package com.autoclip.app

import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.autoclip.app/native"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openGallery" -> {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "video/*")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            // Fallback to generic gallery intent
                            val fallbackIntent = Intent(Intent.ACTION_VIEW).apply {
                                type = "video/*"
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(fallbackIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("GALLERY_OPEN_FAILED", e2.localizedMessage, null)
                        }
                    }
                }
                "scanMediaFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(filePath),
                            arrayOf("video/mp4")
                        ) { path, uri ->
                            // Scanned successfully
                        }
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "File path was null", null)
                    }
                }
                "getAutoClipStorageDir" -> {
                    try {
                        val moviesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
                        val autoClipDir = File(moviesDir, "AutoClip")
                        if (!autoClipDir.exists()) {
                            autoClipDir.mkdirs()
                        }
                        result.success(autoClipDir.absolutePath)
                    } catch (e: Exception) {
                        result.error("DIR_ERROR", e.localizedMessage, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
