package com.example.vdoplayer.ui.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.vdoplayer.data.repository.VideoRepository
import com.example.vdoplayer.domain.model.Folder
import com.example.vdoplayer.domain.model.Video
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class LibraryViewModel(private val repository: VideoRepository) : ViewModel() {

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery

    private val _selectedTab = MutableStateFlow(1) // 0: All, 1: Folders, 2: Favorites, 3: Recent
    val selectedTab: StateFlow<Int> = _selectedTab

    val allVideos: StateFlow<List<Video>> = repository.allVideos
        .combine(_searchQuery) { videos, query ->
            if (query.isEmpty()) videos else videos.filter { it.title.contains(query, ignoreCase = true) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val folders: StateFlow<List<Folder>> = allVideos
        .combine(_searchQuery) { videos, _ -> // searchQuery already applied to allVideos but keeping combine if needed
            repository.getFolders(videos)
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val favoriteVideos: StateFlow<List<Video>> = repository.favoriteVideos
        .combine(_searchQuery) { videos, query ->
            if (query.isEmpty()) videos else videos.filter { it.title.contains(query, ignoreCase = true) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val recentVideos: StateFlow<List<Video>> = repository.watchHistory
        .combine(_searchQuery) { videos, query ->
            if (query.isEmpty()) videos else videos.filter { it.title.contains(query, ignoreCase = true) }
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun refresh() {
        viewModelScope.launch {
            try {
                repository.refreshVideos()
                Log.d("LibraryViewModel", "Videos refreshed successfully")
            } catch (e: Exception) {
                Log.e("LibraryViewModel", "Failed to refresh videos", e)
            }
        }
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun onTabSelected(index: Int) {
        _selectedTab.value = index
    }

    fun toggleFavorite(video: Video) {
        viewModelScope.launch {
            repository.toggleFavorite(video.id, !video.isFavorite)
        }
    }
}
