package com.example.vdoplayer.ui.player

import android.app.Activity
import android.content.Context
import android.media.AudioManager
import android.view.ViewGroup
import androidx.annotation.OptIn
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.example.vdoplayer.ui.components.SpecChip
import com.example.vdoplayer.ui.theme.*
import com.example.vdoplayer.ui.viewmodel.PlayerViewModel
import java.util.Locale
import kotlin.math.abs

@OptIn(UnstableApi::class)
@Composable
fun PlayerScreen(
    videoId: Long,
    viewModel: PlayerViewModel,
    onBackClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    val context = LocalContext.current
    val activity = remember(context) { context as? Activity }
    val haptic = LocalHapticFeedback.current
    val video by viewModel.currentVideo.collectAsState()

    val exoPlayer = viewModel.exoPlayer

    val isControlsVisible by viewModel.showControls.collectAsState()
    val playbackPosition by viewModel.currentPosition.collectAsState()
    val duration by viewModel.duration.collectAsState()
    val isPlaying by viewModel.isPlaying.collectAsState()
    val playbackSpeed by viewModel.playbackSpeed.collectAsState()
    val isLocked by viewModel.isLocked.collectAsState()

    var isBuffering by remember { mutableStateOf(false) }
    var resizeMode by remember { mutableIntStateOf(AspectRatioFrameLayout.RESIZE_MODE_FIT) }

    // Gesture States
    var initialBrightness by remember { mutableFloatStateOf(0.5f) }
    var volume by remember { mutableFloatStateOf(0.5f) }
    var gestureInfo by remember { mutableStateOf<String?>(null) }

    // Playback Engine Settings Sheet State
    var showEngineSheet by remember { mutableStateOf(false) }
    var selectedAudioTrack by remember { mutableIntStateOf(0) }
    var selectedSubtitleTrack by remember { mutableIntStateOf(0) }
    var isHardwareAccelerationEnabled by remember { mutableStateOf(true) }

    val audioManager = remember { context.getSystemService(Context.AUDIO_SERVICE) as AudioManager }

    LaunchedEffect(videoId) {
        viewModel.loadVideo(videoId)
    }

    val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_STOP) {
                viewModel.saveCurrentPosition()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)

        val listener = object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                isBuffering = state == Player.STATE_BUFFERING
            }
        }
        exoPlayer.addListener(listener)
        onDispose {
            viewModel.saveCurrentPosition()
            exoPlayer.removeListener(listener)
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black) // True Black OLED canvas
            .pointerInput(Unit) {
                detectTapGestures(onTap = {
                    if (isControlsVisible) viewModel.hideControlsWithDelay() else viewModel.showControls()
                })
            }
            .pointerInput(isLocked) {
                if (isLocked) return@pointerInput
                var isAdjustingBrightness = false
                var isAdjustingVolume = false

                detectDragGestures(
                    onDragStart = { offset ->
                        val isLeftSide = offset.x < size.width / 2
                        isAdjustingBrightness = isLeftSide
                        isAdjustingVolume = !isLeftSide

                        activity?.let {
                            if (isLeftSide) {
                                initialBrightness = it.window.attributes.screenBrightness
                                if (initialBrightness < 0) initialBrightness = 0.5f
                            }
                        }
                    },
                    onDragEnd = {
                        isAdjustingBrightness = false
                        isAdjustingVolume = false
                        gestureInfo = null
                    },
                    onDragCancel = {
                        isAdjustingBrightness = false
                        isAdjustingVolume = false
                        gestureInfo = null
                    },
                    onDrag = { _, dragAmount ->
                        val width = size.width
                        val height = size.height

                        if (abs(dragAmount.y) > abs(dragAmount.x)) {
                            // Vertical Drag
                            if (isAdjustingBrightness) {
                                initialBrightness = (initialBrightness - dragAmount.y / height).coerceIn(0f, 1f)
                                gestureInfo = "Brightness: ${(initialBrightness * 100).toInt()}%"
                                activity?.let { setBrightness(it, initialBrightness) }
                            } else if (isAdjustingVolume) {
                                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                                val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                                volume = (currentVolume.toFloat() / maxVolume - dragAmount.y / height).coerceIn(0f, 1f)
                                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, (volume * maxVolume).toInt(), 0)
                                gestureInfo = "Volume: ${(volume * 100).toInt()}%"
                            }
                        } else {
                            // Horizontal Drag: Seeking
                            val seekAmount = (dragAmount.x / width * duration).toLong()
                            viewModel.seekTo((playbackPosition + seekAmount).coerceIn(0, duration))
                            gestureInfo = "Seek: ${formatTimestamp(playbackPosition + seekAmount)}"
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        }
                    }
                )
            }
    ) {
        AndroidView(
            factory = { ctx ->
                PlayerView(ctx).apply {
                    player = exoPlayer
                    useController = false
                    layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                }
            },
            update = { view ->
                view.resizeMode = resizeMode
            },
            modifier = Modifier.fillMaxSize()
        )

        if (isBuffering) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.Center).size(52.dp),
                color = AccentCyan
            )
        }

        // Overlay Controls
        AnimatedVisibility(
            visible = isControlsVisible,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            CinematicPlayerControls(
                title = video?.title ?: "Dune: Part Two (IMAX 70mm Special Edition)",
                isPlaying = isPlaying,
                playbackPosition = playbackPosition,
                duration = duration,
                playbackSpeed = playbackSpeed,
                isLocked = isLocked,
                onBackClick = onBackClick,
                onPlayPauseClick = {
                    viewModel.playPause()
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                },
                onSeek = { viewModel.seekTo(it) },
                onSkipBackward = { viewModel.skipBackward() },
                onSkipForward = { viewModel.skipForward() },
                onResizeClick = {
                    resizeMode = when (resizeMode) {
                        AspectRatioFrameLayout.RESIZE_MODE_FIT -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                        AspectRatioFrameLayout.RESIZE_MODE_ZOOM -> AspectRatioFrameLayout.RESIZE_MODE_FILL
                        else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
                    }
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                },
                onSpeedClick = { showEngineSheet = true },
                onAudioClick = { showEngineSheet = true },
                onSubtitleClick = { showEngineSheet = true },
                onLockClick = { viewModel.toggleLock() },
                onSettingsClick = { showEngineSheet = true }
            )
        }

        gestureInfo?.let {
            Surface(
                modifier = Modifier.align(Alignment.Center),
                color = Color.Black.copy(alpha = 0.75f),
                shape = RoundedCornerShape(12.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
            ) {
                Text(
                    text = it,
                    color = TextPrimary,
                    modifier = Modifier.padding(horizontal = 20.dp, vertical = 12.dp),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        // Playback Engine Settings Modal Sheet
        if (showEngineSheet) {
            PlaybackEngineBottomSheet(
                currentSpeed = playbackSpeed,
                onSpeedSelected = {
                    viewModel.setPlaybackSpeed(it)
                },
                selectedAudioTrack = selectedAudioTrack,
                onAudioTrackSelected = { selectedAudioTrack = it },
                selectedSubtitleTrack = selectedSubtitleTrack,
                onSubtitleTrackSelected = { selectedSubtitleTrack = it },
                isHardwareAccelerationEnabled = isHardwareAccelerationEnabled,
                onHardwareAccelerationToggle = { isHardwareAccelerationEnabled = it },
                onDismiss = { showEngineSheet = false }
            )
        }
    }
}

@Composable
private fun CinematicPlayerControls(
    title: String,
    isPlaying: Boolean,
    playbackPosition: Long,
    duration: Long,
    playbackSpeed: Float,
    isLocked: Boolean,
    onBackClick: () -> Unit,
    onPlayPauseClick: () -> Unit,
    onSeek: (Long) -> Unit,
    onSkipBackward: () -> Unit,
    onSkipForward: () -> Unit,
    onResizeClick: () -> Unit,
    onSpeedClick: () -> Unit,
    onAudioClick: () -> Unit,
    onSubtitleClick: () -> Unit,
    onLockClick: () -> Unit,
    onSettingsClick: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Scrim Gradients
        if (!isLocked) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(140.dp)
                    .align(Alignment.TopCenter)
                    .background(Brush.verticalGradient(listOf(Color.Black.copy(alpha = 0.85f), Color.Transparent)))
            )
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
                    .align(Alignment.BottomCenter)
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.9f))))
            )
        }

        // TOP CONTROLS BAR
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            if (!isLocked) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    IconButton(
                        onClick = onBackClick,
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(SurfaceElevation2.copy(alpha = 0.8f))
                            .border(1.dp, HairlineBorder, CircleShape)
                    ) {
                        Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = "Back", tint = TextPrimary, modifier = Modifier.size(18.dp))
                    }

                    Column(modifier = Modifier.padding(end = 8.dp)) {
                        Text(
                            text = title,
                            color = TextPrimary,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            SpecChip(text = "4K HDR", isHighlight = true)
                            SpecChip(text = "HEVC 10-BIT", isHighlight = false)
                        }
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    IconButton(
                        onClick = { },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(SurfaceElevation2.copy(alpha = 0.8f))
                            .border(1.dp, HairlineBorder, CircleShape)
                    ) {
                        Icon(Icons.Rounded.PictureInPictureAlt, contentDescription = "PiP", tint = TextPrimary, modifier = Modifier.size(18.dp))
                    }

                    IconButton(
                        onClick = { },
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(SurfaceElevation2.copy(alpha = 0.8f))
                            .border(1.dp, HairlineBorder, CircleShape)
                    ) {
                        Icon(Icons.Rounded.Cast, contentDescription = "Cast", tint = TextPrimary, modifier = Modifier.size(18.dp))
                    }

                    IconButton(
                        onClick = onSettingsClick,
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(SurfaceElevation2.copy(alpha = 0.8f))
                            .border(1.dp, HairlineBorder, CircleShape)
                    ) {
                        Icon(Icons.Rounded.MoreVert, contentDescription = "Settings", tint = TextPrimary, modifier = Modifier.size(18.dp))
                    }
                }
            } else {
                Spacer(modifier = Modifier.weight(1f))
            }
        }

        // CENTER PLAYBACK CONTROLS
        if (!isLocked) {
            Row(
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(horizontal = 24.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(20.dp)
            ) {
                // Previous Chapter
                IconButton(
                    onClick = onSkipBackward,
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(SurfaceElevation2.copy(alpha = 0.85f))
                        .border(1.dp, HairlineBorder, CircleShape)
                ) {
                    Icon(Icons.Rounded.SkipPrevious, contentDescription = "Previous", tint = TextPrimary, modifier = Modifier.size(22.dp))
                }

                // Rewind 10s
                IconButton(
                    onClick = onSkipBackward,
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(SurfaceElevation2.copy(alpha = 0.85f))
                        .border(1.dp, HairlineBorder, CircleShape)
                ) {
                    Icon(Icons.Rounded.Replay10, contentDescription = "Rewind 10s", tint = TextPrimary, modifier = Modifier.size(26.dp))
                }

                // Big Center Pause/Play Button (84dp)
                Box(
                    modifier = Modifier
                        .size(84.dp)
                        .shadow(24.dp, CircleShape, spotColor = PrimaryContainer.copy(alpha = 0.8f))
                        .clip(CircleShape)
                        .background(PrimaryContainer)
                        .clickable(onClick = onPlayPauseClick),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = if (isPlaying) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
                        contentDescription = "Play/Pause",
                        tint = Color.White,
                        modifier = Modifier.size(44.dp)
                    )
                }

                // Forward 10s
                IconButton(
                    onClick = onSkipForward,
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(SurfaceElevation2.copy(alpha = 0.85f))
                        .border(1.dp, HairlineBorder, CircleShape)
                ) {
                    Icon(Icons.Rounded.Forward10, contentDescription = "Forward 10s", tint = TextPrimary, modifier = Modifier.size(26.dp))
                }

                // Next Chapter
                IconButton(
                    onClick = onSkipForward,
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(SurfaceElevation2.copy(alpha = 0.85f))
                        .border(1.dp, HairlineBorder, CircleShape)
                ) {
                    Icon(Icons.Rounded.SkipNext, contentDescription = "Next", tint = TextPrimary, modifier = Modifier.size(22.dp))
                }
            }
        }

        // BOTTOM SCRUBBER & TIMELINE
        if (!isLocked) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .navigationBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                // Time stamps & Chapter tag
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = formatTimestamp(playbackPosition),
                            style = CodeTimeStyle,
                            color = TextPrimary
                        )

                        Text("•", color = TextTertiary, fontSize = 12.sp)

                        // Chapter Badge
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(PrimaryContainer.copy(alpha = 0.15f))
                                .border(1.dp, AccentCyan.copy(alpha = 0.35f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "CH. 7 THE PROPHET",
                                style = CodeBadgeStyle,
                                color = AccentCyan
                            )
                        }
                    }

                    val remainingMs = (duration - playbackPosition).coerceAtLeast(0)
                    Text(
                        text = "-${formatTimestamp(remainingMs)}",
                        style = CodeTimeStyle,
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                // Custom High-Precision Scrubber Track with Chapter Segments
                val progress = if (duration > 0) (playbackPosition.toFloat() / duration).coerceIn(0f, 1f) else 0.45f
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(28.dp)
                        .pointerInput(duration) {
                            detectTapGestures { offset ->
                                val targetRatio = (offset.x / size.width).coerceIn(0f, 1f)
                                onSeek((targetRatio * duration).toLong())
                            }
                        },
                    contentAlignment = Alignment.CenterStart
                ) {
                    // Base background track with chapter partitions
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(4.dp)
                            .clip(RoundedCornerShape(2.dp))
                            .background(SurfaceElevation2)
                    ) {
                        // Buffered line
                        Box(
                            modifier = Modifier
                                .fillMaxWidth((progress + 0.18f).coerceAtMost(1f))
                                .fillMaxHeight()
                                .background(Color.White.copy(alpha = 0.25f))
                        )
                        // Played line
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(progress)
                                .fillMaxHeight()
                                .background(PrimaryContainer)
                        )
                    }

                    // Glow Thumb Pip
                    Box(
                        modifier = Modifier
                            .offset(x = 320.dp * progress) // approximate or dynamic offset
                            .size(16.dp)
                            .shadow(8.dp, CircleShape, spotColor = PrimaryContainer)
                            .clip(CircleShape)
                            .background(Color.White)
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Quick Action Pill Toggles Row
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        PlayerPillToggle(
                            icon = Icons.Rounded.Speed,
                            label = "${playbackSpeed}x",
                            onClick = onSpeedClick
                        )
                        PlayerPillToggle(
                            icon = Icons.Rounded.GraphicEq,
                            label = "Atmos 7.1",
                            onClick = onAudioClick
                        )
                        PlayerPillToggle(
                            icon = Icons.Rounded.Subtitles,
                            label = "English [CC]",
                            onClick = onSubtitleClick
                        )
                    }

                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        IconButton(
                            onClick = onResizeClick,
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(SurfaceElevation2)
                                .border(1.dp, HairlineBorder, RoundedCornerShape(10.dp))
                        ) {
                            Icon(Icons.Rounded.AspectRatio, contentDescription = "Aspect Ratio", tint = TextSecondary, modifier = Modifier.size(18.dp))
                        }

                        IconButton(
                            onClick = onLockClick,
                            modifier = Modifier
                                .size(36.dp)
                                .clip(RoundedCornerShape(10.dp))
                                .background(SurfaceElevation2)
                                .border(1.dp, HairlineBorder, RoundedCornerShape(10.dp))
                        ) {
                            Icon(Icons.Rounded.LockOpen, contentDescription = "Lock", tint = TextSecondary, modifier = Modifier.size(18.dp))
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Hint footer
                Text(
                    text = "CONTROLS FADE AFTER 3S • TAP ANYWHERE TO TOGGLE",
                    style = CodeBadgeStyle.copy(fontSize = 9.sp),
                    color = TextTertiary,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        } else {
            // Lock State Indicator
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                contentAlignment = Alignment.TopEnd
            ) {
                IconButton(
                    onClick = onLockClick,
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(Color.Black.copy(alpha = 0.6f))
                        .border(1.dp, HairlineBorder, CircleShape)
                ) {
                    Icon(Icons.Rounded.Lock, contentDescription = "Unlock", tint = AccentCyan, modifier = Modifier.size(22.dp))
                }
            }
        }
    }
}

@Composable
private fun PlayerPillToggle(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .height(36.dp)
            .clip(RoundedCornerShape(10.dp))
            .background(SurfaceElevation2)
            .border(1.dp, HairlineBorder, RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(icon, contentDescription = label, tint = AccentCyan, modifier = Modifier.size(16.dp))
        Text(text = label, style = MaterialTheme.typography.labelSmall, color = TextPrimary)
    }
}

@Composable
private fun PlaybackEngineBottomSheet(
    currentSpeed: Float,
    onSpeedSelected: (Float) -> Unit,
    selectedAudioTrack: Int,
    onAudioTrackSelected: (Int) -> Unit,
    selectedSubtitleTrack: Int,
    onSubtitleTrackSelected: (Int) -> Unit,
    isHardwareAccelerationEnabled: Boolean,
    onHardwareAccelerationToggle: (Boolean) -> Unit,
    onDismiss: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.BottomCenter
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
                .background(SurfaceElevation2)
                .border(1.dp, HairlineBorder, RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
                .clickable(enabled = false) { }
                .padding(20.dp)
        ) {
            // Drag Handle
            Box(
                modifier = Modifier
                    .size(36.dp, 4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(TextTertiary.copy(alpha = 0.4f))
                    .align(Alignment.CenterHorizontally)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Icon(Icons.Rounded.Tune, contentDescription = null, tint = AccentCyan, modifier = Modifier.size(20.dp))
                    Text(
                        text = "Playback Engine Settings",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                }

                Text(
                    text = "VELO HW+ ENGINE V4.2",
                    style = CodeBadgeStyle,
                    color = AccentCyan
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            // 1. Playback Speed Section
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Rounded.Speed, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(16.dp))
                    Text("Playback Speed", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                }
                Text("${currentSpeed}x (Normal)", style = CodeBadgeStyle, color = AccentCyan)
            }

            Spacer(modifier = Modifier.height(10.dp))

            val speeds = listOf(0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                speeds.forEach { speed ->
                    val isSelected = currentSpeed == speed
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .height(36.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(if (isSelected) PrimaryContainer else SurfaceElevation1)
                            .border(1.dp, if (isSelected) PrimaryContainer else HairlineBorder, RoundedCornerShape(8.dp))
                            .clickable { onSpeedSelected(speed) },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "${speed}x",
                            style = CodeBadgeStyle,
                            color = if (isSelected) Color.White else TextSecondary
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // 2. Audio Stream Section
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Rounded.GraphicEq, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(16.dp))
                    Text("Audio Stream", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                }
                Text("DTS-HD / E-AC3", style = CodeBadgeStyle, color = TextTertiary)
            }

            Spacer(modifier = Modifier.height(10.dp))

            EngineOptionCard(
                title = "English (Dolby Atmos 7.1)",
                subtitle = "Direct Passthrough • 768 kbps",
                isSelected = selectedAudioTrack == 0,
                onClick = { onAudioTrackSelected(0) }
            )

            Spacer(modifier = Modifier.height(6.dp))

            EngineOptionCard(
                title = "Director Commentary (Denis V.)",
                subtitle = "Stereo AAC • 192 kbps",
                isSelected = selectedAudioTrack == 1,
                onClick = { onAudioTrackSelected(1) }
            )

            Spacer(modifier = Modifier.height(20.dp))

            // 3. Subtitle Track Section
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(Icons.Rounded.Subtitles, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(16.dp))
                    Text("Subtitle Track", style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                }
                Text(
                    text = "+ External SRT",
                    style = MaterialTheme.typography.labelSmall,
                    color = AccentCyan,
                    modifier = Modifier.clickable { }
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            EngineOptionCard(
                title = "English [SDH / CC]",
                subtitle = "Embedded PGS • High Res",
                isSelected = selectedSubtitleTrack == 0,
                onClick = { onSubtitleTrackSelected(0) }
            )

            Spacer(modifier = Modifier.height(6.dp))

            EngineOptionCard(
                title = "Spanish (Latinoamérica)",
                subtitle = "SubRip UTF-8",
                isSelected = selectedSubtitleTrack == 1,
                onClick = { onSubtitleTrackSelected(1) }
            )

            Spacer(modifier = Modifier.height(20.dp))

            // 4. Hardware Acceleration Toggle Switch
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(SurfaceElevation1)
                    .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(SurfaceElevation2),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Rounded.Memory, contentDescription = null, tint = AccentCyan, modifier = Modifier.size(20.dp))
                    }

                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text("Hardware Acceleration", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                            SpecChip(text = "HW+ (Active)", isHighlight = isHardwareAccelerationEnabled)
                        }
                        Text("Zero-copy Vulkan Surface Rendering • 10-bit P010", style = MaterialTheme.typography.bodySmall, color = TextTertiary)
                    }
                }

                Switch(
                    checked = isHardwareAccelerationEnabled,
                    onCheckedChange = onHardwareAccelerationToggle,
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = PrimaryContainer,
                        uncheckedTrackColor = SurfaceElevation2
                    )
                )
            }
        }
    }
}

@Composable
private fun EngineOptionCard(
    title: String,
    subtitle: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(10.dp))
            .background(SurfaceElevation1)
            .border(1.dp, if (isSelected) AccentCyan.copy(alpha = 0.5f) else HairlineBorder, RoundedCornerShape(10.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column {
            Text(text = title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
            Text(text = subtitle, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        }

        RadioButton(
            selected = isSelected,
            onClick = onClick,
            colors = RadioButtonDefaults.colors(
                selectedColor = AccentCyan,
                unselectedColor = TextTertiary
            )
        )
    }
}

private fun formatTimestamp(ms: Long): String {
    val totalSeconds = ms / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        String.format(Locale.getDefault(), "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.getDefault(), "%02d:%02d", minutes, seconds)
    }
}

private fun setBrightness(activity: Activity, brightness: Float) {
    val lp = activity.window.attributes
    lp.screenBrightness = brightness
    activity.window.attributes = lp
}
