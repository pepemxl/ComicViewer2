package com.comicviewer.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

/**
 * Room database for Comic Viewer.
 *
 * Stores reading progress and cached manga data for offline access.
 * Uses a singleton pattern via [getInstance].
 */
@Database(
    entities = [ProgressEntity::class, CachedMangaEntity::class],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    /** Access DAO for reading progress operations. */
    abstract fun progressDao(): ProgressDao

    /** Access DAO for cached manga operations. */
    abstract fun cachedMangaDao(): CachedMangaDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        /**
         * Get or create the singleton database instance.
         *
         * @param context Application context.
         * @return The [AppDatabase] singleton.
         */
        fun getInstance(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "comicviewer.db"
                )
                    .fallbackToDestructiveMigration()
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}
