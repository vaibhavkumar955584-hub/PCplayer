package com.example.vdoplayer.data.scanner

import android.content.ContentUris
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import com.example.vdoplayer.domain.model.Video
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class VideoScanner(private val context: Context) {

    suspend fun scanVideos(): List<Video> = withContext(Dispatchers.IO) {
        val videos = mutableListOf<Video>()
        val collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        
        val projection = mutableListOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DISPLAY_NAME,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DURATION,
            MediaStore.Video.Media.SIZE,
            MediaStore.Video.Media.DATE_ADDED,
            MediaStore.Video.Media.MIME_TYPE
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection.add(MediaStore.Video.Media.RELATIVE_PATH)
        }

        val sortOrder = "${MediaStore.Video.Media.DATE_ADDED} DESC"

        try {
            context.contentResolver.query(
                collection,
                projection.toTypedArray(),
                null,
                null,
                sortOrder
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
                val nameColumn = cursor.getColumnIndex(MediaStore.Video.Media.DISPLAY_NAME)
                val dataColumn = cursor.getColumnIndex(MediaStore.Video.Media.DATA)
                val durationColumn = cursor.getColumnIndex(MediaStore.Video.Media.DURATION)
                val sizeColumn = cursor.getColumnIndex(MediaStore.Video.Media.SIZE)
                val dateAddedColumn = cursor.getColumnIndex(MediaStore.Video.Media.DATE_ADDED)
                val mimeTypeColumn = cursor.getColumnIndex(MediaStore.Video.Media.MIME_TYPE)
                
                val relativePathColumn = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    cursor.getColumnIndex(MediaStore.Video.Media.RELATIVE_PATH)
                } else -1
                
                Log.d("VideoScanner", "Found ${cursor.count} videos in MediaStore")

                while (cursor.moveToNext()) {
                    val id = cursor.getLong(idColumn)
                    val name = if (nameColumn != -1) cursor.getString(nameColumn) else "Unknown"
                    val data = if (dataColumn != -1) cursor.getString(dataColumn) else ""
                    val duration = if (durationColumn != -1) cursor.getLong(durationColumn) else 0L
                    val size = if (sizeColumn != -1) cursor.getLong(sizeColumn) else 0L
                    val dateAdded = if (dateAddedColumn != -1) cursor.getLong(dateAddedColumn) else 0L
                    val mimeType = if (mimeTypeColumn != -1) cursor.getString(mimeTypeColumn) else ""
                    val contentUri = ContentUris.withAppendedId(collection, id)

                    var folderName = "Unknown"
                    if (relativePathColumn != -1) {
                        val relPath = cursor.getString(relativePathColumn)
                        if (!relPath.isNullOrEmpty()) {
                            folderName = relPath.trimEnd('/').substringAfterLast('/', relPath.trimEnd('/'))
                        }
                    } else if (data.isNotEmpty()) {
                        folderName = File(data).parentFile?.name ?: "Unknown"
                    }

                    if (size <= 0) continue

                    videos.add(
                        Video(
                            id = id,
                            title = name ?: "Unknown",
                            path = data ?: "",
                            folderName = folderName,
                            duration = duration,
                            size = size,
                            dateAdded = dateAdded,
                            mimeType = mimeType ?: "",
                            contentUri = contentUri
                        )
                    )
                }
            }
        } catch (e: Exception) {
            Log.e("VideoScanner", "Error scanning videos: ${e.message}", e)
            throw e
        }
        videos
    }
}
