package com.example.vdoplayer.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "playback_settings")

class PlaybackSettingsRepository(private val context: Context) {

    private val dataStore = context.dataStore

    val autoplayNext: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[AUTOPLAY_NEXT_KEY] ?: false
    }

    val defaultSpeed: Flow<Float> = dataStore.data.map { preferences ->
        preferences[DEFAULT_SPEED_KEY] ?: 1.0f
    }

    val smartHdr: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[SMART_HDR_KEY] ?: false
    }

    val subtitleSize: Flow<Float> = dataStore.data.map { preferences ->
        preferences[SUBTITLE_SIZE_KEY] ?: 1.0f
    }
    
    val streamOnWifiOnly: Flow<Boolean> = dataStore.data.map { preferences ->
        preferences[STREAM_ON_WIFI_ONLY_KEY] ?: true
    }

    suspend fun setAutoplayNext(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[AUTOPLAY_NEXT_KEY] = enabled
        }
    }

    suspend fun setDefaultSpeed(speed: Float) {
        dataStore.edit { preferences ->
            preferences[DEFAULT_SPEED_KEY] = speed
        }
    }

    suspend fun setSmartHdr(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[SMART_HDR_KEY] = enabled
        }
    }

    suspend fun setSubtitleSize(size: Float) {
        dataStore.edit { preferences ->
            preferences[SUBTITLE_SIZE_KEY] = size
        }
    }
    
    suspend fun setStreamOnWifiOnly(enabled: Boolean) {
        dataStore.edit { preferences ->
            preferences[STREAM_ON_WIFI_ONLY_KEY] = enabled
        }
    }

    companion object {
        private val AUTOPLAY_NEXT_KEY = booleanPreferencesKey("autoplay_next")
        private val DEFAULT_SPEED_KEY = floatPreferencesKey("default_speed")
        private val SMART_HDR_KEY = booleanPreferencesKey("smart_hdr")
        private val SUBTITLE_SIZE_KEY = floatPreferencesKey("subtitle_size")
        private val STREAM_ON_WIFI_ONLY_KEY = booleanPreferencesKey("stream_on_wifi_only")
    }
}
