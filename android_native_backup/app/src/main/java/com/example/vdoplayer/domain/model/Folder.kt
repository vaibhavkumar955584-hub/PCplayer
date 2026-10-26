package com.example.vdoplayer.domain.model

data class Folder(
    val name: String,
    val videoCount: Int,
    val size: Long,
    val firstVideoThumbnail: android.net.Uri? = null
)
