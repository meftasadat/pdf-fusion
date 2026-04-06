import Foundation
import PDFKit

/// Errors that can occur during PDF merging
enum PDFMergeError: LocalizedError {
    case noFiles
    case invalidFile(String)
    case writeFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .noFiles:
            return "No PDF files to merge"
        case .invalidFile(let name):
            return "Could not read PDF file: \(name)"
        case .writeFailed(let path):
            return "Failed to save merged PDF to: \(path)"
        case .cancelled:
            return "Merge operation was cancelled"
        }
    }
}

/// Service for merging multiple PDF files into one
actor PDFMergerService {

    /// Merges multiple PDF files into a single document
    /// - Parameters:
    ///   - files: Array of PDFFileItem to merge in order
    ///   - outputURL: Optional output URL. If nil, a temp file is created
    ///   - progress: Callback reporting progress 0.0 to 1.0
    /// - Returns: URL of the merged PDF file
    func merge(
        files: [PDFFileItem],
        outputURL: URL? = nil,
        progress: @escaping @Sendable (Double) -> Void
    ) throws -> URL {
        guard !files.isEmpty else {
            throw PDFMergeError.noFiles
        }

        let destination = PDFDocument()
        let totalPages = files.reduce(0) { $0 + $1.pageCount }
        var processedPages = 0

        for file in files {
            guard let source = PDFDocument(url: file.url) else {
                throw PDFMergeError.invalidFile(file.fileName)
            }

            for pageIndex in 0..<source.pageCount {
                if let page = source.page(at: pageIndex) {
                    destination.insert(page, at: destination.pageCount)
                    processedPages += 1
                    let currentProgress = Double(processedPages) / Double(totalPages)
                    progress(currentProgress)
                }
            }
        }

        let output = outputURL ?? Self.generateTempURL()

        guard destination.write(to: output) else {
            throw PDFMergeError.writeFailed(output.path)
        }

        return output
    }

    /// Generates a temporary file URL for the merged output
    private static func generateTempURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "PDFFusion_Merged_\(Self.timestamp()).pdf"
        return tempDir.appendingPathComponent(fileName)
    }

    /// Generates a timestamp string for file naming
    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
