package com.comicviewer.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Room entity for locally cached reading progress.
 *
 * The manga_id acts as the primary key (one progress record per manga),
 * matching the backend's UNIQUE constraint on manga_id.
 */
@Entity(tableName = "reading_progress")
data class ProgressEntity(
    @PrimaryKey
    val mangaId: Int,
    val chapterId: Int,
    val currentPage: Int = 0,
    val totalPages: Int = 0,
    val lastReadAt: Long = System.currentTimeMillis()
)

/**
 * Room entity for locally cached manga records.
 *
 * Allows offline browsing of previously-fetched manga data.
 */
@Entity(tableName = "cached_mangas")
data class CachedMangaEntity(
    @PrimaryKey
    val id: Int,
    val title: String,
    val author: String? = null,
    val description: String? = null,
    val coverPath: String? = null,
    val sourceId: Int,
    val totalChapters: Int = 0,
    val cachedAt: Long = System.currentTimeMillis()
)
