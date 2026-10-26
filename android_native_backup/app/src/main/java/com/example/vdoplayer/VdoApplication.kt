package com.example.vdoplayer

import android.app.Application
import androidx.room.Room
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.disk.DiskCache
import coil.memory.MemoryCache
import coil.request.CachePolicy
import coil.util.DebugLogger
import com.example.vdoplayer.data.local.VdoDatabase
import com.example.vdoplayer.data.repository.PlaybackSettingsRepository
import com.example.vdoplayer.data.repository.VideoRepository
import com.example.vdoplayer.data.scanner.VideoScanner

class VdoApplication : Application(), ImageLoaderFactory {
    
    val database: VdoDatabase by lazy {
        Room.databaseBuilder(
            this,
            VdoDatabase::class.java,
            VdoDatabase.DATABASE_NAME
        ).build()
    }
    
    val videoScanner: VideoScanner by lazy {
        VideoScanner(this)
    }
    
    val videoRepository: VideoRepository by lazy {
        VideoRepository(database.videoDao(), videoScanner)
    }
    
    val playbackSettingsRepository: PlaybackSettingsRepository by lazy {
        PlaybackSettingsRepository(this)
    }

    override fun newImageLoader(): ImageLoader {
        return ImageLoader.Builder(this)
            .memoryCache {
                MemoryCache.Builder(this)
                    .maxSizePercent(0.25)
                    .build()
            }
            .diskCache {
                DiskCache.Builder()
                    .directory(this.cacheDir.resolve("image_cache"))
                    .maxSizePercent(0.05) // Aggressive disk caching
                    .build()
            }
            .diskCachePolicy(CachePolicy.ENABLED)
            .memoryCachePolicy(CachePolicy.ENABLED)
            .respectCacheHeaders(false) // Ignore standard cache headers for local files
            .crossfade(true)
            .build()
    }
}
