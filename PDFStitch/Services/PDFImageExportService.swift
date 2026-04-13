import Foundation
import PDFKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Errors that can occur during PDF-to-image export
enum PDFImageExportError: LocalizedError {
    case invalidInput(String)
    case exportFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let name):
            return "Could not read PDF file: \(name)"
        case .exportFailed(let reason):
            return "Image export failed: \(reason)"
        case .writeFailed(let path):
            return "Failed to save image to: \(path)"
        }
    }
}

/// Service for converting PDF pages to individual image files
actor PDFImageExportService {

    /// Exports all pages of a PDF as individual images
    /// - Parameters:
    ///   - inputURL: URL of the source PDF
    ///   - settings: Export settings (format, DPI, quality)
    ///   - outputDirectory: Directory to write images into
    ///   - fileNamePrefix: Prefix for output filenames (e.g., "MyDocument")
    ///   - progress: Callback reporting progress 0.0 to 1.0
    /// - Returns: Array of URLs for the exported image files
    func exportPages(
        inputURL: URL,
        settings: ImageExportSettings,
        outputDirectory: URL,
        fileNamePrefix: String,
        progress: @escaping @Sendable (Double) -> Void
    ) throws -> [URL] {
        guard let document = PDFDocument(url: inputURL) else {
            throw PDFImageExportError.invalidInput(inputURL.lastPathComponent)
        }

        let pageCount = document.pageCount
        guard pageCount > 0 else {
            throw PDFImageExportError.invalidInput("Document has no pages")
        }

        // Ensure output directory exists
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let dpiScale = settings.dpiScale
        var exportedURLs: [URL] = []

        for pageIndex in 0..<pageCount {
            guard let page = document.page(at: pageIndex) else { continue }

            let pageRect = page.bounds(for: .cropBox)
            let rotation = page.rotation
            let isLandscape = rotation == 90 || rotation == 270

            let actualWidth = isLandscape ? pageRect.height : pageRect.width
            let actualHeight = isLandscape ? pageRect.width : pageRect.height
            let targetSize = CGSize(width: actualWidth * dpiScale, height: actualHeight * dpiScale)

            // Leverage built-in thumbnail generation which properly handles
            // iOS/macOS coordinate flipping, cropBox offsets, and Document rotations.
            let nsImage = page.thumbnail(of: targetSize, for: .cropBox)

            guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw PDFImageExportError.exportFailed("Could not render page \(pageIndex + 1)")
            }

            // Build output filename: prefix_page_001.png
            let pageNumber = String(format: "%03d", pageIndex + 1)
            let fileName = "\(fileNamePrefix)_page_\(pageNumber).\(settings.format.fileExtension)"
            let outputURL = outputDirectory.appendingPathComponent(fileName)

            // Write image to disk
            try writeImage(cgImage, to: outputURL, settings: settings)
            exportedURLs.append(outputURL)

            let currentProgress = Double(pageIndex + 1) / Double(pageCount)
            progress(currentProgress)
        }

        return exportedURLs
    }

    /// Estimates the total output size by sampling the first page
    func estimateTotalSize(
        for url: URL,
        settings: ImageExportSettings
    ) -> Int64 {
        guard let document = PDFDocument(url: url),
              document.pageCount > 0,
              let firstPage = document.page(at: 0) else {
            return 0
        }

        let pageCount = document.pageCount
        let dpiScale = settings.dpiScale
        let pageRect = firstPage.bounds(for: .cropBox)
        let rotation = firstPage.rotation
        let isLandscape = rotation == 90 || rotation == 270

        let actualWidth = isLandscape ? pageRect.height : pageRect.width
        let actualHeight = isLandscape ? pageRect.width : pageRect.height
        let targetSize = CGSize(width: actualWidth * dpiScale, height: actualHeight * dpiScale)

        let nsImage = firstPage.thumbnail(of: targetSize, for: .cropBox)
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return 0 }

        // Write to temp data to measure size
        let data = NSMutableData()
        let utType = settings.format.utType.identifier as CFString
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, utType, 1, nil) else {
            return 0
        }

        var options: [CFString: Any] = [:]
        if settings.format == .jpeg {
            options[kCGImageDestinationLossyCompressionQuality] = settings.jpegQuality
        }
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        let singlePageSize = Int64(data.length)
        return singlePageSize * Int64(pageCount)
    }

    // MARK: - Private

    /// Writes a CGImage to disk in the specified format
    private func writeImage(_ image: CGImage, to url: URL, settings: ImageExportSettings) throws {
        let utType = settings.format.utType.identifier as CFString

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, utType, 1, nil) else {
            throw PDFImageExportError.writeFailed(url.path)
        }

        var options: [CFString: Any] = [:]
        if settings.format == .jpeg {
            options[kCGImageDestinationLossyCompressionQuality] = settings.jpegQuality
        }

        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw PDFImageExportError.writeFailed(url.path)
        }
    }
}
