// ReaderView.swift
// Comic Viewer – Full-Screen Page Reader
//
// Displays comic pages one at a time with swipe/tap navigation,
// a scrubber bar, and auto-saved reading progress.

import SwiftUI

/// Full-screen comic page reader with gesture navigation.
struct ReaderView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ReaderViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Chapter to read
    let chapter: Chapter

    /// Starting page (0-indexed)
    let startPage: Int

    /// Whether the toolbar overlay is visible
    @State private var showOverlay = true

    /// Drag gesture offset for page turning
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Page image
            pageContent

            // Toolbar overlay
            if showOverlay {
                overlayControls
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(!showOverlay)
        .task {
            await viewModel.setup(
                chapter: chapter,
                apiClient: appState.apiClient,
                database: appState.database,
                startPage: startPage
            )
        }
        .gesture(tapGesture)
        .gesture(dragGesture)
    }

    // MARK: - Page Content

    /// The main page image with pinch-to-zoom support.
    @ViewBuilder
    private var pageContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.white)
                .controlSize(.large)
        } else if let image = viewModel.currentImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(x: dragOffset)
                .animation(.interactiveSpring, value: dragOffset)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                Text(error)
                    .foregroundStyle(.white)
                Button("Retry") {
                    Task {
                        await viewModel.goToPage(viewModel.currentPage)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Overlay Controls

    /// Top and bottom toolbar overlay.
    private var overlayControls: some View {
        VStack {
            // Top bar
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.ultraThinMaterial))
                }

                Spacer()

                Text(chapter.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()

            // Bottom bar with scrubber
            VStack(spacing: 8) {
                // Page scrubber
                Slider(
                    value: Binding(
                        get: { Double(viewModel.currentPage) },
                        set: { newValue in
                            Task {
                                await viewModel.goToPage(Int(newValue))
                            }
                        }
                    ),
                    in: 0...max(Double(viewModel.totalPages - 1), 0),
                    step: 1
                )
                .tint(.indigo)

                // Page indicator
                Text(viewModel.progressText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                // Progress bar
                ProgressView(value: viewModel.progressFraction)
                    .tint(.indigo)
            }
            .padding()
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .transition(.opacity)
    }

    // MARK: - Gestures

    /// Tap gesture: tap left/right edges to turn pages, center to toggle overlay.
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                let screenWidth = UIScreen.main.bounds.width
                let tapX = value.location.x

                if tapX < screenWidth * 0.3 {
                    // Left third → previous page
                    Task { await viewModel.previousPage() }
                } else if tapX > screenWidth * 0.7 {
                    // Right third → next page
                    Task { await viewModel.nextPage() }
                } else {
                    // Center → toggle overlay
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showOverlay.toggle()
                    }
                }
            }
    }

    /// Drag gesture for swiping between pages.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let threshold: CGFloat = 80
                if value.translation.width < -threshold {
                    Task { await viewModel.nextPage() }
                } else if value.translation.width > threshold {
                    Task { await viewModel.previousPage() }
                }
                withAnimation(.spring) {
                    dragOffset = 0
                }
            }
    }
}
