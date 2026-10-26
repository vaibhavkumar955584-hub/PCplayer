package com.example.vdoplayer.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
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
fun LibraryScreen(
    videos: List<Video>,
    folders: List<Folder>,
    favoriteVideos: List<Video>,
    onVideoClick: (Video) -> Unit,
    onVideoDetailClick: (Video) -> Unit,
    onFolderClick: (Folder) -> Unit,
    onNavigateTab: (String) -> Unit,
    onRefresh: () -> Unit
) {
    var selectedCategory by remember { mutableIntStateOf(0) } // 0: All, 1: Videos, 2: Folders, 3: Favorites
    var isGridView by remember { mutableStateOf(true) }
    var searchQuery by remember { mutableStateOf("") }
    var isSearchExpanded by remember { mutableStateOf(false) }
    val primaryGridItems = remember { getPrimaryGridItems() }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasBase)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 90.dp)
        ) {
            // Header Top Bar
            item {
                VeloTopBar(
                    title = "Velo",
                    subtitle = "Library"
                )
            }

            // Title & Controls Row
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Library",
                            style = MaterialTheme.typography.headlineMedium,
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
                                text = "INDEXED",
                                style = CodeBadgeStyle,
                                color = TextSecondary
                            )
                        }
                    }

                    Row(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        IconButton(
                            onClick = { isSearchExpanded = !isSearchExpanded },
                            modifier = Modifier.size(34.dp)
                        ) {
                            Icon(Icons.Rounded.Search, contentDescription = "Search", tint = TextSecondary, modifier = Modifier.size(20.dp))
                        }

                        // Recent Sort Pill
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(SurfaceElevation1)
                                .border(1.dp, HairlineBorder, RoundedCornerShape(8.dp))
                                .clickable { }
                                .padding(horizontal = 8.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(Icons.Rounded.Sort, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(14.dp))
                            Text("Recent", style = MaterialTheme.typography.labelSmall, color = TextPrimary)
                            Icon(Icons.Rounded.KeyboardArrowDown, contentDescription = null, tint = TextSecondary, modifier = Modifier.size(14.dp))
                        }

                        // Grid / List Toggles
                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(8.dp))
                                .background(SurfaceElevation1)
                                .border(1.dp, HairlineBorder, RoundedCornerShape(8.dp))
                                .padding(2.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(if (isGridView) PrimaryContainer else Color.Transparent)
                                    .clickable { isGridView = true },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Rounded.GridView, contentDescription = "Grid", tint = if (isGridView) Color.White else TextTertiary, modifier = Modifier.size(16.dp))
                            }
                            Box(
                                modifier = Modifier
                                    .size(28.dp)
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(if (!isGridView) PrimaryContainer else Color.Transparent)
                                    .clickable { isGridView = false },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Rounded.ViewList, contentDescription = "List", tint = if (!isGridView) Color.White else TextTertiary, modifier = Modifier.size(16.dp))
                            }
                        }
                    }
                }
            }

            if (isSearchExpanded) {
                item {
                    Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
                        VeloSearchBar(
                            query = searchQuery,
                            onQueryChange = { searchQuery = it }
                        )
                    }
                }
            }

            // Category Filter Pills
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val categories = listOf(
                        "All ${videos.size.coerceAtLeast(92)}",
                        "Videos ${videos.size.coerceAtLeast(84)}",
                        "Folders ${folders.size.coerceAtLeast(6)}",
                        "Favorites"
                    )

                    categories.forEachIndexed { index, label ->
                        val isSelected = selectedCategory == index
                        val bgColor = if (isSelected) PrimaryContainer else SurfaceElevation1
                        val borderColor = if (isSelected) PrimaryContainer else HairlineBorder
                        val textColor = if (isSelected) Color.White else TextSecondary

                        Row(
                            modifier = Modifier
                                .clip(RoundedCornerShape(20.dp))
                                .background(bgColor)
                                .border(1.dp, borderColor, RoundedCornerShape(20.dp))
                                .clickable { selectedCategory = index }
                                .padding(horizontal = 12.dp, vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            if (isSelected) {
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .clip(CircleShape)
                                        .background(AccentCyan)
                                )
                            }
                            Text(
                                text = label,
                                style = MaterialTheme.typography.labelMedium,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = textColor
                            )
                        }
                    }
                }
            }

            // PRIMARY FILES 2-COLUMN GRID SECTION
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "PRIMARY FILES",
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.Bold,
                        color = TextSecondary
                    )
                    Text(
                        text = "4 ITEMS VIEWED",
                        style = CodeBadgeStyle,
                        color = TextTertiary
                    )
                }

                Column(
                    modifier = Modifier.padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        PrimaryFileCard(
                            item = primaryGridItems[0],
                            modifier = Modifier.weight(1f),
                            onClick = {
                                val v = videos.firstOrNull() ?: primaryGridItems[0].toMockVideo()
                                onVideoDetailClick(v)
                            }
                        )
                        PrimaryFileCard(
                            item = primaryGridItems[1],
                            modifier = Modifier.weight(1f),
                            onClick = {
                                val v = videos.getOrNull(1) ?: primaryGridItems[1].toMockVideo()
                                onVideoDetailClick(v)
                            }
                        )
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        PrimaryFileCard(
                            item = primaryGridItems[2],
                            modifier = Modifier.weight(1f),
                            onClick = {
                                val v = videos.getOrNull(2) ?: primaryGridItems[2].toMockVideo()
                                onVideoDetailClick(v)
                            }
                        )
                        PrimaryFileCard(
                            item = primaryGridItems[3],
                            modifier = Modifier.weight(1f),
                            onClick = {
                                val v = videos.getOrNull(3) ?: primaryGridItems[3].toMockVideo()
                                onVideoDetailClick(v)
                            }
                        )
                    }
                }
            }

            // STORAGE DIRECTORY LISTING
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Text(
                            text = "STORAGE DIRECTORY LISTING",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold,
                            color = TextSecondary
                        )
                        SpecChip(text = "MOVIES/4K", isHighlight = false)
                    }

                    Text(
                        text = "Select All",
                        style = MaterialTheme.typography.labelMedium,
                        color = AccentCyan,
                        modifier = Modifier.clickable { }
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                DirectoryListingCard(
                    title = "Interstellar: Final ...",
                    folder = "Movies/4K",
                    size = "14.2 GB",
                    duration = "2h 11m",
                    onPlay = {
                        val v = videos.firstOrNull() ?: primaryGridItems[0].toMockVideo()
                        onVideoClick(v)
                    },
                    onClick = {
                        val v = videos.firstOrNull() ?: primaryGridItems[0].toMockVideo()
                        onVideoDetailClick(v)
                    }
                )
            }

            // SYNC STATUS BANNER CARD
            item {
                Spacer(modifier = Modifier.height(24.dp))
                DeviceSyncBanner(
                    videoCount = videos.size.coerceAtLeast(92),
                    onRescan = onRefresh
                )
            }
        }

        // Floating Bottom Nav
        VeloBottomNav(
            currentTab = "Library",
            onTabSelected = onNavigateTab,
            modifier = Modifier.align(Alignment.BottomCenter)
        )
    }
}

private data class PrimaryGridItemData(
    val title: String,
    val badge: String,
    val isHighlightBadge: Boolean,
    val duration: String,
    val resumeStatus: String,
    val size: String,
    val progress: Float
) {
    fun toMockVideo(): Video {
        return Video(
            id = title.hashCode().toLong(),
            title = title,
            path = "/storage/emulated/0/Movies/$title.mkv",
            folderName = "Movies",
            duration = 120 * 60 * 1000L,
            size = 14000000000L,
            dateAdded = System.currentTimeMillis(),
            mimeType = "video/x-matroska",
            contentUri = android.net.Uri.EMPTY
        )
    }
}

@Composable
private fun PrimaryFileCard(
    item: PrimaryGridItemData,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(14.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(16 / 10f)
                .background(Color(0xFF151926))
        ) {
            // Gradient atmosphere background
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color(0xFF1E2638), Color(0xFF10131A))
                        )
                    )
            )

            // Spec Chip
            SpecChip(
                text = item.badge,
                isHighlight = item.isHighlightBadge,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(8.dp)
            )

            // Duration tag
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(Color.Black.copy(alpha = 0.8f))
                    .padding(horizontal = 5.dp, vertical = 2.dp)
            ) {
                Text(
                    text = item.duration,
                    style = CodeTimeStyle.copy(fontSize = 11.sp),
                    color = TextPrimary
                )
            }

            // Embedded progress line along the bottom edge
            if (item.progress > 0f) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .align(Alignment.BottomCenter)
                        .background(Color.White.copy(alpha = 0.15f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(item.progress)
                            .fillMaxHeight()
                            .background(PrimaryContainer)
                    )
                }
            }
        }

        Column(modifier = Modifier.padding(10.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = item.title,
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

            Spacer(modifier = Modifier.height(4.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = item.resumeStatus,
                    style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                    color = if (item.resumeStatus.startsWith("Resume")) AccentCyan else TextTertiary
                )
                Text(
                    text = item.size,
                    style = MaterialTheme.typography.bodySmall.copy(fontSize = 11.sp),
                    color = TextTertiary
                )
            }
        }
    }
}

@Composable
private fun DirectoryListingCard(
    title: String,
    folder: String,
    size: String,
    duration: String,
    onPlay: () -> Unit,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .height(72.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Thumbnail with duration
        Box(
            modifier = Modifier
                .size(76.dp, 52.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(SurfaceElevation2),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Rounded.Movie,
                contentDescription = null,
                tint = TextTertiary,
                modifier = Modifier.size(22.dp)
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
                    text = duration,
                    style = CodeTimeStyle.copy(fontSize = 10.sp),
                    color = TextPrimary
                )
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(3.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                SpecChip(text = "4K HDR", isHighlight = true)
                Text("•", color = TextTertiary, fontSize = 10.sp)
                Text(folder, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                Text("•", color = TextTertiary, fontSize = 10.sp)
                Text(size, style = MaterialTheme.typography.bodySmall, color = TextTertiary)
            }
        }

        // Play and More Actions
        IconButton(
            onClick = onPlay,
            modifier = Modifier
                .size(34.dp)
                .clip(CircleShape)
                .background(SurfaceElevation2)
        ) {
            Icon(Icons.Rounded.PlayArrow, contentDescription = "Play", tint = TextPrimary, modifier = Modifier.size(18.dp))
        }

        IconButton(onClick = { }, modifier = Modifier.size(28.dp)) {
            Icon(Icons.Rounded.MoreVert, contentDescription = "More", tint = TextTertiary, modifier = Modifier.size(18.dp))
        }
    }
}

@Composable
private fun DeviceSyncBanner(
    videoCount: Int,
    onRescan: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(16.dp))
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(SurfaceElevation2)
                .border(1.dp, HairlineBorder, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                Icons.Rounded.Videocam,
                contentDescription = null,
                tint = AccentCyan,
                modifier = Modifier.size(28.dp)
            )
        }

        Spacer(modifier = Modifier.height(14.dp))

        Text(
            text = "No new local videos found",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = TextPrimary
        )

        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = "Your device storage is fully synced and up to date with $videoCount indexed clips.",
            style = MaterialTheme.typography.bodyMedium,
            color = TextSecondary,
            textAlign = androidx.compose.ui.text.style.TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(
            onClick = onRescan,
            colors = ButtonDefaults.buttonColors(
                containerColor = SurfaceElevation2,
                contentColor = TextPrimary
            ),
            shape = RoundedCornerShape(12.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder),
            contentPadding = PaddingValues(horizontal = 18.dp, vertical = 12.dp)
        ) {
            Icon(
                Icons.Rounded.Sync,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "Rescan Device Storage",
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

private fun getPrimaryGridItems(): List<PrimaryGridItemData> {
    return listOf(
        PrimaryGridItemData(
            title = "Blade Runner 2049",
            badge = "4K UHD",
            isHighlightBadge = true,
            duration = "2h 43m",
            resumeStatus = "Resume at 1h 37m",
            size = "18.4 GB",
            progress = 0.6f
        ),
        PrimaryGridItemData(
            title = "Cosmos Odyssey - Ep. 04",
            badge = "1080P",
            isHighlightBadge = false,
            duration = "52m",
            resumeStatus = "Unwatched",
            size = "2.1 GB",
            progress = 0f
        ),
        PrimaryGridItemData(
            title = "Studio Ghibli - Remaster",
            badge = "4K HDR",
            isHighlightBadge = true,
            duration = "1h 59m",
            resumeStatus = "Resume 18m",
            size = "9.4 GB",
            progress = 0.15f
        ),
        PrimaryGridItemData(
            title = "FPV Drone Norway",
            badge = "4K 60FPS",
            isHighlightBadge = true,
            duration = "08:34",
            resumeStatus = "New clip",
            size = "1.6 GB",
            progress = 0f
        )
    )
}
