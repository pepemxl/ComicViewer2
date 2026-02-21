// Manga.swift
// Comic Viewer – Manga Data Model
//
// Codable model representing a manga / comic series.

import Foundation

/// Represents a manga or comic series from the backend.
struct Manga: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let author: String?
    let description: String?
    let coverPath: String?
    let sourceId: Int
    let totalChapters: Int
    let createdAt: String?
    let updatedAt: String?

    /// Chapters associated with this manga (populated from detail endpoint)
    var chapters: [Chapter]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case author
        case description
        case coverPath = "cover_path"
        case sourceId = "source_id"
        case totalChapters = "total_chapters"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case chapters
    }

    /// Conformance to Hashable (ignoring chapters for identity)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Manga, rhs: Manga) -> Bool {
        lhs.id == rhs.id
    }
}
