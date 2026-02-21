// CBZParser.swift
// Comic Viewer – Local CBZ/ZIP Archive Parser
//
// Extracts comic pages from CBZ (ZIP) archives stored on the device.
// Uses Foundation's built-in archive support.

import Foundation
import UIKit
import UniformTypeIdentifiers

/// Parses CBZ (Comic Book ZIP) archives for local reading.
final class CBZParser {
    /// Supported image UTTypes for filtering archive entries.
    private static let imageUTTypes: Set<UTType> = [
        .jpeg, .png, .webP, .gif, .bmp, .tiff
    ]

    /// Supported image file extensions (lowercase).
    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "gif", "bmp", "tiff"
    ]

    // MARK: - Public API

    /// List all image page names in a CBZ archive, sorted.
    ///
    /// - Parameter url: File URL to the CBZ/ZIP archive.
    /// - Returns: Sorted array of image entry names.
    static func listPages(in url: URL) throws -> [String] {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw CBZError.cannotOpenArchive
        }

        let pages = archive
            .compactMap { entry -> String? in
                let name = entry.path
                guard !name.hasPrefix("__MACOSX"),
                      isImageFile(name)
                else { return nil }
                return name
            }
            .sorted()

        return pages
    }

    /// Extract a single page image from a CBZ archive.
    ///
    /// - Parameters:
    ///   - url: File URL to the CBZ/ZIP archive.
    ///   - pageName: Name of the image entry within the archive.
    /// - Returns: The extracted image.
    static func extractPage(
        from url: URL,
        pageName: String
    ) throws -> UIImage {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw CBZError.cannotOpenArchive
        }
        guard let entry = archive[pageName] else {
            throw CBZError.pageNotFound
        }

        var imageData = Data()
        _ = try archive.extract(entry) { chunk in
            imageData.append(chunk)
        }

        guard let image = UIImage(data: imageData) else {
            throw CBZError.invalidImageData
        }
        return image
    }

    /// Extract a page by its zero-based index.
    ///
    /// - Parameters:
    ///   - url: File URL to the CBZ/ZIP archive.
    ///   - index: Zero-based page index.
    /// - Returns: The extracted image.
    static func extractPage(
        from url: URL,
        at index: Int
    ) throws -> UIImage {
        let pages = try listPages(in: url)
        guard index >= 0, index < pages.count else {
            throw CBZError.pageNotFound
        }
        return try extractPage(from: url, pageName: pages[index])
    }

    /// Get the total number of pages in a CBZ archive.
    ///
    /// - Parameter url: File URL to the CBZ/ZIP archive.
    /// - Returns: Number of image pages.
    static func pageCount(in url: URL) throws -> Int {
        try listPages(in: url).count
    }

    // MARK: - Helpers

    /// Check if a filename has a supported image extension.
    private static func isImageFile(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }
}

// MARK: - Minimal ZIP Archive Reader

/// A minimal ZIP archive reader using Foundation.
/// This avoids third-party dependencies for basic CBZ support.
final class Archive: Sequence {
    /// Entries in the archive
    private(set) var entries: [Entry] = []

    /// File handle for reading
    private let fileHandle: FileHandle

    /// File URL
    private let url: URL

    /// Open an archive from a file URL.
    init?(url: URL, accessMode: AccessMode) {
        self.url = url
        guard let handle = FileHandle(forReadingAtPath: url.path) else {
            return nil
        }
        self.fileHandle = handle
        self.entries = parseEntries()
    }

    deinit {
        fileHandle.closeFile()
    }

    /// Access mode for the archive.
    enum AccessMode {
        case read
    }

    /// A single entry in the ZIP archive.
    struct Entry {
        let path: String
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
        let compressionMethod: UInt16
    }

    /// Subscript access by entry path.
    subscript(path: String) -> Entry? {
        entries.first { $0.path == path }
    }

    // MARK: - Sequence

    func makeIterator() -> IndexingIterator<[Entry]> {
        entries.makeIterator()
    }

    // MARK: - Extract

    /// Extract an entry and call the consumer with data chunks.
    func extract(
        _ entry: Entry,
        consumer: (Data) throws -> Void
    ) throws {
        fileHandle.seek(toFileOffset: UInt64(entry.localHeaderOffset))

        // Read local file header (30 bytes minimum)
        let localHeader = fileHandle.readData(ofLength: 30)
        guard localHeader.count == 30 else {
            throw CBZError.corruptArchive
        }

        // Parse filename length and extra field length
        let filenameLength = localHeader.readUInt16(at: 26)
        let extraLength = localHeader.readUInt16(at: 28)

        // Skip past filename and extra field to reach file data
        let dataOffset = UInt64(entry.localHeaderOffset) + 30
            + UInt64(filenameLength) + UInt64(extraLength)
        fileHandle.seek(toFileOffset: dataOffset)

        // Read the compressed data
        let compressedData = fileHandle.readData(
            ofLength: Int(entry.compressedSize)
        )

        if entry.compressionMethod == 0 {
            // Stored (no compression)
            try consumer(compressedData)
        } else if entry.compressionMethod == 8 {
            // Deflate – use Foundation's decompression
            let decompressed = try (compressedData as NSData)
                .decompressed(using: .zlib) as Data
            try consumer(decompressed)
        } else {
            throw CBZError.unsupportedCompression
        }
    }

    // MARK: - Parsing

    /// Parse the central directory to enumerate entries.
    private func parseEntries() -> [Entry] {
        guard let eocdOffset = findEndOfCentralDirectory() else {
            return []
        }

        fileHandle.seek(toFileOffset: UInt64(eocdOffset))
        let eocd = fileHandle.readData(ofLength: 22)
        guard eocd.count == 22 else { return [] }

        let centralDirOffset = eocd.readUInt32(at: 16)
        let entryCount = Int(eocd.readUInt16(at: 10))

        fileHandle.seek(toFileOffset: UInt64(centralDirOffset))
        var results: [Entry] = []

        for _ in 0..<entryCount {
            let header = fileHandle.readData(ofLength: 46)
            guard header.count == 46 else { break }

            // Verify central directory signature
            guard header.readUInt32(at: 0) == 0x02014B50 else { break }

            let compressionMethod = header.readUInt16(at: 10)
            let compressedSize = header.readUInt32(at: 20)
            let uncompressedSize = header.readUInt32(at: 24)
            let filenameLength = Int(header.readUInt16(at: 28))
            let extraLength = Int(header.readUInt16(at: 30))
            let commentLength = Int(header.readUInt16(at: 32))
            let localHeaderOffset = header.readUInt32(at: 42)

            // Read filename
            let filenameData = fileHandle.readData(ofLength: filenameLength)
            let filename = String(data: filenameData, encoding: .utf8) ?? ""

            // Skip extra and comment fields
            if extraLength + commentLength > 0 {
                fileHandle.seek(
                    toFileOffset: fileHandle.offsetInFile
                        + UInt64(extraLength + commentLength)
                )
            }

            results.append(Entry(
                path: filename,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localHeaderOffset: localHeaderOffset,
                compressionMethod: compressionMethod
            ))
        }

        return results
    }

    /// Search backwards for the End of Central Directory record.
    private func findEndOfCentralDirectory() -> Int? {
        let fileSize = fileHandle.seekToEndOfFile()
        let searchSize = min(fileSize, 65557)
        let searchStart = fileSize - searchSize
        fileHandle.seek(toFileOffset: searchStart)
        let data = fileHandle.readData(ofLength: Int(searchSize))

        // EOCD signature: 0x06054B50
        for i in stride(from: data.count - 4, through: 0, by: -1) {
            if data.readUInt32(at: i) == 0x06054B50 {
                return Int(searchStart) + i
            }
        }
        return nil
    }
}

// MARK: - Data Helpers

private extension Data {
    /// Read a little-endian UInt16 at the given byte offset.
    func readUInt16(at offset: Int) -> UInt16 {
        self.subdata(in: offset..<(offset + 2))
            .withUnsafeBytes { $0.load(as: UInt16.self).littleEndian }
    }

    /// Read a little-endian UInt32 at the given byte offset.
    func readUInt32(at offset: Int) -> UInt32 {
        self.subdata(in: offset..<(offset + 4))
            .withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
    }
}

// MARK: - Errors

/// Errors that can occur during CBZ parsing.
enum CBZError: LocalizedError {
    case cannotOpenArchive
    case pageNotFound
    case invalidImageData
    case corruptArchive
    case unsupportedCompression

    var errorDescription: String? {
        switch self {
        case .cannotOpenArchive:
            return "Cannot open the CBZ archive"
        case .pageNotFound:
            return "Page not found in archive"
        case .invalidImageData:
            return "Could not decode image from archive"
        case .corruptArchive:
            return "The archive appears to be corrupt"
        case .unsupportedCompression:
            return "Unsupported compression method"
        }
    }
}
