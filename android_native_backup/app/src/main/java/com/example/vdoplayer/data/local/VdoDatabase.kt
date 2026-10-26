package com.example.vdoplayer.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.example.vdoplayer.data.local.dao.VideoDao
import com.example.vdoplayer.data.local.entity.VideoEntity

@Database(entities = [VideoEntity::class], version = 1, exportSchema = false)
abstract class VdoDatabase : RoomDatabase() {
    abstract fun videoDao(): VideoDao

    companion object {
        const val DATABASE_NAME = "vdo_player_db"
    }
}
