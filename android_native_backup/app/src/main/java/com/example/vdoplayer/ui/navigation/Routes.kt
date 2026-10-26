package com.example.vdoplayer.ui.navigation

import androidx.navigation3.runtime.NavKey
import kotlinx.serialization.Serializable

sealed interface Route : NavKey {
    @Serializable
    data object Home : Route

    @Serializable
    data object Library : Route

    @Serializable
    data class FolderDetail(val folderName: String) : Route

    @Serializable
    data class VideoDetail(val videoId: Long) : Route

    @Serializable
    data class Player(val videoId: Long) : Route

    @Serializable
    data object Playlists : Route

    @Serializable
    data object Settings : Route
}
