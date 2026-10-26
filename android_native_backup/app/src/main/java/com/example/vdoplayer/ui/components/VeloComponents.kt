package com.example.vdoplayer.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vdoplayer.ui.theme.*

/**
 * Velo Brand Play Emblem (Sleek Squircle with Blue Gradient Playmark)
 */
@Composable
fun VeloLogoMark(
    modifier: Modifier = Modifier,
    size: Dp = 32.dp
) {
    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(size * 0.28f))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(size * 0.28f)),
        contentAlignment = Alignment.Center
    ) {
        // Geometric Play Triangle with Gradient
        androidx.compose.foundation.Canvas(modifier = Modifier.size(size * 0.5f)) {
            val path = Path().apply {
                moveTo(size.toPx() * 0.08f, 0f)
                lineTo(size.toPx() * 0.44f, size.toPx() * 0.25f)
                lineTo(size.toPx() * 0.08f, size.toPx() * 0.5f)
                close()
            }
            drawPath(
                path = path,
                brush = Brush.linearGradient(
                    colors = listOf(PrimaryContainer, AccentCyan)
                )
            )
        }
    }
}

/**
 * Technical Specification Badge (4K, HDR, HEVC, ATMOS, 1080p, AV1, etc.)
 */
@Composable
fun SpecChip(
    text: String,
    modifier: Modifier = Modifier,
    isHighlight: Boolean = false
) {
    val bgColor = if (isHighlight) PrimaryContainer.copy(alpha = 0.16f) else Color.White.copy(alpha = 0.08f)
    val borderColor = if (isHighlight) AccentCyan.copy(alpha = 0.35f) else Color.White.copy(alpha = 0.12f)
    val textColor = if (isHighlight) AccentCyan else TextSecondary

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(4.dp))
            .background(bgColor)
            .border(1.dp, borderColor, RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text.uppercase(),
            style = CodeBadgeStyle,
            color = textColor
        )
    }
}

/**
 * Common Top Bar adhering to the Cinematic Precision style
 */
@Composable
fun VeloTopBar(
    title: String = "Velo",
    subtitle: String? = "Home",
    showBack: Boolean = false,
    onBackClick: () -> Unit = {},
    actions: @Composable RowScope.() -> Unit = {}
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .statusBarsPadding()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            if (showBack) {
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
            } else {
                VeloLogoMark(size = 34.dp)
            }

            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = TextPrimary
            )
        }

        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextSecondary,
                    modifier = Modifier.padding(end = 4.dp)
                )
            }

            actions()

            // User Avatar Profile Button
            Box(
                modifier = Modifier
                    .size(34.dp)
                    .clip(CircleShape)
                    .background(Primary.copy(alpha = 0.2f))
                    .border(1.dp, Primary.copy(alpha = 0.4f), CircleShape)
                    .clickable { },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    Icons.Rounded.Person,
                    contentDescription = "Profile",
                    tint = Primary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

/**
 * Cinematic Search Bar with Voice and Filter Controls
 */
@Composable
fun VeloSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    placeholder: String = "Search movies, series, folders...",
    onFilterClick: () -> Unit = {},
    onMicClick: () -> Unit = {}
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .height(50.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(SurfaceElevation1)
            .border(1.dp, HairlineBorder, RoundedCornerShape(12.dp))
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            Icons.Rounded.Search,
            contentDescription = "Search",
            tint = TextSecondary,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(10.dp))

        Box(modifier = Modifier.weight(1f)) {
            if (query.isEmpty()) {
                Text(
                    text = placeholder,
                    style = MaterialTheme.typography.bodyMedium,
                    color = TextTertiary
                )
            }
            androidx.compose.foundation.text.BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                singleLine = true,
                textStyle = MaterialTheme.typography.bodyMedium.copy(color = TextPrimary),
                cursorBrush = Brush.verticalGradient(listOf(AccentCyan, PrimaryContainer)),
                modifier = Modifier.fillMaxWidth()
            )
        }

        IconButton(
            onClick = onMicClick,
            modifier = Modifier.size(32.dp)
        ) {
            Icon(
                Icons.Rounded.Mic,
                contentDescription = "Voice Search",
                tint = TextSecondary,
                modifier = Modifier.size(18.dp)
            )
        }

        Spacer(modifier = Modifier.width(4.dp))

        IconButton(
            onClick = onFilterClick,
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(SurfaceElevation2)
                .border(1.dp, HairlineBorder, RoundedCornerShape(8.dp))
        ) {
            Icon(
                Icons.Rounded.Tune,
                contentDescription = "Filters",
                tint = TextPrimary,
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

/**
 * Floating / Elevated Bottom Navigation Bar with Cyan Active Glow Dot
 */
@Composable
fun VeloBottomNav(
    currentTab: String,
    onTabSelected: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val items = listOf(
        NavigationItem("Home", Icons.Rounded.Movie),
        NavigationItem("Library", Icons.Rounded.Folder),
        NavigationItem("Playlists", Icons.Rounded.PlaylistPlay),
        NavigationItem("Settings", Icons.Rounded.Tune)
    )

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .navigationBarsPadding()
            .padding(horizontal = 16.dp, vertical = 10.dp)
            .height(64.dp)
            .shadow(16.dp, RoundedCornerShape(20.dp), spotColor = Color.Black.copy(alpha = 0.8f)),
        color = SurfaceElevation1.copy(alpha = 0.92f),
        shape = RoundedCornerShape(20.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 12.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            items.forEach { item ->
                val isSelected = currentTab.equals(item.name, ignoreCase = true)
                val iconColor by animateColorAsState(
                    targetValue = if (isSelected) AccentCyan else TextTertiary,
                    label = "nav_icon_color"
                )

                Column(
                    modifier = Modifier
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        ) { onTabSelected(item.name) }
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = item.icon,
                        contentDescription = item.name,
                        tint = iconColor,
                        modifier = Modifier.size(22.dp)
                    )

                    Spacer(modifier = Modifier.height(2.dp))

                    Text(
                        text = item.name,
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 10.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                        ),
                        color = iconColor
                    )

                    Spacer(modifier = Modifier.height(2.dp))

                    // 4px Glowing Dot Anchor
                    Box(
                        modifier = Modifier
                            .size(4.dp)
                            .clip(CircleShape)
                            .background(if (isSelected) AccentCyan else Color.Transparent)
                    )
                }
            }
        }
    }
}

private data class NavigationItem(val name: String, val icon: ImageVector)

/**
 * Centered Circular Blue Play / Resume Button
 */
@Composable
fun VeloPlayButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: Dp = 56.dp,
    isPlaying: Boolean = false
) {
    Box(
        modifier = modifier
            .size(size)
            .shadow(12.dp, CircleShape, spotColor = PrimaryContainer.copy(alpha = 0.6f))
            .clip(CircleShape)
            .background(PrimaryContainer)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = if (isPlaying) Icons.Rounded.Pause else Icons.Rounded.PlayArrow,
            contentDescription = if (isPlaying) "Pause" else "Play",
            tint = Color.White,
            modifier = Modifier.size(size * 0.52f)
        )
    }
}
