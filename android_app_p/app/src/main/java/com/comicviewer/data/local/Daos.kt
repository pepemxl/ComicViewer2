package com.comicviewer.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for reading progress operations.
 *
 * Provides reactive [Flow]-based queries and suspend functions
 * for insert/update/delete operations.
 */
@Dao
interface ProgressDao {

    /**
     * Observe all reading progress records, newest first.
     *
     * @return A [Flow] that emits updated lists when data changes.
     */
    @Query("SELECT * FROM reading_progress ORDER BY lastReadAt DESC")
    fun observeAll(): Flow<List<ProgressEntity>>

    /**
     * Get reading progress for a specific manga.
     *
     * @param mangaId The manga identifier.
     * @return The progress entity, or null if not found.
     */
    @Query("SELECT * FROM reading_progress WHERE mangaId = :mangaId")
    suspend fun getProgress(mangaId: Int): ProgressEntity?

    /**
     * Insert or update reading progress.
     *
     * Uses [OnConflictStrategy.REPLACE] to upsert by mangaId.
     *
     * @param progress The progress entity to save.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(progress: ProgressEntity)

    /**
     * Delete reading progress for a manga.
     *
     * @param mangaId The manga identifier.
     */
    @Query("DELETE FROM reading_progress WHERE mangaId = :mangaId")
    suspend fun delete(mangaId: Int)
}

/**
 * Data Access Object for cached manga operations.
 */
@Dao
interface CachedMangaDao {

    /**
     * Get all cached mangas ordered by title.
     *
     * @return List of cached mangas.
     */
    @Query("SELECT * FROM cached_mangas ORDER BY title")
    suspend fun getAll(): List<CachedMangaEntity>

    /**
     * Insert or update a cached manga record.
     *
     * @param manga The manga entity to cache.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(manga: CachedMangaEntity)

    /**
     * Clear the entire manga cache.
     */
    @Query("DELETE FROM cached_mangas")
    suspend fun clearAll()
}
