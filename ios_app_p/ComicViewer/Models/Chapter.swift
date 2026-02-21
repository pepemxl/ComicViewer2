// Chapter.swift
// Comic Viewer – Chapter Data Model
//
// Codable model representing a single chapter within a manga.

import Foundation

/// Represents a chapter (or volume) within a manga.
struct Chapter: Codable, Identifiable, Hashable {
    let id: Int
    let mangaId: Int
    let chapterNumber: Double
    let title: String?
    let filePath: String
    let pageCount: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mangaId = "manga_id"
        case chapterNumber = "chapter_number"
        case title
        case filePath = "file_path"
        case pageCount = "page_count"
        case createdAt = "created_at"
    }

    /// Formatted chapter number for display (e.g., "Ch. 1" or "Ch. 1.5")
    var displayTitle: String {
        let numStr = chapterNumber.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", chapterNumber)
            : String(format: "%.1f", chapterNumber)

        if let title, !title.isEmpty {
            return "Ch. \(numStr) – \(title)"
        }
        return "Chapter \(numStr)"
    }
}
