package com.example.vdoplayer.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "videos")
data class VideoEntity(
    @PrimaryKey val id: Long,
    val title: String,
    val path: String,
    val folderName: String,
    val duration: Long,
    val size: Long,
    val dateAdded: Long,
    val mimeType: String,
    val lastPlaybackPosition: Long = 0,
    val isFavorite: Boolean = false
)
