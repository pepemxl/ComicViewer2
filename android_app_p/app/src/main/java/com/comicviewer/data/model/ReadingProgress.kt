package com.comicviewer.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Tracks reading progress for a manga.
 */
@Serializable
data class ReadingProgress(
    val id: Int? = null,

    @SerialName("manga_id")
    val mangaId: Int,

    @SerialName("chapter_id")
    val chapterId: Int? = null,

    @SerialName("current_page")
    val currentPage: Int = 0,

    @SerialName("total_pages")
    val totalPages: Int = 0,

    @SerialName("last_read_at")
    val lastReadAt: String? = null
) {
    /** Percentage of progress through the current chapter (0.0–1.0). */
    val progressPercent: Float
        get() = if (totalPages > 0) currentPage.toFloat() / totalPages else 0f
}

/**
 * Request body for updating reading progress via the API.
 */
@Serializable
data class ProgressUpdateRequest(
    @SerialName("chapter_id")
    val chapterId: Int,

    @SerialName("current_page")
    val currentPage: Int,

    @SerialName("total_pages")
    val totalPages: Int = 0
)

/**
 * Represents a comic source directory from the backend.
 */
@Serializable
data class Source(
    val id: Int,
    val name: String,
    val path: String,

    @SerialName("source_type")
    val sourceType: String = "local",

    @SerialName("created_at")
    val createdAt: String? = null
)

/**
 * Response model for the pages list endpoint.
 */
@Serializable
data class PageListResponse(
    @SerialName("chapter_id")
    val chapterId: Int,

    @SerialName("page_count")
    val pageCount: Int,

    val pages: List<PageInfo>
)

/**
 * Metadata for a single page.
 */
@Serializable
data class PageInfo(
    @SerialName("page_number")
    val pageNumber: Int,

    val url: String
)

/**
 * Result of a source scan operation.
 */
@Serializable
data class ScanResult(
    val message: String,

    @SerialName("mangas_found")
    val mangasFound: Int,

    @SerialName("chapters_found")
    val chaptersFound: Int
)

/**
 * Generic message response from the API.
 */
@Serializable
data class MessageResponse(
    val message: String,
    val id: Int? = null
)

/**
 * Health check response.
 */
@Serializable
data class HealthResponse(
    val status: String,
    val version: String? = null
)
