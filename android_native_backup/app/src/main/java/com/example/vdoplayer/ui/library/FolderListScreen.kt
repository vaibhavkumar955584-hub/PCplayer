package com.example.vdoplayer.ui.library

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.SelectAll
import androidx.compose.material.icons.rounded.Folder
import androidx.compose.material.icons.rounded.GridView
import androidx.compose.material.icons.rounded.Menu
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Info
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.VideoLibrary
import androidx.compose.material.icons.rounded.Favorite
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil.compose.AsyncImage
import com.example.vdoplayer.domain.model.Folder
import com.example.vdoplayer.domain.model.Video
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FolderListScreen(
    folders: List<Folder>,
    videos: List<Video>,
    recentVideos: List<Video>,
    selectedTab: Int,
    searchQuery: String,
    onTabSelected: (Int) -> Unit,
    onSearchQueryChange: (String) -> Unit,
    onFolderClick: (Folder) -> Unit,
    onVideoClick: (Video) -> Unit,
    onToggleFavorite: (Video) -> Unit,
    onRefresh: () -> Unit,
    onSettingsClick: () -> Unit
) {
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    
    var selectedVideoIds by remember { mutableStateOf(setOf<Long>()) }
    val isSelectionMode = selectedVideoIds.isNotEmpty()

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                Text("Cinematic", modifier = Modifier.padding(16.dp), style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                HorizontalDivider()
                NavigationDrawerItem(
                    label = { Text(text = "Library") },
                    selected = true,
                    onClick = { scope.launch { drawerState.close() } },
                    icon = { Icon(Icons.Rounded.VideoLibrary, contentDescription = null) },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
                NavigationDrawerItem(
                    label = { Text(text = "Downloads") },
                    selected = false,
                    onClick = { scope.launch { drawerState.close() } },
                    icon = { Icon(Icons.Rounded.Download, contentDescription = null) },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
                NavigationDrawerItem(
                    label = { Text(text = "Settings") },
                    selected = false,
                    onClick = { 
                        scope.launch { drawerState.close() }
                        onSettingsClick()
                    },
                    icon = { Icon(Icons.Rounded.Settings, contentDescription = null) },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
                NavigationDrawerItem(
                    label = { Text(text = "About") },
                    selected = false,
                    onClick = { scope.launch { drawerState.close() } },
                    icon = { Icon(Icons.Rounded.Info, contentDescription = null) },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
            }
        }
    ) {
        Scaffold(
            containerColor = MaterialTheme.colorScheme.background,
            topBar = {
                if (isSelectionMode) {
                    TopAppBar(
                        title = { Text("${selectedVideoIds.size} Selected", fontWeight = FontWeight.Bold) },
                        navigationIcon = {
                            IconButton(onClick = { selectedVideoIds = emptySet() }) {
                                Icon(Icons.Rounded.Close, contentDescription = "Close")
                            }
                        },
                        actions = {
                            IconButton(onClick = { /* Select All */ 
                                selectedVideoIds = videos.map { it.id }.toSet() 
                            }) {
                                Icon(Icons.Rounded.SelectAll, contentDescription = "Select All")
                            }
                            IconButton(onClick = { 
                                selectedVideoIds.forEach { id ->
                                    videos.find { it.id == id }?.let { onToggleFavorite(it) }
                                }
                                selectedVideoIds = emptySet()
                            }) {
                                Icon(Icons.Rounded.Favorite, contentDescription = "Favorite")
                            }
                            IconButton(onClick = { /* Delete Logic */ selectedVideoIds = emptySet() }) {
                                Icon(Icons.Rounded.Delete, contentDescription = "Delete")
                            }
                            IconButton(onClick = { /* Share Logic */ selectedVideoIds = emptySet() }) {
                                Icon(Icons.Rounded.Share, contentDescription = "Share")
                            }
                        },
                        colors = TopAppBarDefaults.topAppBarColors(
                            containerColor = MaterialTheme.colorScheme.primaryContainer,
                            titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
                            actionIconContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    )
                } else {
                    CenterAlignedTopAppBar(
                        title = { 
                            Text(
                                "Cinematic", 
                                style = MaterialTheme.typography.headlineMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            ) 
                        },
                        navigationIcon = {
                            IconButton(onClick = { scope.launch { drawerState.open() } }) {
                                Icon(Icons.Rounded.Menu, contentDescription = "Menu")
                            }
                        },
                        actions = {
                            IconButton(onClick = onSettingsClick) {
                                Icon(Icons.Rounded.Settings, contentDescription = "Settings")
                            }
                            IconButton(onClick = { /* Toggle Search */ }) {
                                Icon(Icons.Rounded.Search, contentDescription = "Search")
                            }
                        },
                        colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                            containerColor = MaterialTheme.colorScheme.background
                        )
                    )
                }
            }
        ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            // Tab-like Filter (Obsidian Cinema Style)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                val tabs = listOf("All", "Folders", "Favorites", "Recent")
                tabs.forEachIndexed { index, tab ->
                    Text(
                        text = tab,
                        modifier = Modifier.clickable { onTabSelected(index) },
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = if (selectedTab == index) FontWeight.Bold else FontWeight.Medium,
                        color = if (selectedTab == index) MaterialTheme.colorScheme.onBackground else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (searchQuery.isNotEmpty()) {
                TextField(
                    value = searchQuery,
                    onValueChange = onSearchQueryChange,
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    placeholder = { Text("Search videos...") },
                    leadingIcon = { Icon(Icons.Rounded.Search, null) },
                    shape = MaterialTheme.shapes.medium,
                    colors = TextFieldDefaults.colors(
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        unfocusedContainerColor = MaterialTheme.colorScheme.surfaceContainer,
                        focusedContainerColor = MaterialTheme.colorScheme.surfaceContainerHigh
                    )
                )
            }

            if (selectedTab == 1) { // Folders Tab
                Text(
                    "Collections",
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )

                LazyVerticalGrid(
                    columns = GridCells.Adaptive(160.dp),
                    contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    items(folders) { folder ->
                        FolderItem(folder = folder, onClick = { onFolderClick(folder) })
                    }
                }
            } else {
                val title = when (selectedTab) {
                    0 -> "All Videos"
                    2 -> "Favorites"
                    3 -> "Recent Videos"
                    else -> ""
                }
                Text(
                    title,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    if (selectedTab == 0 && recentVideos.isNotEmpty()) {
                        item {
                            Text(
                                "Continue Watching",
                                modifier = Modifier.padding(bottom = 8.dp),
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                            androidx.compose.foundation.lazy.LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                items(recentVideos) { video ->
                                    Box(modifier = Modifier.width(200.dp)) {
                                        VideoItem(
                                            video = video,
                                            isSelected = selectedVideoIds.contains(video.id),
                                            onClick = { 
                                                if (isSelectionMode) {
                                                    selectedVideoIds = if (selectedVideoIds.contains(video.id)) selectedVideoIds - video.id else selectedVideoIds + video.id
                                                } else {
                                                    onVideoClick(video) 
                                                }
                                            },
                                            onLongClick = {
                                                selectedVideoIds = selectedVideoIds + video.id
                                            },
                                            onToggleFavorite = { onToggleFavorite(video) }
                                        )
                                    }
                                }
                            }
                            HorizontalDivider(modifier = Modifier.padding(vertical = 16.dp))
                        }
                    }

                    items(videos) { video ->
                        VideoItem(
                            video = video,
                            isSelected = selectedVideoIds.contains(video.id),
                            onClick = { 
                                if (isSelectionMode) {
                                    selectedVideoIds = if (selectedVideoIds.contains(video.id)) selectedVideoIds - video.id else selectedVideoIds + video.id
                                } else {
                                    onVideoClick(video) 
                                }
                            },
                            onLongClick = {
                                selectedVideoIds = selectedVideoIds + video.id
                            },
                            onToggleFavorite = { onToggleFavorite(video) }
                        )
                    }
                }
            }
        }
    }
    }
}

@Composable
fun FolderItem(folder: Folder, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .aspectRatio(16/10f)
                .clip(MaterialTheme.shapes.large)
                .background(MaterialTheme.colorScheme.surfaceContainer),
            contentAlignment = Alignment.Center
        ) {
            if (folder.firstVideoThumbnail != null) {
                val context = androidx.compose.ui.platform.LocalContext.current
                AsyncImage(
                    model = coil.request.ImageRequest.Builder(context)
                        .data(folder.firstVideoThumbnail)
                        .crossfade(true)
                        .diskCachePolicy(coil.request.CachePolicy.ENABLED)
                        .memoryCachePolicy(coil.request.CachePolicy.ENABLED)
                        .build(),
                    contentDescription = null,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                // Overlay for folder feel
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Rounded.Folder,
                        contentDescription = null,
                        modifier = Modifier.size(32.dp),
                        tint = Color.White
                    )
                }
            } else {
                Icon(
                    Icons.Rounded.Folder,
                    contentDescription = null,
                    modifier = Modifier.size(48.dp),
                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f)
                )
            }
            
            // Video Count Badge (Obsidian Cinema style)
            Surface(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(8.dp),
                color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.9f),
                shape = CircleShape
            ) {
                Text(
                    text = "${folder.videoCount}",
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = folder.name,
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            text = formatFileSize(folder.size),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

private fun formatFileSize(size: Long): String {
    if (size <= 0) return "0 B"
    val units = arrayOf("B", "KB", "MB", "GB", "TB")
    val digitGroups = (Math.log10(size.toDouble()) / Math.log10(1024.0)).toInt()
    return String.format(java.util.Locale.getDefault(), "%.1f %s", size / Math.pow(1024.0, digitGroups.toDouble()), units[digitGroups])
}
