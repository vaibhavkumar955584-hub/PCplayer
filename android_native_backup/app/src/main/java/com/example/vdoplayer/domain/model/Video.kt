package com.example.vdoplayer.domain.model

import android.net.Uri

data class Video(
    val id: Long,
    val title: String,
    val path: String,
    val folderName: String,
    val duration: Long,
    val size: Long,
    val dateAdded: Long,
    val mimeType: String,
    val contentUri: Uri,
    val lastPlaybackPosition: Long = 0,
    val isFavorite: Boolean = false
)
