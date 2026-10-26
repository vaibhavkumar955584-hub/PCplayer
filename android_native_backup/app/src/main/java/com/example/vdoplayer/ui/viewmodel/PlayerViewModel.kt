package com.example.vdoplayer.ui.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import com.example.vdoplayer.data.repository.VideoRepository
import com.example.vdoplayer.domain.model.Video
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PlayerViewModel(
    private val repository: VideoRepository,
    context: Context
) : ViewModel() {

    private val _currentVideo = MutableStateFlow<Video?>(null)
    val currentVideo: StateFlow<Video?> = _currentVideo.asStateFlow()

    val exoPlayer = ExoPlayer.Builder(context).build()

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _currentPosition = MutableStateFlow(0L)
    val currentPosition: StateFlow<Long> = _currentPosition.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()
    
    private val _playbackSpeed = MutableStateFlow(1.0f)
    val playbackSpeed: StateFlow<Float> = _playbackSpeed.asStateFlow()
    
    private val _isLocked = MutableStateFlow(false)
    val isLocked: StateFlow<Boolean> = _isLocked.asStateFlow()
    
    private val _showControls = MutableStateFlow(true)
    val showControls: StateFlow<Boolean> = _showControls.asStateFlow()

    private var tickerJob: Job? = null
    private var savePositionJob: Job? = null
    private var controlsHideJob: Job? = null

    init {
        exoPlayer.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) {
                _isPlaying.value = isPlaying
                if (isPlaying) {
                    startTicker()
                    hideControlsWithDelay()
                } else {
                    stopTicker()
                    showControls() // Keep controls visible when paused
                }
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_READY) {
                    _duration.value = exoPlayer.duration.coerceAtLeast(0)
                }
            }
        })
        
        startSavePositionTimer()
    }

    fun loadVideo(videoId: Long) {
        viewModelScope.launch {
            repository.allVideos.collect { videos ->
                val video = videos.find { it.id == videoId }
                if (video != null && _currentVideo.value?.id != videoId) {
                    _currentVideo.value = video
                    val mediaItem = MediaItem.fromUri(video.contentUri)
                    exoPlayer.setMediaItem(mediaItem)
                    if (video.lastPlaybackPosition > 0) {
                        exoPlayer.seekTo(video.lastPlaybackPosition)
                    }
                    exoPlayer.prepare()
                    exoPlayer.play()
                }
            }
        }
    }

    fun playPause() {
        if (exoPlayer.isPlaying) {
            exoPlayer.pause()
        } else {
            exoPlayer.play()
        }
    }

    fun seekTo(position: Long) {
        val clampedPosition = position.coerceIn(0, exoPlayer.duration.coerceAtLeast(0))
        exoPlayer.seekTo(clampedPosition)
        _currentPosition.value = clampedPosition
        hideControlsWithDelay()
    }

    fun skipBackward() {
        seekTo(exoPlayer.currentPosition - 10_000)
    }

    fun skipForward() {
        seekTo(exoPlayer.currentPosition + 10_000)
    }

    fun toggleLock() {
        _isLocked.value = !_isLocked.value
        if (_isLocked.value) {
            hideControlsWithDelay()
        } else {
            showControls()
        }
    }
    
    fun setPlaybackSpeed(speed: Float) {
        _playbackSpeed.value = speed
        exoPlayer.setPlaybackSpeed(speed)
        hideControlsWithDelay()
    }
    
    fun showControls() {
        _showControls.value = true
        controlsHideJob?.cancel()
        if (_isLocked.value) {
            hideControlsWithDelay() // Re-hide quickly when locked
        }
    }
    
    fun hideControlsWithDelay() {
        controlsHideJob?.cancel()
        controlsHideJob = viewModelScope.launch {
            delay(if (_isLocked.value) 2000 else 3000)
            _showControls.value = false
        }
    }

    private fun startTicker() {
        tickerJob?.cancel()
        tickerJob = viewModelScope.launch {
            while (true) {
                _currentPosition.value = exoPlayer.currentPosition
                delay(500)
            }
        }
    }

    private fun stopTicker() {
        tickerJob?.cancel()
    }
    
    private fun startSavePositionTimer() {
        savePositionJob?.cancel()
        savePositionJob = viewModelScope.launch {
            while (true) {
                delay(5000)
                saveCurrentPosition()
            }
        }
    }

    fun saveCurrentPosition() {
        val video = _currentVideo.value
        if (video != null && exoPlayer.currentPosition > 0) {
            viewModelScope.launch {
                repository.updatePlaybackPosition(video.id, exoPlayer.currentPosition)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        saveCurrentPosition()
        exoPlayer.release()
    }
}
