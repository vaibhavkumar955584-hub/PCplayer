package com.example.veloplayer.velo_player

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val MEDIA_SCANNER_CHANNEL = "com.example.veloplayer/media_scanner"
    private val THUMBNAILS_CHANNEL = "com.example.veloplayer/thumbnails"
    private val PERMISSION_REQUEST_CODE = 1001

    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Media Scanner Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    permissionResult = result
                    requestMediaPermission()
                }
                "hasPermission" -> {
                    result.success(hasMediaPermission())
                }
                "queryVideos" -> {
                    try {
                        val videos = queryMediaStoreVideos()
                        result.success(videos)
                    } catch (e: Exception) {
                        result.error("QUERY_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Thumbnails Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, THUMBNAILS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "generateThumbnail" -> {
                    val videoPath = call.argument<String>("videoPath") ?: ""
                    val outputPath = call.argument<String>("outputPath") ?: ""
                    val width = call.argument<Int>("width") ?: 480
                    val height = call.argument<Int>("height") ?: 270

                    Thread {
                        try {
                            val thumbPath = generateThumbnail(videoPath, outputPath, width, height)
                            runOnUiThread { result.success(thumbPath) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("THUMB_ERROR", e.message, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasMediaPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestMediaPermission() {
        if (hasMediaPermission()) {
            permissionResult?.success(true)
            permissionResult = null
            return
        }

        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_VIDEO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

        ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    private fun queryMediaStoreVideos(): List<Map<String, Any?>> {
        val videos = mutableListOf<Map<String, Any?>>()

        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.TITLE,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.WIDTH,
            MediaStore.Video.Media.HEIGHT,
            MediaStore.Video.Media.MIME_TYPE,
            MediaStore.Video.Media.DATE_ADDED,
        )

        val sortOrder = "${MediaStore.Video.Media.DATE_ADDED} DESC"

        contentResolver.query(
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
            val pathCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val titleCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.TITLE)
            val durationCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
            val sizeCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
            val widthCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH)
            val heightCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT)
            val mimeCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE)
            val dateCol = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)

            while (cursor.moveToNext()) {
                val path = cursor.getString(pathCol) ?: continue
                // Skip if file no longer exists
                if (!File(path).exists()) continue

                videos.add(mapOf(
                    "id" to cursor.getLong(idCol),
                    "path" to path,
                    "title" to (cursor.getString(titleCol) ?: path.substringAfterLast("/")),
                    "duration" to cursor.getLong(durationCol),
                    "size" to cursor.getLong(sizeCol),
                    "width" to cursor.getInt(widthCol),
                    "height" to cursor.getInt(heightCol),
                    "mimeType" to (cursor.getString(mimeCol) ?: "video/mp4"),
                    "dateAdded" to cursor.getLong(dateCol),
                ))
            }
        }

        return videos
    }

    private fun generateThumbnail(videoPath: String, outputPath: String, width: Int, height: Int): String? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)
            val bitmap = retriever.getFrameAtTime(1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC) // 1 second in
                ?: return null

            val scaled = Bitmap.createScaledBitmap(bitmap, width, height, true)

            val outFile = File(outputPath)
            outFile.parentFile?.mkdirs()

            FileOutputStream(outFile).use { fos ->
                scaled.compress(Bitmap.CompressFormat.JPEG, 85, fos)
            }

            if (scaled != bitmap) scaled.recycle()
            bitmap.recycle()

            outputPath
        } catch (e: Exception) {
            null
        } finally {
            try { retriever.release() } catch (_: Exception) {}
        }
    }
}
