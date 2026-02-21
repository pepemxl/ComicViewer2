package com.comicviewer.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a single chapter within a manga.
 */
@Serializable
data class Chapter(
    val id: Int,

    @SerialName("manga_id")
    val mangaId: Int,

    @SerialName("chapter_number")
    val chapterNumber: Double,

    val title: String? = null,

    @SerialName("file_path")
    val filePath: String = "",

    @SerialName("page_count")
    val pageCount: Int = 0,

    @SerialName("created_at")
    val createdAt: String? = null
) {
    /**
     * Formatted chapter title for display.
     *
     * Examples: "Chapter 1", "Ch. 1.5 – Special Chapter"
     */
    val displayTitle: String
        get() {
            val numStr = if (chapterNumber % 1.0 == 0.0) {
                chapterNumber.toInt().toString()
            } else {
                String.format("%.1f", chapterNumber)
            }
            return if (!title.isNullOrBlank()) {
                "Ch. $numStr – $title"
            } else {
                "Chapter $numStr"
            }
        }
}
