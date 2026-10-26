package com.example.vdoplayer.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.vdoplayer.ui.components.VeloBottomNav
import com.example.vdoplayer.ui.components.VeloTopBar
import com.example.vdoplayer.ui.theme.*
import com.example.vdoplayer.ui.viewmodel.SettingsViewModel

@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel,
    onBackClick: () -> Unit,
    onNavigateTab: ((String) -> Unit)? = null
) {
    val autoplayNext by viewModel.autoplayNext.collectAsState()
    val defaultSpeed by viewModel.defaultSpeed.collectAsState()
    val smartHdr by viewModel.smartHdr.collectAsState()
    val streamOnWifiOnly by viewModel.streamOnWifiOnly.collectAsState()
    val cacheSize by viewModel.cacheSize.collectAsState()

    val context = LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.calculateCacheSize(context)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CanvasBase)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(bottom = if (onNavigateTab != null) 90.dp else 24.dp)
        ) {
            // Header
            VeloTopBar(
                title = "Velo",
                subtitle = "Settings",
                showBack = onNavigateTab == null,
                onBackClick = onBackClick
            )

            // PLAYBACK SECTION
            SettingsCategoryHeader("PLAYBACK ENGINE")

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceElevation1),
                border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
            ) {
                SettingsSwitchRow(
                    title = "Autoplay Next Video",
                    subtitle = "Automatically play the next video in the folder",
                    checked = autoplayNext,
                    onCheckedChange = { viewModel.setAutoplayNext(it) }
                )

                HorizontalDivider(color = HairlineBorder, modifier = Modifier.padding(horizontal = 14.dp))

                SettingsSwitchRow(
                    title = "Smart HDR Rendering",
                    subtitle = "Boost brightness and tone-mapping for HDR footage",
                    checked = smartHdr,
                    onCheckedChange = { viewModel.setSmartHdr(it) }
                )

                HorizontalDivider(color = HairlineBorder, modifier = Modifier.padding(horizontal = 14.dp))

                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Default Playback Speed", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                        Text("${defaultSpeed}x", style = CodeTimeStyle, color = AccentCyan)
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Slider(
                        value = defaultSpeed,
                        onValueChange = { viewModel.setDefaultSpeed((it * 4).toInt() / 4f) },
                        valueRange = 0.5f..2.0f,
                        steps = 5,
                        colors = SliderDefaults.colors(
                            thumbColor = Color.White,
                            activeTrackColor = PrimaryContainer,
                            inactiveTrackColor = SurfaceElevation2
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // NETWORK SECTION
            SettingsCategoryHeader("NETWORK & STREAMING")

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceElevation1),
                border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
            ) {
                SettingsSwitchRow(
                    title = "Stream on Wi-Fi Only",
                    subtitle = "Conserve cellular mobile data during network discovery",
                    checked = streamOnWifiOnly,
                    onCheckedChange = { viewModel.setStreamOnWifiOnly(it) }
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // STORAGE SECTION
            SettingsCategoryHeader("STORAGE & CACHE")

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceElevation1),
                border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { viewModel.clearCache(context) }
                        .padding(14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text("Clear Thumbnail Cache", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
                        Spacer(modifier = Modifier.height(2.dp))
                        Text("Free up disk space (${formatFileSize(cacheSize)})", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                    }
                    Icon(Icons.Rounded.DeleteOutline, contentDescription = "Clear", tint = TextTertiary)
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ABOUT / ENGINE INFO
            SettingsCategoryHeader("ABOUT")

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceElevation1),
                border = androidx.compose.foundation.BorderStroke(1.dp, HairlineBorder)
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text("Velo Player", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = TextPrimary)
                    Spacer(modifier = Modifier.height(2.dp))
                    Text("Cinematic Precision Video Engine v4.2", style = MaterialTheme.typography.bodySmall, color = AccentCyan)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text("High-performance local video player engineered for OLED displays and HDR media playback.", style = MaterialTheme.typography.bodySmall, color = TextSecondary)
                }
            }
        }

        if (onNavigateTab != null) {
            VeloBottomNav(
                currentTab = "Settings",
                onTabSelected = onNavigateTab,
                modifier = Modifier.align(Alignment.BottomCenter)
            )
        }
    }
}

@Composable
private fun SettingsCategoryHeader(text: String) {
    Text(
        text = text,
        modifier = Modifier.padding(horizontal = 20.dp, vertical = 8.dp),
        style = CodeBadgeStyle,
        color = TextTertiary
    )
}

@Composable
private fun SettingsSwitchRow(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f).padding(end = 12.dp)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold, color = TextPrimary)
            Spacer(modifier = Modifier.height(2.dp))
            Text(subtitle, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        }

        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = PrimaryContainer,
                uncheckedTrackColor = SurfaceElevation2
            )
        )
    }
}

private fun formatFileSize(size: Long): String {
    if (size <= 0) return "0 B"
    val units = arrayOf("B", "KB", "MB", "GB", "TB")
    val digitGroups = (Math.log10(size.toDouble()) / Math.log10(1024.0)).toInt()
    return String.format(java.util.Locale.getDefault(), "%.1f %s", size / Math.pow(1024.0, digitGroups.toDouble()), units[digitGroups])
}
