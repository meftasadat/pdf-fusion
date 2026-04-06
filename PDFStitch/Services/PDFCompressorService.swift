import Foundation
import PDFKit
import Quartz
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Errors that can occur during PDF compression
enum PDFCompressionError: LocalizedError {
    case invalidInput(String)
    case compressionFailed(String)
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let name):
            return "Could not read PDF file: \(name)"
        case .compressionFailed(let reason):
            return "Compression failed: \(reason)"
        case .writeFailed(let path):
            return "Failed to save compressed PDF to: \(path)"
        }
    }
}

/// Service for compressing PDF files using Core Graphics
actor PDFCompressorService {

    /// Compresses a PDF file by rasterizing pages and applying JPEG compression
    /// - Parameters:
    ///   - inputURL: URL of the PDF to compress
    ///   - settings: Compression settings (quality, DPI)
    ///   - outputURL: Optional output URL. If nil, a temp file is created
    ///   - progress: Callback reporting progress 0.0 to 1.0
    /// - Returns: URL of the compressed PDF file
    func compress(
        inputURL: URL,
        settings: CompressionSettings,
        outputURL: URL? = nil,
        progress: @escaping @Sendable (Double) -> Void
    ) throws -> URL {
        guard let sourceDocument = PDFDocument(url: inputURL) else {
            throw PDFCompressionError.invalidInput(inputURL.lastPathComponent)
        }

        let output = outputURL ?? Self.generateTempURL()
        let pageCount = sourceDocument.pageCount

        guard pageCount > 0 else {
            throw PDFCompressionError.invalidInput("Document has no pages")
        }

        // Create PDF context for writing
        guard let pdfContext = CGContext(output as CFURL, mediaBox: nil, nil) else {
            throw PDFCompressionError.writeFailed(output.path)
        }

        let targetDPI = settings.targetDPI
        let imageQuality = settings.imageQuality

        // DPI scale relative to PDF base (72 DPI)
        // This controls the bitmap rendering resolution
        let dpiScale = targetDPI / 72.0

        for pageIndex in 0..<pageCount {
            guard let page = sourceDocument.page(at: pageIndex) else { continue }

            let pageRect = page.bounds(for: .mediaBox)

            // Bitmap size at target DPI
            let bitmapWidth = Int(pageRect.width * dpiScale)
            let bitmapHeight = Int(pageRect.height * dpiScale)

            // Output page size stays the same as original
            var mediaBox = CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height)

            pdfContext.beginPDFPage([
                kCGPDFContextMediaBox: Data(bytes: &mediaBox, count: MemoryLayout<CGRect>.size) as CFData
            ] as CFDictionary)

            // Step 1: Render the PDF page into a bitmap at target DPI
            if let bitmapContext = CGContext(
                data: nil,
                width: bitmapWidth,
                height: bitmapHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) {
                // Fill white background
                bitmapContext.setFillColor(CGColor.white)
                bitmapContext.fill(CGRect(x: 0, y: 0, width: bitmapWidth, height: bitmapHeight))

                // Scale and draw the PDF page into bitmap
                bitmapContext.scaleBy(x: dpiScale, y: dpiScale)
                bitmapContext.drawPDFPage(page.pageRef!)

                // Step 2: Get the rendered bitmap
                if let cgImage = bitmapContext.makeImage() {
                    // Step 3: Apply JPEG compression to reduce data size
                    if let compressedImage = Self.jpegCompressedImage(from: cgImage, quality: imageQuality) {
                        pdfContext.draw(compressedImage, in: mediaBox)
                    } else {
                        // Fallback: draw uncompressed bitmap (still reduces resolution)
                        pdfContext.draw(cgImage, in: mediaBox)
                    }
                }
            } else {
                // Fallback: copy page directly if bitmap creation fails
                if let pageRef = page.pageRef {
                    pdfContext.drawPDFPage(pageRef)
                }
            }

            pdfContext.endPDFPage()

            let currentProgress = Double(pageIndex + 1) / Double(pageCount)
            progress(currentProgress)
        }

        pdfContext.closePDF()

        // Verify the output was created
        guard FileManager.default.fileExists(atPath: output.path) else {
            throw PDFCompressionError.writeFailed(output.path)
        }

        return output
    }

    // MARK: - JPEG Compression

    /// Compresses a CGImage using JPEG encoding at the specified quality
    /// Returns a new CGImage decoded from the JPEG data, which CoreGraphics
    /// will store efficiently in the output PDF
    private static func jpegCompressedImage(from image: CGImage, quality: CGFloat) -> CGImage? {
        // Encode to JPEG data
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }

        // Decode JPEG data back to CGImage
        // When CoreGraphics draws this into a PDF context, it recognizes
        // the JPEG origin and passes the compressed data through
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let compressedImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        return compressedImage
    }

    // MARK: - Quartz Filter Compression

    /// Quick compression using the system Quartz "Reduce File Size" filter
    func compressWithQuartzFilter(
        inputURL: URL,
        outputURL: URL? = nil,
        progress: @escaping @Sendable (Double) -> Void
    ) throws -> URL {
        guard let sourceDocument = PDFDocument(url: inputURL) else {
            throw PDFCompressionError.invalidInput(inputURL.lastPathComponent)
        }

        let output = outputURL ?? Self.generateTempURL()

        // Try to use the built-in Quartz filter
        if let filter = QuartzFilter(url: URL(fileURLWithPath: "/System/Library/Filters/Reduce File Size.qfilter")) {
            progress(0.3)

            // Apply the filter to every page via CGContext
            let pageCount = sourceDocument.pageCount
            guard pageCount > 0 else {
                throw PDFCompressionError.invalidInput("Document has no pages")
            }

            // Use the filter's dictionary to configure the output context
            guard let pdfContext = CGContext(output as CFURL, mediaBox: nil, nil) else {
                throw PDFCompressionError.writeFailed(output.path)
            }

            // Apply the quartz filter to the context
            filter.apply(to: pdfContext)

            for pageIndex in 0..<pageCount {
                guard let page = sourceDocument.page(at: pageIndex) else { continue }
                let pageRect = page.bounds(for: .mediaBox)
                var mediaBox = CGRect(origin: .zero, size: pageRect.size)

                pdfContext.beginPDFPage([
                    kCGPDFContextMediaBox: Data(bytes: &mediaBox, count: MemoryLayout<CGRect>.size) as CFData
                ] as CFDictionary)

                if let pageRef = page.pageRef {
                    pdfContext.drawPDFPage(pageRef)
                }

                pdfContext.endPDFPage()

                let currentProgress = 0.3 + (Double(pageIndex + 1) / Double(pageCount) * 0.7)
                progress(currentProgress)
            }

            pdfContext.closePDF()

            if FileManager.default.fileExists(atPath: output.path) {
                progress(1.0)
                return output
            }
        }

        // Fallback: use our JPEG-based compression
        return try compress(
            inputURL: inputURL,
            settings: CompressionSettings(compressionLevel: 0.5, isEnabled: true),
            outputURL: output,
            progress: progress
        )
    }
    // MARK: - Estimation

    /// Estimates compressed size for a given compression level by compressing page 1 as a sample
    func estimateSize(for url: URL, settings: CompressionSettings, originalSize: Int64) -> Int64 {
        guard let document = PDFDocument(url: url),
              document.pageCount > 0,
              let firstPage = document.page(at: 0) else {
            return Self.fallbackEstimate(originalSize: originalSize, level: settings.compressionLevel)
        }

        let pageCount = document.pageCount
        let dpiScale = settings.targetDPI / 72.0
        let pageRect = firstPage.bounds(for: .mediaBox)
        let bitmapWidth = max(1, Int(pageRect.width * dpiScale))
        let bitmapHeight = max(1, Int(pageRect.height * dpiScale))

        guard let bitmapContext = CGContext(
            data: nil,
            width: bitmapWidth,
            height: bitmapHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return Self.fallbackEstimate(originalSize: originalSize, level: settings.compressionLevel)
        }

        bitmapContext.setFillColor(CGColor.white)
        bitmapContext.fill(CGRect(x: 0, y: 0, width: bitmapWidth, height: bitmapHeight))
        bitmapContext.scaleBy(x: dpiScale, y: dpiScale)
        bitmapContext.drawPDFPage(firstPage.pageRef!)

        guard let cgImage = bitmapContext.makeImage() else {
            return Self.fallbackEstimate(originalSize: originalSize, level: settings.compressionLevel)
        }

        // Measure JPEG data size for page 1
        let jpegData = NSMutableData()
        if let dest = CGImageDestinationCreateWithData(
            jpegData as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1, nil
        ) {
            CGImageDestinationAddImage(dest, cgImage, [
                kCGImageDestinationLossyCompressionQuality: settings.imageQuality
            ] as CFDictionary)
            CGImageDestinationFinalize(dest)
        }

        let page1Size = Int64(jpegData.length)
        let pdfOverhead: Int64 = 1024
        return (page1Size * Int64(pageCount)) + pdfOverhead
    }

    /// Fallback estimate using a simple ratio
    private static func fallbackEstimate(originalSize: Int64, level: Double) -> Int64 {
        // At level 0 (150 DPI): ~50% of original, at level 1 (36 DPI): ~5% of original
        let ratio = 0.50 - (level * 0.45)
        return max(1024, Int64(Double(originalSize) * ratio))
    }

    // MARK: - Utilities

    /// Generates a temporary file URL for the compressed output
    private static func generateTempURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "PDFStitch_Compressed_\(Self.timestamp()).pdf"
        return tempDir.appendingPathComponent(fileName)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
