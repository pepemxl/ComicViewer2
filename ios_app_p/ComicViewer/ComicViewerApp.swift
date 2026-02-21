// ComicViewerApp.swift
// Comic Viewer – iOS App Entry Point
//
// Main application file using SwiftUI App lifecycle.
// Targets iOS 17+ with modern Swift concurrency.

import SwiftUI

/// Main application entry point for the Comic Viewer app.
@main
struct ComicViewerApp: App {
    /// Shared app state for dependency injection
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

/// Root content view with tab-based navigation.
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.indigo)
    }
}

/// Global application state shared across views.
@MainActor
final class AppState: ObservableObject {
    /// Base URL of the Python backend server
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "serverURL")
            apiClient = APIClient(baseURL: serverURL)
        }
    }

    /// API client instance
    @Published var apiClient: APIClient

    /// Local database manager
    let database: DatabaseManager

    init() {
        let savedURL = UserDefaults.standard.string(forKey: "serverURL")
            ?? "http://localhost:8000"
        self.serverURL = savedURL
        self.apiClient = APIClient(baseURL: savedURL)
        self.database = DatabaseManager()
    }
}
