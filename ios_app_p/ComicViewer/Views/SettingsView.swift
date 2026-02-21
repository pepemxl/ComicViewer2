// SettingsView.swift
// Comic Viewer – Settings & Source Management
//
// Allows users to configure the backend server URL,
// manage comic sources, and clear caches.

import SwiftUI

/// Settings screen for server configuration and source management.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    /// Server connection status
    @State private var isConnected = false

    /// Server URL input field
    @State private var serverURLInput = ""

    /// Registered sources from the server
    @State private var sources: [Source] = []

    /// Loading state
    @State private var isLoading = false

    /// Alert message
    @State private var alertMessage: String?

    /// Show alert flag
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            List {
                serverSection
                sourcesSection
                cacheSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                serverURLInput = appState.serverURL
            }
            .task {
                await checkConnection()
            }
            .alert("Info", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    /// Server configuration section.
    private var serverSection: some View {
        Section {
            HStack {
                TextField("Server URL", text: $serverURLInput)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Button("Save") {
                    appState.serverURL = serverURLInput
                    Task { await checkConnection() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)

                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Test") {
                    Task { await checkConnection() }
                }
                .controlSize(.small)
            }
        } header: {
            Label("Server", systemImage: "server.rack")
        }
    }

    /// Comic sources section.
    private var sourcesSection: some View {
        Section {
            if sources.isEmpty {
                Text("No sources registered.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.body)
                            .fontWeight(.medium)

                        Text(source.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        HStack {
                            Text(source.sourceType)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.indigo.opacity(0.15))
                                )

                            Spacer()

                            Button("Scan") {
                                Task { await scanSource(source) }
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                Task { await loadSources() }
            } label: {
                Label("Refresh Sources", systemImage: "arrow.clockwise")
            }
        } header: {
            Label("Sources", systemImage: "folder")
        }
    }

    /// Cache management section.
    private var cacheSection: some View {
        Section {
            Button(role: .destructive) {
                Task {
                    await ImageCache.shared.clearAll()
                    showAlertMessage("Image cache cleared.")
                }
            } label: {
                Label("Clear Image Cache", systemImage: "trash")
            }
        } header: {
            Label("Cache", systemImage: "internaldrive")
        }
    }

    /// About section.
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Platform")
                Spacer()
                Text("iOS 17+")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("About", systemImage: "info.circle")
        }
    }

    // MARK: - Actions

    /// Check the connection to the backend server.
    private func checkConnection() async {
        isConnected = await appState.apiClient.checkHealth()
        if isConnected {
            await loadSources()
        }
    }

    /// Load registered sources from the server.
    private func loadSources() async {
        do {
            sources = try await appState.apiClient.fetchSources()
        } catch {
            sources = []
        }
    }

    /// Trigger a scan on a source.
    private func scanSource(_ source: Source) async {
        isLoading = true
        do {
            let result = try await appState.apiClient.scanSource(id: source.id)
            showAlertMessage(
                "Scan complete! Found \(result.mangasFound) mangas "
                + "and \(result.chaptersFound) chapters."
            )
        } catch {
            showAlertMessage("Scan failed: \(error.localizedDescription)")
        }
        isLoading = false
    }

    /// Show an alert with a message.
    private func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
