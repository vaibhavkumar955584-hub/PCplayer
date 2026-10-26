package com.example.vdoplayer

import android.Manifest
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import com.example.vdoplayer.ui.navigation.VdoNavGraph
import com.example.vdoplayer.ui.theme.VdoPlayerTheme
import com.example.vdoplayer.ui.viewmodel.LibraryViewModel
import com.example.vdoplayer.ui.viewmodel.PlayerViewModel
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.isGranted
import com.google.accompanist.permissions.rememberPermissionState

class MainActivity : ComponentActivity() {
    @OptIn(ExperimentalPermissionsApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        val app = application as VdoApplication
        val libraryViewModel = LibraryViewModel(app.videoRepository)
        val playerViewModel = PlayerViewModel(app.videoRepository, app)
        val settingsViewModel = com.example.vdoplayer.ui.viewmodel.SettingsViewModel(app.playbackSettingsRepository)

        setContent {
            VdoPlayerTheme {
                Scaffold(
                    modifier = Modifier.fillMaxSize(),
                    contentWindowInsets = WindowInsets(0, 0, 0, 0)
                ) { _ ->
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            Manifest.permission.READ_MEDIA_VIDEO
                        } else {
                            Manifest.permission.READ_EXTERNAL_STORAGE
                        }
                        
                        val permissionState = rememberPermissionState(permission)
                        
                        LaunchedEffect(permissionState.status.isGranted) {
                            if (permissionState.status.isGranted) {
                                libraryViewModel.refresh()
                            } else {
                                permissionState.launchPermissionRequest()
                            }
                        }

                        VdoNavGraph(
                            libraryViewModel = libraryViewModel,
                            playerViewModel = playerViewModel,
                            settingsViewModel = settingsViewModel
                        )
                    }
                }
            }
        }
    }
}
