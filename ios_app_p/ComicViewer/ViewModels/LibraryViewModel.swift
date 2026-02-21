// LibraryViewModel.swift
// Comic Viewer – Library State Management
//
// Manages the list of available mangas, fetching from the API,
// and caching locally for offline access.

import Foundation
import UIKit

/// View model for the manga library grid.
@MainActor
final class LibraryViewModel: ObservableObject {
    /// All available mangas
    @Published var mangas: [Manga] = []

    /// Cover images keyed by manga ID
    @Published var coverImages: [Int: UIImage] = [:]

    /// Loading state
    @Published var isLoading = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Reference to the API client
    private var apiClient: APIClient?

    // MARK: - Data Loading

    /// Fetch the manga list from the backend server.
    ///
    /// - Parameter apiClient: The API client to use.
    func loadMangas(using apiClient: APIClient) async {
        self.apiClient = apiClient
        isLoading = true
        errorMessage = nil

        do {
            mangas = try await apiClient.fetchMangas()
            // Start loading covers in background
            for manga in mangas {
                Task {
                    await loadCover(for: manga, using: apiClient)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Refresh the manga list.
    ///
    /// - Parameter apiClient: The API client to use.
    func refresh(using apiClient: APIClient) async {
        await loadMangas(using: apiClient)
    }

    // MARK: - Cover Images

    /// Load and cache the cover image for a manga.
    ///
    /// - Parameters:
    ///   - manga: The manga to load the cover for.
    ///   - apiClient: The API client to use.
    private func loadCover(
        for manga: Manga,
        using apiClient: APIClient
    ) async {
        let cacheKey = "cover_\(manga.id)"

        // Check image cache first
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            coverImages[manga.id] = cached
            return
        }

        // Fetch from server
        do {
            let image = try await apiClient.fetchCoverImage(mangaId: manga.id)
            coverImages[manga.id] = image
            await ImageCache.shared.setImage(image, forKey: cacheKey)
        } catch {
            // Silently fail – no cover is fine
        }
    }
}
