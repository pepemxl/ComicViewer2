// LibraryView.swift
// Comic Viewer – Library Grid View
//
// Displays a grid of available mangas with cover thumbnails.
// Supports pull-to-refresh and navigation to manga details.

import SwiftUI

/// Grid view displaying the user's comic/manga library.
struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LibraryViewModel()

    /// Adaptive grid columns
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading && viewModel.mangas.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.mangas.isEmpty {
                    errorView(message: error)
                } else if viewModel.mangas.isEmpty {
                    emptyView
                } else {
                    mangaGrid
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh(
                                using: appState.apiClient
                            )
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh(using: appState.apiClient)
            }
            .task {
                if viewModel.mangas.isEmpty {
                    await viewModel.loadMangas(using: appState.apiClient)
                }
            }
        }
    }

    // MARK: - Subviews

    /// Grid of manga cover cards
    private var mangaGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.mangas) { manga in
                NavigationLink(value: manga) {
                    MangaCoverCard(
                        manga: manga,
                        coverImage: viewModel.coverImages[manga.id]
                    )
                }
            }
        }
        .padding()
        .navigationDestination(for: Manga.self) { manga in
            MangaDetailView(manga: manga)
        }
    }

    /// Loading placeholder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading library…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    /// Empty state view
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Comics Found")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Add a source in Settings and scan for comics.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    /// Error state view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            Text("Connection Error")
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task {
                    await viewModel.loadMangas(using: appState.apiClient)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Manga Cover Card

/// A single manga card in the library grid.
struct MangaCoverCard: View {
    let manga: Manga
    let coverImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))

                if let coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)

            // Title
            Text(manga.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)

            // Chapter count
            Text("\(manga.totalChapters) chapters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
