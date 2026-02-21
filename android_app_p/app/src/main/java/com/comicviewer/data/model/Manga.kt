package com.comicviewer.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a manga or comic series from the backend API.
 *
 * Uses Kotlinx Serialization for JSON deserialization with
 * snake_case field mapping.
 */
@Serializable
data class Manga(
    val id: Int,
    val title: String,
    val author: String? = null,
    val description: String? = null,

    @SerialName("cover_path")
    val coverPath: String? = null,

    @SerialName("source_id")
    val sourceId: Int,

    @SerialName("total_chapters")
    val totalChapters: Int = 0,

    @SerialName("created_at")
    val createdAt: String? = null,

    @SerialName("updated_at")
    val updatedAt: String? = null,

    /** Chapters populated from the detail endpoint. */
    val chapters: List<Chapter>? = null
)
