package com.example.vdoplayer.data.repository

import android.content.ContentUris
import android.provider.MediaStore
import com.example.vdoplayer.data.local.dao.VideoDao
import com.example.vdoplayer.data.local.entity.VideoEntity
import com.example.vdoplayer.data.scanner.VideoScanner
import com.example.vdoplayer.domain.model.Folder
import com.example.vdoplayer.domain.model.Video
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class VideoRepository(
    private val videoDao: VideoDao,
    private val videoScanner: VideoScanner
) {
    val allVideos: Flow<List<Video>> = videoDao.getAllVideos().map { entities ->
        entities.map { it.toDomain() }
    }

    val favoriteVideos: Flow<List<Video>> = videoDao.getFavoriteVideos().map { entities ->
        entities.map { it.toDomain() }
    }

    val watchHistory: Flow<List<Video>> = videoDao.getWatchHistory().map { entities ->
        entities.map { it.toDomain() }
    }

    suspend fun refreshVideos() {
        val scannedVideos = videoScanner.scanVideos()
        val entities = scannedVideos.map { video ->
            val existing = videoDao.getVideoById(video.id)
            VideoEntity(
                id = video.id,
                title = video.title,
                path = video.path,
                folderName = video.folderName,
                duration = video.duration,
                size = video.size,
                dateAdded = video.dateAdded,
                mimeType = video.mimeType,
                lastPlaybackPosition = existing?.lastPlaybackPosition ?: 0,
                isFavorite = existing?.isFavorite ?: false
            )
        }
        videoDao.insertVideos(entities)
    }

    suspend fun updatePlaybackPosition(videoId: Long, position: Long) {
        videoDao.updatePlaybackPosition(videoId, position)
    }

    suspend fun toggleFavorite(videoId: Long, isFavorite: Boolean) {
        videoDao.updateFavoriteStatus(videoId, isFavorite)
    }

    fun getFolders(videos: List<Video>): List<Folder> {
        return videos.groupBy { it.folderName }
            .map { (name, folderVideos) ->
                val totalSize = folderVideos.sumOf { it.size }
                Folder(
                    name = name,
                    videoCount = folderVideos.size,
                    size = totalSize,
                    firstVideoThumbnail = folderVideos.firstOrNull()?.contentUri
                )
            }
            .sortedBy { it.name }
    }

    private fun VideoEntity.toDomain(): Video {
        return Video(
            id = id,
            title = title,
            path = path,
            folderName = folderName,
            duration = duration,
            size = size,
            dateAdded = dateAdded,
            mimeType = mimeType,
            contentUri = ContentUris.withAppendedId(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id),
            lastPlaybackPosition = lastPlaybackPosition,
            isFavorite = isFavorite
        )
    }
}
