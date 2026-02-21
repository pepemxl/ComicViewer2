// swift-tools-version: 5.9
// Package.swift
// Comic Viewer – Swift Package Manifest
//
// This package manifest is provided for reference.
// To build the iOS app, create a new Xcode project (iOS App)
// and add the ComicViewer/ source files.

import PackageDescription

let package = Package(
    name: "ComicViewer",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "ComicViewer",
            path: "ComicViewer"
        )
    ]
)
