// MangaDetailView.swift
// Comic Viewer – Manga Detail & Chapter List
//
// Shows manga metadata (cover, title, author) and a list of chapters.
// Tapping a chapter opens the reader.

import SwiftUI

/// Detail view for a single manga, showing its chapter list.
struct MangaDetailView: View {
    @EnvironmentObject var appState: AppState

    /// Initial manga data (may be refreshed from API)
    let manga: Manga

    /// Full manga detail with chapters
    @State private var detail: Manga?

    /// Reading progress from local DB
    @State private var progress: ReadingProgress?

    /// Loading state
    @State private var isLoading = true

    /// Error message
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                progressSection
                chaptersSection
            }
            .padding()
        }
        .navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetail()
        }
    }

    // MARK: - Sections

    /// Header with cover image, title, and metadata.
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Cover image
            AsyncCoverImage(mangaId: manga.id, apiClient: appState.apiClient)
                .frame(width: 120, height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(manga.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if let author = manga.author, !author.isEmpty {
                    Label(author, systemImage: "person")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Label(
                    "\(detail?.totalChapters ?? manga.totalChapters) chapters",
                    systemImage: "book"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let desc = manga.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
            }
        }
    }

    /// Progress indicator and resume button.
    @ViewBuilder
    private var progressSection: some View {
        if let progress, progress.chapterId != nil {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.indigo)
                    Text("Continue Reading")
                        .font(.headline)
                }

                ProgressView(
                    value: progress.progressPercent
                )
                .tint(.indigo)

                Text("Page \(progress.currentPage + 1) of \(progress.totalPages)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }

    /// List of chapters.
    private var chaptersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chapters")
                .font(.title3)
                .fontWeight(.semibold)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let chapters = detail?.chapters, !chapters.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(chapters) { chapter in
                        NavigationLink {
                            ReaderView(
                                chapter: chapter,
                                startPage: startPage(for: chapter)
                            )
                        } label: {
                            ChapterRow(
                                chapter: chapter,
                                isCurrentChapter: chapter.id == progress?.chapterId
                            )
                        }
                        Divider()
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No chapters available.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }

    // MARK: - Data Loading

    /// Fetch full manga detail with chapters from the API.
    private func loadDetail() async {
        isLoading = true
        do {
            detail = try await appState.apiClient.fetchManga(id: manga.id)
            progress = appState.database.getProgress(mangaId: manga.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Determine the start page for a chapter based on saved progress.
    private func startPage(for chapter: Chapter) -> Int {
        if chapter.id == progress?.chapterId {
            return progress?.currentPage ?? 0
        }
        return 0
    }
}

// MARK: - Chapter Row

/// A single row in the chapter list.
struct ChapterRow: View {
    let chapter: Chapter
    let isCurrentChapter: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.displayTitle)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("\(chapter.pageCount) pages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isCurrentChapter {
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(.indigo)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Async Cover Image

/// Asynchronously loads and displays a manga cover.
struct AsyncCoverImage: View {
    let mangaId: Int
    let apiClient: APIClient

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                image = try await apiClient.fetchCoverImage(mangaId: mangaId)
            } catch {
                // No cover available
            }
        }
    }
}
