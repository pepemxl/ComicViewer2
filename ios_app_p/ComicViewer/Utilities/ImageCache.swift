// ImageCache.swift
// Comic Viewer – In-Memory and Disk Image Cache
//
// Provides a two-tier caching system for comic page images:
// an in-memory NSCache for fast access and a disk cache for persistence.

import Foundation
import UIKit

/// Actor-based image cache with in-memory and disk tiers.
actor ImageCache {
    /// Shared singleton instance.
    static let shared = ImageCache()

    /// In-memory cache using NSCache (auto-eviction under memory pressure)
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Disk cache directory URL
    private let diskCacheURL: URL

    /// Maximum disk cache size in bytes (200 MB)
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024

    // MARK: - Initialization

    private init() {
        let caches = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first!
        self.diskCacheURL = caches.appendingPathComponent(
            "ComicViewerImageCache",
            isDirectory: true
        )

        // Create cache directory
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )

        // Configure memory cache limits
        memoryCache.countLimit = 100          // max 100 images
        memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
    }

    // MARK: - Public API

    /// Retrieve an image from cache (memory first, then disk).
    ///
    /// - Parameter key: Cache key (e.g., "chapter_5_page_3").
    /// - Returns: Cached image or nil.
    func image(forKey key: String) -> UIImage? {
        let nsKey = key as NSString

        // Check memory cache first
        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        // Check disk cache
        let fileURL = diskCacheURL.appendingPathComponent(
            key.sha256Hash + ".jpg"
        )
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data)
        else {
            return nil
        }

        // Promote to memory cache
        memoryCache.setObject(
            image,
            forKey: nsKey,
            cost: data.count
        )
        return image
    }

    /// Store an image in both memory and disk caches.
    ///
    /// - Parameters:
    ///   - image: The image to cache.
    ///   - key: Cache key.
    func setImage(_ image: UIImage, forKey key: String) {
        let nsKey = key as NSString

        // Memory cache
        if let data = image.jpegData(compressionQuality: 0.9) {
            memoryCache.setObject(
                image,
                forKey: nsKey,
                cost: data.count
            )

            // Disk cache (fire-and-forget)
            let fileURL = diskCacheURL.appendingPathComponent(
                key.sha256Hash + ".jpg"
            )
            try? data.write(to: fileURL)
        }
    }

    /// Remove a specific image from all cache tiers.
    ///
    /// - Parameter key: Cache key.
    func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        let fileURL = diskCacheURL.appendingPathComponent(
            key.sha256Hash + ".jpg"
        )
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Clear the entire cache (memory and disk).
    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(
            at: diskCacheURL,
            withIntermediateDirectories: true
        )
    }
}

// MARK: - String Hashing Extension

import CryptoKit

extension String {
    /// Compute a SHA-256 hex digest for use as a cache filename.
    var sha256Hash: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
