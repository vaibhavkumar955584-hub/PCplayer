package com.example.vdoplayer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.vdoplayer.data.repository.PlaybackSettingsRepository
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SettingsViewModel(private val repository: PlaybackSettingsRepository) : ViewModel() {

    val autoplayNext: StateFlow<Boolean> = repository.autoplayNext
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), false)

    val defaultSpeed: StateFlow<Float> = repository.defaultSpeed
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 1.0f)

    val smartHdr: StateFlow<Boolean> = repository.smartHdr
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), false)

    val subtitleSize: StateFlow<Float> = repository.subtitleSize
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 1.0f)

    val streamOnWifiOnly: StateFlow<Boolean> = repository.streamOnWifiOnly
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), true)

    private val _cacheSize = kotlinx.coroutines.flow.MutableStateFlow(0L)
    val cacheSize: StateFlow<Long> = _cacheSize

    fun calculateCacheSize(context: android.content.Context) {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val size = getFolderSize(context.cacheDir)
            _cacheSize.value = size
        }
    }

    fun clearCache(context: android.content.Context) {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            context.cacheDir.deleteRecursively()
            context.cacheDir.mkdirs() // Recreate the directory
            calculateCacheSize(context)
        }
    }

    private fun getFolderSize(dir: java.io.File): Long {
        var size = 0L
        if (dir.isDirectory) {
            val files = dir.listFiles()
            if (files != null) {
                for (file in files) {
                    size += if (file.isDirectory) {
                        getFolderSize(file)
                    } else {
                        file.length()
                    }
                }
            }
        } else {
            size = dir.length()
        }
        return size
    }

    fun setAutoplayNext(enabled: Boolean) {
        viewModelScope.launch {
            repository.setAutoplayNext(enabled)
        }
    }

    fun setDefaultSpeed(speed: Float) {
        viewModelScope.launch {
            repository.setDefaultSpeed(speed)
        }
    }

    fun setSmartHdr(enabled: Boolean) {
        viewModelScope.launch {
            repository.setSmartHdr(enabled)
        }
    }

    fun setSubtitleSize(size: Float) {
        viewModelScope.launch {
            repository.setSubtitleSize(size)
        }
    }

    fun setStreamOnWifiOnly(enabled: Boolean) {
        viewModelScope.launch {
            repository.setStreamOnWifiOnly(enabled)
        }
    }
}
