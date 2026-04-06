import Foundation
import PDFKit

/// Errors that can occur during PDF validation
enum PDFValidationError: LocalizedError {
    case fileNotFound(String)
    case invalidPDF(String)
    case passwordProtected(String)
    case emptyDocument(String)
    case duplicateFile(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "File not found: \(name)"
        case .invalidPDF(let name):
            return "Invalid PDF file: \(name)"
        case .passwordProtected(let name):
            return "Password-protected PDF: \(name)"
        case .emptyDocument(let name):
            return "Empty document: \(name)"
        case .duplicateFile(let name):
            return "Duplicate file: \(name)"
        }
    }
}

/// Service for validating PDF files before processing
struct FileValidatorService {

    /// Validates a single URL, returning the validated PDFFileItem or throwing an error
    static func validate(url: URL, existingFiles: [PDFFileItem] = []) throws -> PDFFileItem {
        let fileName = url.lastPathComponent

        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFValidationError.fileNotFound(fileName)
        }

        // Check it's actually a PDF
        guard url.pathExtension.lowercased() == "pdf" else {
            throw PDFValidationError.invalidPDF(fileName)
        }

        // Try to open as PDF
        guard let document = PDFDocument(url: url) else {
            throw PDFValidationError.invalidPDF(fileName)
        }

        // Check for password protection
        if document.isLocked {
            throw PDFValidationError.passwordProtected(fileName)
        }

        // Check not empty
        guard document.pageCount > 0 else {
            throw PDFValidationError.emptyDocument(fileName)
        }

        // Check for duplicates by file path
        if existingFiles.contains(where: { $0.url.path == url.path }) {
            throw PDFValidationError.duplicateFile(fileName)
        }

        // Create the file item
        guard let fileItem = PDFFileItem(url: url) else {
            throw PDFValidationError.invalidPDF(fileName)
        }

        return fileItem
    }

    /// Validates multiple URLs, returning valid items and any errors
    static func validateBatch(urls: [URL], existingFiles: [PDFFileItem] = []) -> (valid: [PDFFileItem], errors: [PDFValidationError]) {
        var validItems: [PDFFileItem] = []
        var errors: [PDFValidationError] = []
        var currentFiles = existingFiles

        for url in urls {
            do {
                let item = try validate(url: url, existingFiles: currentFiles)
                validItems.append(item)
                currentFiles.append(item)
            } catch let error as PDFValidationError {
                errors.append(error)
            } catch {
                errors.append(.invalidPDF(url.lastPathComponent))
            }
        }

        return (validItems, errors)
    }

    /// Checks if a URL points to a valid PDF file (quick check without full validation)
    static func isPDF(url: URL) -> Bool {
        url.pathExtension.lowercased() == "pdf" && PDFDocument(url: url) != nil
    }
}
