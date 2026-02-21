// ReaderViewModel.swift
// Comic Viewer – Reader State Management
//
// Manages the current reading session: page loading, navigation,
// and progress persistence.

import Foundation
import UIKit

/// View model for the full-screen comic reader.
@MainActor
final class ReaderViewModel: ObservableObject {
    /// Currently displayed page image
    @Published var currentImage: UIImage?

    /// Current page number (0-indexed)
    @Published var currentPage: Int = 0

    /// Total pages in the current chapter
    @Published var totalPages: Int = 0

    /// Loading indicator
    @Published var isLoading = false

    /// Error message
    @Published var errorMessage: String?

    /// Pre-loaded next page for smooth transitions
    private var prefetchedImages: [Int: UIImage] = [:]

    /// Current chapter being read
    private var chapter: Chapter?

    /// API client reference
    private var apiClient: APIClient?

    /// Database for progress persistence
    private var database: DatabaseManager?

    // MARK: - Setup

    /// Initialize the reader with a chapter.
    ///
    /// - Parameters:
    ///   - chapter: The chapter to read.
    ///   - apiClient: API client for fetching pages.
    ///   - database: Database manager for progress tracking.
    ///   - startPage: Page to start reading from (0-indexed).
    func setup(
        chapter: Chapter,
        apiClient: APIClient,
        database: DatabaseManager,
        startPage: Int = 0
    ) async {
        self.chapter = chapter
        self.apiClient = apiClient
        self.database = database
        self.totalPages = chapter.pageCount
        self.currentPage = min(startPage, max(0, chapter.pageCount - 1))

        await loadCurrentPage()
        prefetchAdjacentPages()
    }

    // MARK: - Navigation

    /// Navigate to the next page.
    func nextPage() async {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
        await loadCurrentPage()
        saveProgress()
        prefetchAdjacentPages()
    }

    /// Navigate to the previous page.
    func previousPage() async {
        guard currentPage > 0 else { return }
        currentPage -= 1
        await loadCurrentPage()
        saveProgress()
        prefetchAdjacentPages()
    }

    /// Jump to a specific page.
    ///
    /// - Parameter page: Zero-based page number.
    func goToPage(_ page: Int) async {
        guard page >= 0, page < totalPages else { return }
        currentPage = page
        await loadCurrentPage()
        saveProgress()
        prefetchAdjacentPages()
    }

    // MARK: - Page Loading

    /// Load the current page image.
    private func loadCurrentPage() async {
        guard let chapter, let apiClient else { return }

        // Check prefetch cache
        if let prefetched = prefetchedImages[currentPage] {
            currentImage = prefetched
            prefetchedImages.removeValue(forKey: currentPage)
            return
        }

        isLoading = true
        errorMessage = nil

        let cacheKey = "chapter_\(chapter.id)_page_\(currentPage)"

        // Check image cache
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            currentImage = cached
            isLoading = false
            return
        }

        // Fetch from server
        do {
            let image = try await apiClient.fetchPageImage(
                chapterId: chapter.id,
                pageNumber: currentPage
            )
            currentImage = image
            await ImageCache.shared.setImage(image, forKey: cacheKey)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Prefetch the next and previous pages for smooth navigation.
    private func prefetchAdjacentPages() {
        guard let chapter, let apiClient else { return }

        let pagesToPrefetch = [currentPage + 1, currentPage + 2]
        for page in pagesToPrefetch {
            guard page < totalPages, prefetchedImages[page] == nil else {
                continue
            }
            Task {
                let cacheKey = "chapter_\(chapter.id)_page_\(page)"
                if let cached = await ImageCache.shared.image(forKey: cacheKey) {
                    prefetchedImages[page] = cached
                    return
                }
                do {
                    let image = try await apiClient.fetchPageImage(
                        chapterId: chapter.id,
                        pageNumber: page
                    )
                    prefetchedImages[page] = image
                    await ImageCache.shared.setImage(image, forKey: cacheKey)
                } catch {
                    // Prefetch failures are non-critical
                }
            }
        }
    }

    // MARK: - Progress

    /// Persist the current reading position.
    private func saveProgress() {
        guard let chapter, let database else { return }
        database.saveProgress(
            mangaId: chapter.mangaId,
            chapterId: chapter.id,
            currentPage: currentPage,
            totalPages: totalPages
        )
    }

    /// Progress display text (e.g., "5 / 24").
    var progressText: String {
        "\(currentPage + 1) / \(totalPages)"
    }

    /// Progress fraction for a progress bar.
    var progressFraction: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage + 1) / Double(totalPages)
    }
}
