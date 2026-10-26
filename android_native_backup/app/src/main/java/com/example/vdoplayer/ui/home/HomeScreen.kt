package com.example.vdoplayer.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.request.ImageRequest
import com.example.vdoplayer.domain.model.Folder
import com.example.vdoplayer.domain.model.Video
import com.example.vdoplayer.ui.components.*
import com.example.vdoplayer.ui.theme.*

@Composable
fun HomeScreen(
    videos: List<Video>,
    recentVideos: List<Video>,
    folders: List<Folder>,
    onVideoClick: (Video) -> Unit,
    onVideoDetailClick: (Video) -> Unit,
    onFolderClick: (String) -> Unit,
    onNavigateTab: (String) -> Unit,
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasBase)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 90.dp)
        ) {
            // Top App Bar
            item {
                VeloTopBar(
                    title = "Velo",
                    subtitle = "Home"
                )
            }

            // Search Bar
            item {
                Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
                    VeloSearchBar(
                        query = searchQuery,
                        onQueryChange = onSearchQueryChange
                    )
                }
            }

            // CONTINUE WATCHING HERO SECTION
            item {
                Spacer(modifier = Modifier.height(18.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Continue Watching",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(SurfaceElevation2)
                                .border(1.dp, HairlineBorder, RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "2 LEFT",
                                style = CodeBadgeStyle,
                                color = TextSecondary
                            )
                        }
                    }

                    Text(
                        text = "History",
                        style = MaterialTheme.typography.labelMedium,
                        color = AccentCyan,
                        modifier = Modifier.clickable { onNavigateTab("Library") }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Hero Featured Card (Dune Part Two)
                HeroContinueWatchingCard(
                    video = recentVideos.firstOrNull() ?: videos.firstOrNull(),
                    onPlayClick = {
                        val v = recentVideos.firstOrNull() ?: videos.firstOrNull()
                        if (v != null) onVideoClick(v)
                    },
                    onCardClick = {
                        val v = recentVideos.firstOrNull() ?: videos.firstOrNull()
                        if (v != null) onVideoDetailClick(v)
                    }
                )
            }

            // RECENTLY ADDED SECTION
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Recently Added",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = "${videos.size.coerceAtLeast(12)} files",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextTertiary
                        )
                    }

                    Text(
                        text = "See All",
                        style = MaterialTheme.typography.labelMedium,
                        color = AccentCyan,
                        modifier = Modifier.clickable { onNavigateTab("Library") }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    val displayVideos = if (videos.isNotEmpty()) videos else getMockRecentlyAdded()
                    items(displayVideos) { video ->
                        RecentlyAddedCard(
                            video = video,
                            onClick = { onVideoDetailClick(video) }
                        )
                    }
                }
            }

            // LOCAL FOLDERS SECTION
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Local Folders",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Text(
                            text = "Storage (64% free)",
                            style = MaterialTheme.typography.bodySmall,
                            color = TextTertiary
                        )
                    }

                    Text(
                        text = "View All (${folders.size.coerceAtLeast(4)})",
                        style = MaterialTheme.typography.labelMedium,
                        color = AccentCyan,
                        modifier = Modifier.clickable { onNavigateTab("Library") }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                val folderGrid = if (folders.size >= 4) {
                    folders.take(4).map { FolderGridItem(it.name, "${it.videoCount} videos", Icons.Rounded.Folder) }
                } else {
                    listOf(
                        FolderGridItem("Camera Roll", "48 videos", Icons.Rounded.Videocam),
                        FolderGridItem("Downloads", "14 videos", Icons.Rounded.Download),
                        FolderGridItem("Movies & Series", "8 videos", Icons.Rounded.Movie),
                        FolderGridItem("Recordings", "22 videos", Icons.Rounded.FiberDvr)
                    )
                }

                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        LocalFolderCard(folderGrid[0], modifier = Modifier.weight(1f), onClick = { onFolderClick(folderGrid[0].title) })
                        LocalFolderCard(folderGrid[1], modifier = Modifier.weight(1f), onClick = { onFolderClick(folderGrid[1].title) })
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        LocalFolderCard(folderGrid[2], modifier = Modifier.weight(1f), onClick = { onFolderClick(folderGrid[2].title) })
                        LocalFolderCard(folderGrid[3], modifier = Modifier.weight(1f), onClick = { onFolderClick(folderGrid[3].title) })
                    }
                }
            }

            // PINNED FAVORITES SECTION
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "Pinned Favorites",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextPrimary
                        )
                        Icon(
                            Icons.Rounded.FavoriteBorder,
                            contentDescription = null,
                            tint = TextSecondary,
                            modifier = Modifier.size(18.dp)
                        )
                    }

                    Text(
                        text = "Manage",
                        style = MaterialTheme.typography.labelMedium,
                        color = AccentCyan,
                        modifier = Modifier.clickable { }
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                val pinnedItems = listOf(
                    PinnedFavorite("Rainy Shinjuku Ambient 4K...", "08:45", "Spatial Audio • 1.1 GB"),
                    PinnedFavorite("Silverstone Hot Lap Onboard...", "15:20", "60 FPS • 2.4 GB")
                )

                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    pinnedItems.forEach { item ->
                        PinnedFavoriteRow(
                            item = item,
                            onPlay = {
                                val v = videos.firstOrNull()
                                if (v != null) onVideoClick(v)
                            }
                        )
                    }
                }
            }
        }

        // Floating Bottom Navigation
        VeloBottomNav(
            currentTab = "Home",
            onTabSelected = onNavigateTab,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}

@Composable
private fun HeroContinueWatchingCard(
    video: Video?,
    onPlayClick: () -> Unit,
    onCardClick: () -> Unit
) {
    val title = video?.title ?: "Dune: Part Two (IMAX 70mm Special Edition)"
    val folderSubtitle = if (video != null) "Watched yesterday • ${video.folderName}" else "Watched yesterday • Downloads > Sci-Fi"

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            .clickable(onClick = onCardClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16 / 9f)
                .background(Color(0xFF1E1712))
        ) {
            // Cinematic Backdrop
            if (video != null && video.contentUri != android.net.Uri.EMPTY) {
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
                // Procedural Desert Dunes Visual Backdrop
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.radialGradient(
                                colors = listOf(Color(0xFFB05B17), Color(0xFF331C0D), Color(0xFF130D08)),
                                radius = 700f
                            )
                        )
                )
            }

            // Top Badges
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    SpecChip(text = "4K HDR", isHighlight = true)
                    SpecChip(text = "DOLBY ATMOS", isHighlight = false)
                }

                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(Color.Black.copy(alpha = 0.5f))
                        .clickable { },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Rounded.BookmarkBorder,
                        contentDescription = "Bookmark",
                        tint = TextPrimary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            // Central Blue Play Button
            VeloPlayButton(
                onClick = onPlayClick,
                size = 56.dp,
                modifier = Modifier.align(Alignment.Center)
            )

            // Scrubber line and Timestamps at bottom of media viewport
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .background(Brush.verticalGradient(listOf(Color.Transparent, Color.Black.copy(alpha = 0.85f))))
                    .padding(horizontal = 12.dp, vertical = 8.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(text = "48:12", style = CodeTimeStyle, color = TextPrimary)
                    Text(text = "2:46:00", style = CodeTimeStyle, color = TextSecondary)
                }
                Spacer(modifier = Modifier.height(6.dp))
                // Progress Bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .clip(RoundedCornerShape(1.5.dp))
                        .background(Color.White.copy(alpha = 0.15f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.29f)
                            .fillMaxHeight()
                            .background(PrimaryContainer)
                    )
                }
            }
        }

        // Details Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = folderSubtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary
                )
            }

            IconButton(
                onClick = { },
                modifier = Modifier.size(28.dp)
            ) {
                Icon(
                    Icons.Rounded.MoreVert,
                    contentDescription = "More",
                    tint = TextSecondary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun RecentlyAddedCard(
    video: Video,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .width(210.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(118.dp)
                .background(Color(0xFF131722))
        ) {
            if (video.contentUri != android.net.Uri.EMPTY) {
                AsyncImage(
                    model = video.contentUri,
                    contentDescription = video.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(
                            Brush.linearGradient(
                                listOf(Color(0xFF192033), Color(0xFF0F121C))
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Rounded.PlayCircle,
                        contentDescription = null,
                        tint = AccentCyan.copy(alpha = 0.4f),
                        modifier = Modifier.size(36.dp)
                    )
                }
            }

            // Badge
            SpecChip(
                text = if (video.title.contains("Interstellar", ignoreCase = true)) "1080P" else "4K AV1",
                isHighlight = !video.title.contains("Interstellar", ignoreCase = true),
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(8.dp)
            )

            // Duration Pill
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(6.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.Black.copy(alpha = 0.75f))
                    .padding(horizontal = 5.dp, vertical = 2.dp)
            ) {
                Text(
                    text = if (video.duration > 0) formatDurationShort(video.duration) else "2h 49m",
                    style = CodeTimeStyle.copy(fontSize = 11.sp),
                    color = TextPrimary
                )
            }
        }

        Column(modifier = Modifier.padding(10.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = video.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    Icons.Rounded.MoreVert,
                    contentDescription = null,
                    tint = TextTertiary,
                    modifier = Modifier.size(16.dp)
                )
            }
            Spacer(modifier = Modifier.height(3.dp))
            Text(
                text = if (video.size > 0) "${formatSizeMB(video.size)} • MKV (HEVC)" else "12.4 GB • MKV (HEVC)",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary
            )
        }
    }
}

private data class FolderGridItem(val title: String, val count: String, val icon: ImageVector)

@Composable
private fun LocalFolderCard(
    item: FolderGridItem,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Row(
        modifier = modifier
            .height(72.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(SurfaceElevation2)
                .border(1.dp, HairlineBorder, RoundedCornerShape(10.dp)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                item.icon,
                contentDescription = item.title,
                tint = AccentCyan,
                modifier = Modifier.size(22.dp)
            )
        }

        Column {
            Text(
                text = item.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                maxLines = 1
            )
            Text(
                text = item.count,
                style = MaterialTheme.typography.bodySmall,
                color = TextTertiary
            )
        }
    }
}

private data class PinnedFavorite(val title: String, val duration: String, val specs: String)

@Composable
private fun PinnedFavoriteRow(
    item: PinnedFavorite,
    onPlay: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(74.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .padding(10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Thumbnail with duration tag
        Box(
            modifier = Modifier
                .size(80.dp, 54.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(SurfaceElevation2),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Rounded.Movie,
                contentDescription = null,
                tint = TextTertiary,
                modifier = Modifier.size(24.dp)
            )
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(3.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Color.Black.copy(alpha = 0.8f))
                    .padding(horizontal = 4.dp, vertical = 1.dp)
            ) {
                Text(
                    text = item.duration,
                    style = CodeTimeStyle.copy(fontSize = 10.sp),
                    color = TextPrimary
                )
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = item.specs,
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary
            )
        }

        // Heart favorite button
        IconButton(onClick = { }, modifier = Modifier.size(34.dp)) {
            Icon(
                Icons.Rounded.FavoriteBorder,
                contentDescription = "Favorite",
                tint = TextSecondary,
                modifier = Modifier.size(20.dp)
            )
        }

        // Circular Blue Play Button
        VeloPlayButton(
            onClick = onPlay,
            size = 36.dp
        )
    }
}

private fun formatDurationShort(ms: Long): String {
    val totalSeconds = ms / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
}

private fun formatSizeMB(bytes: Long): String {
    val gb = bytes.toDouble() / (1024 * 1024 * 1024)
    return if (gb >= 1.0) String.format(java.util.Locale.US, "%.1f GB", gb) else "${bytes / (1024 * 1024)} MB"
}

private fun getMockRecentlyAdded(): List<Video> {
    return listOf(
        Video(
            id = 101,
            title = "Interstellar (2014)...",
            path = "/storage/emulated/0/Movies/Interstellar.mkv",
            folderName = "Movies",
            duration = 169 * 60 * 1000L,
            size = 12400000000L,
            dateAdded = System.currentTimeMillis(),
            mimeType = "video/x-matroska",
            contentUri = android.net.Uri.EMPTY
        ),
        Video(
            id = 102,
            title = "Cyberpunk Edgerunners",
            path = "/storage/emulated/0/Anime/Cyberpunk.mkv",
            folderName = "Anime",
            duration = 24 * 60 * 1000L,
            size = 1800000000L,
            dateAdded = System.currentTimeMillis(),
            mimeType = "video/x-matroska",
            contentUri = android.net.Uri.EMPTY
        )
    )
}
