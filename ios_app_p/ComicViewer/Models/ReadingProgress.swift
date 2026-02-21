// ReadingProgress.swift
// Comic Viewer – Reading Progress Data Model
//
// Codable model tracking how far the user has read in each manga.

import Foundation

/// Tracks reading progress for a manga.
struct ReadingProgress: Codable, Identifiable {
    let id: Int?
    let mangaId: Int
    let chapterId: Int?
    let currentPage: Int
    let totalPages: Int
    let lastReadAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mangaId = "manga_id"
        case chapterId = "chapter_id"
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case lastReadAt = "last_read_at"
    }

    /// Percentage of progress through the current chapter.
    var progressPercent: Double {
        guard totalPages > 0 else { return 0.0 }
        return Double(currentPage) / Double(totalPages)
    }
}

/// Request body for updating reading progress via the API.
struct ProgressUpdateRequest: Codable {
    let chapterId: Int
    let currentPage: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case currentPage = "current_page"
        case totalPages = "total_pages"
    }
}

/// Represents a comic source directory.
struct Source: Codable, Identifiable {
    let id: Int
    let name: String
    let path: String
    let sourceType: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case path
        case sourceType = "source_type"
        case createdAt = "created_at"
    }
}
