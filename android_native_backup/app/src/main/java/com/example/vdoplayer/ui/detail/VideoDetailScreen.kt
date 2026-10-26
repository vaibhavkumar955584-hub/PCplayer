package com.example.vdoplayer.ui.detail

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.example.vdoplayer.domain.model.Video
import com.example.vdoplayer.ui.components.*
import com.example.vdoplayer.ui.theme.*

@Composable
fun VideoDetailScreen(
    video: Video?,
    onBackClick: () -> Unit,
    onPlayClick: (Long) -> Unit,
    onToggleFavorite: (Video) -> Unit = {}
) {
    val title = video?.title ?: "Dune: Part Two (IMAX 70mm Special Edition)"
    var isFavorite by remember { mutableStateOf(video?.isFavorite ?: false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasBase)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(bottom = 32.dp)
        ) {
            // Top Bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    IconButton(
                        onClick = onBackClick,
                        modifier = Modifier
                            .size(38.dp)
                            .clip(CircleShape)
                            .background(SurfaceElevation1)
                            .border(1.dp, HairlineBorder, CircleShape)
                    ) {
                        Icon(
                            Icons.AutoMirrored.Rounded.ArrowBack,
                            contentDescription = "Back",
                            tint = TextPrimary,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    VeloLogoMark(size = 32.dp)

                    Text(
                        text = "Velo",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = TextPrimary
                    )
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = "Video Details",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary
                    )

                    IconButton(
                        onClick = {
                            isFavorite = !isFavorite
                            if (video != null) onToggleFavorite(video)
                        },
                        modifier = Modifier.size(34.dp)
                    ) {
                        Icon(
                            imageVector = if (isFavorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder,
                            contentDescription = "Favorite",
                            tint = if (isFavorite) PrimaryContainer else TextSecondary,
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    IconButton(onClick = { }, modifier = Modifier.size(34.dp)) {
                        Icon(Icons.Rounded.Share, contentDescription = "Share", tint = TextSecondary, modifier = Modifier.size(18.dp))
                    }

                    IconButton(onClick = { }, modifier = Modifier.size(34.dp)) {
                        Icon(Icons.Rounded.MoreVert, contentDescription = "More", tint = TextSecondary, modifier = Modifier.size(18.dp))
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Cinematic Preview Viewport Card
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .aspectRatio(16 / 9f)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFF19120D))
                    .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            ) {
                if (video?.contentUri != null && video.contentUri != android.net.Uri.EMPTY) {
                    val context = LocalContext.current
                    AsyncImage(
                        model = ImageRequest.Builder(context)
                            .data(video.contentUri)
                            .crossfade(true)
                            .build(),
                        contentDescription = title,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(
                                Brush.radialGradient(
                                    colors = listOf(Color(0xFFA65814), Color(0xFF331D0E), Color(0xFF0F0B08)),
                                    radius = 700f
                                )
                            )
                    )
                }

                // Badges top-left
                Row(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    SpecChip(text = "IMAX 70MM", isHighlight = false)
                    SpecChip(text = "HDR10+", isHighlight = true)
                }

                // Center Play Button
                VeloPlayButton(
                    onClick = { onPlayClick(video?.id ?: 100L) },
                    size = 56.dp,
                    modifier = Modifier.align(Alignment.Center)
                )

                // Progress Indicator Line at bottom
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .align(Alignment.BottomCenter)
                        .background(Color.White.copy(alpha = 0.15f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.45f)
                            .fillMaxHeight()
                            .background(PrimaryContainer)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Title & Quick Specs
            Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineSmall.copy(fontSize = 18.sp),
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(Icons.Rounded.Schedule, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(14.dp))
                        Text(
                            text = if (video != null && video.duration > 0) formatDurationLong(video.duration) else "2h 46m",
                            style = CodeTimeStyle.copy(fontSize = 12.sp),
                            color = TextSecondary
                        )
                    }

                    Text("•", color = TextTertiary, fontSize = 12.sp)

                    SpecChip(text = "4K UHD", isHighlight = true)

                    Text("•", color = TextTertiary, fontSize = 12.sp)

                    Text(
                        text = if (video != null && video.size > 0) formatSizeGB(video.size) else "14.8 GB",
                        style = MaterialTheme.typography.bodySmall,
                        color = TextSecondary
                    )

                    Text("•", color = TextTertiary, fontSize = 12.sp)

                    Text(
                        text = "MKV",
                        style = CodeBadgeStyle.copy(fontSize = 11.sp),
                        color = TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Big Capsule Action Button: Resume (01:14:28)
                Button(
                    onClick = { onPlayClick(video?.id ?: 100L) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .shadow(16.dp, RoundedCornerShape(26.dp), spotColor = PrimaryContainer.copy(alpha = 0.5f)),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = PrimaryContainer,
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(26.dp)
                ) {
                    Icon(
                        Icons.Rounded.PlayCircle,
                        contentDescription = null,
                        modifier = Modifier.size(22.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Resume (01:14:28)",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Secondary Action Pills: + Playlist, Favorite, Start Over
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    ActionPill(
                        icon = Icons.Rounded.PlaylistAdd,
                        label = "Playlist",
                        modifier = Modifier.weight(1f),
                        onClick = { }
                    )
                    ActionPill(
                        icon = if (isFavorite) Icons.Rounded.Favorite else Icons.Rounded.FavoriteBorder,
                        label = "Favorite",
                        modifier = Modifier.weight(1f),
                        onClick = {
                            isFavorite = !isFavorite
                            if (video != null) onToggleFavorite(video)
                        }
                    )
                    ActionPill(
                        icon = Icons.Rounded.Replay,
                        label = "Start Over",
                        modifier = Modifier.weight(1f),
                        onClick = { onPlayClick(video?.id ?: 100L) }
                    )
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Continue Watching Card
                ContinueWatchingProgressCard()

                Spacer(modifier = Modifier.height(18.dp))

                // Technical Specifications Pro Profile Card
                TechSpecsProCard()

                Spacer(modifier = Modifier.height(24.dp))

                // Next in Folder Queue
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(Icons.Rounded.QueueMusic, contentDescription = null, tint = AccentCyan, modifier = Modifier.size(18.dp))
                        Text(
                            text = "Next in Sci-Fi Folder",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                    }

                    Text(
                        text = "1 of 8",
                        style = CodeBadgeStyle,
                        color = TextTertiary
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Next Video Item
                NextFolderVideoRow(
                    title = "Blade Runner 2049",
                    duration = "2h 43m",
                    specs = "4K • 11.4 GB • HEVC",
                    onPlay = { onPlayClick(201L) }
                )
            }
        }
    }
}

@Composable
private fun ActionPill(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Row(
        modifier = modifier
            .height(44.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Icon(icon, contentDescription = label, tint = TextSecondary, modifier = Modifier.size(18.dp))
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = TextPrimary
        )
    }
}

@Composable
private fun ContinueWatchingProgressCard() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(Icons.Rounded.PlayCircleOutline, contentDescription = null, tint = AccentCyan, modifier = Modifier.size(20.dp))
                Text(
                    text = "Continue Watching",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary
                )
            }
            Text(
                text = "45%",
                style = CodeBadgeStyle.copy(fontSize = 12.sp),
                color = AccentCyan
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(Color.White.copy(alpha = 0.15f))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(0.45f)
                    .fillMaxHeight()
                    .background(PrimaryContainer)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "1h 31m remaining",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary
            )
            Text(
                text = "Yesterday, 11:42 PM",
                style = MaterialTheme.typography.bodySmall,
                color = TextTertiary
            )
        }
    }
}

@Composable
private fun TechSpecsProCard() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            .padding(16.dp)
    ) {
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
                    text = "Technical Specifications",
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.Bold,
                    color = TextPrimary
                )
            }

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.White.copy(alpha = 0.08f))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "PRO PROFILE",
                    style = CodeBadgeStyle,
                    color = TextSecondary
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // 2x2 Specs Grid
        Row(modifier = Modifier.fillMaxWidth()) {
            SpecCell(title = "RESOLUTION", value = "3840 × 2160", sub = "4K Ultra HD (2160p)", modifier = Modifier.weight(1f))
            SpecCell(title = "VIDEO CODEC", value = "HEVC / H.265", sub = "Main 10 @ L5.1", modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(14.dp))

        Row(modifier = Modifier.fillMaxWidth()) {
            SpecCell(title = "FRAME RATE", value = "23.976 fps", sub = "Standard 24p Native", modifier = Modifier.weight(1f))
            SpecCell(title = "BITRATE", value = "14.2 Mbps", sub = "Variable (VBR Peak 38M)", modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Audio Stream Subcard
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(10.dp))
                .background(SurfaceElevation2)
                .border(1.dp, HairlineBorder, RoundedCornerShape(10.dp))
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(SurfaceElevation1),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Rounded.GraphicEq, contentDescription = null, tint = AccentCyan, modifier = Modifier.size(20.dp))
            }

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text("AUDIO STREAM", style = CodeBadgeStyle, color = TextTertiary)
                    SpecChip(text = "DOLBY ATMOS", isHighlight = true)
                }
                Text("Dolby TrueHD with Dolby Atmos", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                Text("8 Channels • 48.0 kHz • 24-bit Depth", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Subtitles
        Text("AVAILABLE SUBTITLES", style = CodeBadgeStyle, color = TextTertiary)
        Spacer(modifier = Modifier.height(6.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            SubtitleChip("English (SRT)")
            SubtitleChip("Spanish (PGS)")
            SubtitleChip("French (SRT)")
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Storage Path
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(8.dp))
                .background(SurfaceElevation2)
                .padding(horizontal = 10.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(Icons.Rounded.FolderOpen, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text("Local Storage Path", style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp), color = TextTertiary)
                Text(
                    text = "/storage/emulated/0/Movies/Sci-Fi/...",
                    style = CodeTimeStyle.copy(fontSize = 11.sp),
                    color = TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Text("Oct 24, 2024", style = MaterialTheme.typography.bodySmall.copy(fontSize = 10.sp), color = TextTertiary)
        }
    }
}

@Composable
private fun SpecCell(
    title: String,
    value: String,
    sub: String,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(text = title, style = CodeBadgeStyle, color = TextTertiary)
        Spacer(modifier = Modifier.height(2.dp))
        Text(text = value, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
        Text(text = sub, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
    }
}

@Composable
private fun SubtitleChip(label: String) {
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(6.dp))
            .background(SurfaceElevation2)
            .border(1.dp, HairlineBorder, RoundedCornerShape(6.dp))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(Icons.Rounded.Subtitles, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(12.dp))
        Text(label, style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp), color = TextPrimary)
    }
}

@Composable
private fun NextFolderVideoRow(
    title: String,
    duration: String,
    specs: String,
    onPlay: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            modifier = Modifier
                .size(76.dp, 52.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(SurfaceElevation2),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Rounded.Movie, contentDescription = null, tint = TextTertiary, modifier = Modifier.size(24.dp))
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(3.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Color.Black.copy(alpha = 0.8f))
                    .padding(horizontal = 4.dp, vertical = 1.dp)
            ) {
                Text(text = duration, style = CodeTimeStyle.copy(fontSize = 10.sp), color = TextPrimary)
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
            Spacer(modifier = Modifier.height(2.dp))
            Text(specs, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        }

        IconButton(
            onClick = onPlay,
            modifier = Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(SurfaceElevation2)
        ) {
            Icon(Icons.Rounded.PlayArrow, contentDescription = "Play", tint = TextPrimary, modifier = Modifier.size(18.dp))
        }
    }
}

private fun formatDurationLong(ms: Long): String {
    val totalSeconds = ms / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
}

private fun formatSizeGB(bytes: Long): String {
    val gb = bytes.toDouble() / (1024 * 1024 * 1024)
    return String.format(java.util.Locale.US, "%.1f GB", gb)
}
