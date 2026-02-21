# Comic Viewer – iOS App

SwiftUI-based comic and manga reader for iOS 17+. Connects to the Python
backend for browsing and reading comics, with local CBZ file support and
offline reading progress.

## Setup

1. Open **Xcode 15+**
2. Create a new iOS App project (SwiftUI, Swift)
3. Copy the `ComicViewer/` folder contents into the project
4. Build and run on a simulator or device

## Project Structure

```
ComicViewer/
├── ComicViewerApp.swift          # App entry + tab navigation
├── Models/
│   ├── Manga.swift               # Manga data model
│   ├── Chapter.swift             # Chapter data model
│   └── ReadingProgress.swift     # Progress + Source models
├── Database/
│   └── DatabaseManager.swift     # Local SQLite (offline cache)
├── Network/
│   └── APIClient.swift           # URLSession API client
├── Views/
│   ├── LibraryView.swift         # Manga grid
│   ├── MangaDetailView.swift     # Chapter list
│   ├── ReaderView.swift          # Page reader
│   └── SettingsView.swift        # Server & sources
├── ViewModels/
│   ├── LibraryViewModel.swift    # Library state
│   └── ReaderViewModel.swift     # Reader state
├── Utilities/
│   ├── CBZParser.swift           # Local CBZ extraction
│   └── ImageCache.swift          # Two-tier image cache
└── Assets.xcassets/              # Colors, icons
```

## Features

- **Library Grid** – Browse available comics with covers
- **Chapter Reader** – Tap/swipe navigation, page scrubber
- **Reading Progress** – Auto-saved, resume from where you left off
- **Local CBZ** – Open .cbz files directly on device
- **Offline Cache** – Previously loaded pages available offline
- **Server Configuration** – Connect to any backend instance
