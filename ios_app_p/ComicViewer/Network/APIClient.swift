// APIClient.swift
// Comic Viewer – Network Layer
//
// URLSession-based client for communicating with the Python backend.
// Uses modern Swift concurrency (async/await).

import Foundation
import UIKit

/// HTTP client for the Comic Viewer backend REST API.
@MainActor
final class APIClient: ObservableObject {
    /// Base URL of the backend server (e.g., "http://192.168.1.50:8000")
    private let baseURL: String

    /// Shared URLSession with custom configuration
    private let session: URLSession

    /// JSON decoder configured for snake_case keys
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    /// JSON encoder configured for snake_case keys
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Initialization

    /// Create an API client targeting the given server URL.
    ///
    /// - Parameter baseURL: Root URL of the backend (no trailing slash).
    init(baseURL: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic Helpers

    /// Perform a GET request and decode the JSON response.
    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    /// Perform a request with a JSON body and decode the response.
    private func request<B: Encodable, T: Decodable>(
        _ method: String,
        path: String,
        body: B
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(body)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }

    /// Perform a POST with no response body expected (returns generic dict).
    private func post<B: Encodable>(
        _ path: String,
        body: B
    ) async throws -> [String: String] {
        try await request("POST", path: path, body: body)
    }

    /// Validate that the HTTP response has a success status code.
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Mangas

    /// Fetch all available mangas from the server.
    ///
    /// - Returns: Array of `Manga` objects.
    func fetchMangas() async throws -> [Manga] {
        try await get("/api/mangas")
    }

    /// Fetch a single manga with its chapter list.
    ///
    /// - Parameter mangaId: The manga identifier.
    /// - Returns: The manga including populated chapters.
    func fetchManga(id mangaId: Int) async throws -> Manga {
        try await get("/api/mangas/\(mangaId)")
    }

    // MARK: - Chapters & Pages

    /// Fetch chapter details including page count.
    ///
    /// - Parameter chapterId: The chapter identifier.
    /// - Returns: The chapter details.
    func fetchChapter(id chapterId: Int) async throws -> Chapter {
        try await get("/api/chapters/\(chapterId)")
    }

    /// Fetch metadata for all pages in a chapter.
    ///
    /// - Parameter chapterId: The chapter identifier.
    /// - Returns: A dictionary with page count and page metadata.
    func fetchPages(chapterId: Int) async throws -> PageListResponse {
        try await get("/api/chapters/\(chapterId)/pages")
    }

    /// Download a specific page image.
    ///
    /// - Parameters:
    ///   - chapterId: The chapter identifier.
    ///   - pageNumber: Zero-based page index.
    /// - Returns: The page image as `UIImage`.
    func fetchPageImage(
        chapterId: Int,
        pageNumber: Int
    ) async throws -> UIImage {
        guard let url = URL(
            string: "\(baseURL)/api/chapters/\(chapterId)/pages/\(pageNumber)"
        ) else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        guard let image = UIImage(data: data) else {
            throw APIError.invalidImageData
        }
        return image
    }

    /// Download the cover image for a manga.
    ///
    /// - Parameter mangaId: The manga identifier.
    /// - Returns: The cover image.
    func fetchCoverImage(mangaId: Int) async throws -> UIImage {
        guard let url = URL(
            string: "\(baseURL)/api/mangas/\(mangaId)/cover"
        ) else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        guard let image = UIImage(data: data) else {
            throw APIError.invalidImageData
        }
        return image
    }

    // MARK: - Reading Progress

    /// Fetch reading progress for a manga.
    ///
    /// - Parameter mangaId: The manga identifier.
    /// - Returns: Reading progress data.
    func fetchProgress(mangaId: Int) async throws -> ReadingProgress {
        try await get("/api/progress/\(mangaId)")
    }

    /// Update reading progress for a manga.
    ///
    /// - Parameters:
    ///   - mangaId: The manga identifier.
    ///   - update: Progress update data.
    func updateProgress(
        mangaId: Int,
        update: ProgressUpdateRequest
    ) async throws {
        let _: [String: String] = try await request(
            "PUT",
            path: "/api/progress/\(mangaId)",
            body: update
        )
    }

    // MARK: - Sources

    /// Fetch all registered sources.
    ///
    /// - Returns: Array of `Source` objects.
    func fetchSources() async throws -> [Source] {
        try await get("/api/sources")
    }

    /// Trigger a scan of a source directory.
    ///
    /// - Parameter sourceId: The source identifier.
    /// - Returns: Scan result summary.
    func scanSource(id sourceId: Int) async throws -> ScanResult {
        guard let url = URL(
            string: "\(baseURL)/api/sources/\(sourceId)/scan"
        ) else {
            throw APIError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let (data, response) = try await session.data(for: req)
        try validateResponse(response)
        return try decoder.decode(ScanResult.self, from: data)
    }

    // MARK: - Health

    /// Check if the backend server is reachable.
    ///
    /// - Returns: True if the server is healthy.
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else {
            return false
        }
        do {
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Supporting Types

/// Response model for the pages list endpoint.
struct PageListResponse: Codable {
    let chapterId: Int
    let pageCount: Int
    let pages: [PageInfo]

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case pageCount = "page_count"
        case pages
    }
}

/// Metadata for a single page.
struct PageInfo: Codable, Identifiable {
    let pageNumber: Int
    let url: String

    var id: Int { pageNumber }

    enum CodingKeys: String, CodingKey {
        case pageNumber = "page_number"
        case url
    }
}

/// Result of a source scan operation.
struct ScanResult: Codable {
    let message: String
    let mangasFound: Int
    let chaptersFound: Int

    enum CodingKeys: String, CodingKey {
        case message
        case mangasFound = "mangas_found"
        case chaptersFound = "chapters_found"
    }
}

/// API client error types.
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error (HTTP \(code))"
        case .invalidImageData:
            return "Could not decode image data"
        }
    }
}
