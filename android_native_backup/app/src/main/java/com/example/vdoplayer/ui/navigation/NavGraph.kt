package com.example.vdoplayer.ui.navigation

import androidx.compose.material3.adaptive.ExperimentalMaterial3AdaptiveApi
import androidx.compose.material3.adaptive.navigation3.ListDetailSceneStrategy
import androidx.compose.material3.adaptive.navigation3.rememberListDetailSceneStrategy
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.navigation3.runtime.rememberNavBackStack
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.ui.NavDisplay
import com.example.vdoplayer.domain.model.Video
import com.example.vdoplayer.ui.detail.VideoDetailScreen
import com.example.vdoplayer.ui.home.HomeScreen
import com.example.vdoplayer.ui.library.LibraryScreen
import com.example.vdoplayer.ui.library.VideoListScreen
import com.example.vdoplayer.ui.player.PlayerScreen
import com.example.vdoplayer.ui.settings.SettingsScreen
import com.example.vdoplayer.ui.viewmodel.LibraryViewModel
import com.example.vdoplayer.ui.viewmodel.PlayerViewModel
import com.example.vdoplayer.ui.viewmodel.SettingsViewModel

@OptIn(ExperimentalMaterial3AdaptiveApi::class)
@Composable
fun VdoNavGraph(
    libraryViewModel: LibraryViewModel,
    playerViewModel: PlayerViewModel,
    settingsViewModel: SettingsViewModel
) {
    val backStack = rememberNavBackStack(Route.Home)
    val listDetailStrategy = rememberListDetailSceneStrategy<NavKey>()

    val allVideos by libraryViewModel.allVideos.collectAsState()
    val folders by libraryViewModel.folders.collectAsState()
    val favoriteVideos by libraryViewModel.favoriteVideos.collectAsState()
    val recentVideos by libraryViewModel.recentVideos.collectAsState()
    val searchQuery by libraryViewModel.searchQuery.collectAsState()

    fun navigateToTab(tabName: String) {
        val targetRoute = when (tabName.lowercase()) {
            "home" -> Route.Home
            "library" -> Route.Library
            "playlists" -> Route.Library
            "settings" -> Route.Settings
            else -> Route.Home
        }
        if (backStack.lastOrNull() != targetRoute) {
            // Keep stack clean on bottom tab navigation
            while (backStack.size > 1) {
                backStack.removeAt(backStack.size - 1)
            }
            if (backStack.firstOrNull() != targetRoute) {
                backStack.removeAt(0)
                backStack.add(targetRoute)
            }
        }
    }

    NavDisplay(
        backStack = backStack,
        onBack = {
            if (backStack.size > 1) {
                backStack.removeAt(backStack.size - 1)
            }
        },
        sceneStrategy = listDetailStrategy,
        entryProvider = entryProvider {
            entry<Route.Home>(
                metadata = ListDetailSceneStrategy.listPane()
            ) {
                HomeScreen(
                    videos = allVideos,
                    recentVideos = recentVideos,
                    folders = folders,
                    onVideoClick = { video ->
                        backStack.add(Route.Player(video.id))
                    },
                    onVideoDetailClick = { video ->
                        backStack.add(Route.VideoDetail(video.id))
                    },
                    onFolderClick = { folderName ->
                        backStack.add(Route.FolderDetail(folderName))
                    },
                    onNavigateTab = ::navigateToTab,
                    searchQuery = searchQuery,
                    onSearchQueryChange = libraryViewModel::onSearchQueryChange
                )
            }

            entry<Route.Library>(
                metadata = ListDetailSceneStrategy.listPane()
            ) {
                LibraryScreen(
                    videos = allVideos,
                    folders = folders,
                    favoriteVideos = favoriteVideos,
                    onVideoClick = { video ->
                        backStack.add(Route.Player(video.id))
                    },
                    onVideoDetailClick = { video ->
                        backStack.add(Route.VideoDetail(video.id))
                    },
                    onFolderClick = { folder ->
                        backStack.add(Route.FolderDetail(folder.name))
                    },
                    onNavigateTab = ::navigateToTab,
                    onRefresh = libraryViewModel::refresh
                )
            }

            entry<Route.VideoDetail>(
                metadata = ListDetailSceneStrategy.detailPane()
            ) { key ->
                val video = allVideos.find { it.id == key.videoId }
                    ?: recentVideos.find { it.id == key.videoId }
                VideoDetailScreen(
                    video = video,
                    onBackClick = {
                        if (backStack.size > 1) {
                            backStack.removeAt(backStack.size - 1)
                        }
                    },
                    onPlayClick = { id ->
                        backStack.add(Route.Player(id))
                    },
                    onToggleFavorite = libraryViewModel::toggleFavorite
                )
            }

            entry<Route.FolderDetail>(
                metadata = ListDetailSceneStrategy.detailPane()
            ) { key ->
                val folderVideos = allVideos.filter { it.folderName == key.folderName }
                VideoListScreen(
                    folderName = key.folderName,
                    videos = folderVideos,
                    onVideoClick = { video ->
                        backStack.add(Route.VideoDetail(video.id))
                    },
                    onBackClick = {
                        if (backStack.size > 1) {
                            backStack.removeAt(backStack.size - 1)
                        }
                    },
                    onToggleFavorite = libraryViewModel::toggleFavorite
                )
            }

            entry<Route.Player> { key ->
                PlayerScreen(
                    videoId = key.videoId,
                    viewModel = playerViewModel,
                    onBackClick = {
                        if (backStack.size > 1) {
                            backStack.removeAt(backStack.size - 1)
                        }
                    },
                    onSettingsClick = {
                        backStack.add(Route.Settings)
                    }
                )
            }

            entry<Route.Settings> {
                SettingsScreen(
                    viewModel = settingsViewModel,
                    onBackClick = {
                        if (backStack.size > 1) {
                            backStack.removeAt(backStack.size - 1)
                        } else {
                            navigateToTab("Home")
                        }
                    },
                    onNavigateTab = ::navigateToTab
                )
            }
        }
    )
}
