import Foundation
import PDFKit
import SwiftUI

/// Processing state for async operations
enum ProcessingState: Equatable {
    case idle
    case processing(message: String)
    case success(message: String, outputURL: URL)
    case error(message: String)

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
}

/// Main view model managing all app state
@Observable
class PDFViewModel {
    // MARK: - State
    var files: [PDFFileItem] = []
    var selectedTab: AppTab = .combine
    var processingState: ProcessingState = .idle
    var progress: Double = 0.0
    var compressionSettings = CompressionSettings()
    var validationErrors: [String] = []

    // Compress tab state
    var compressInputFile: PDFFileItem? = nil
    var compressOutputURL: URL? = nil
    var compressOriginalSize: Int64 = 0
    var compressResultSize: Int64 = 0
    var compressEstimatedSize: Int64 = 0
    var isEstimating: Bool = false

    // MARK: - Services
    private let mergerService = PDFMergerService()
    private let compressorService = PDFCompressorService()

    // MARK: - Computed Properties

    var totalPages: Int {
        files.reduce(0) { $0 + $1.pageCount }
    }

    var totalFileSize: Int64 {
        files.reduce(0) { $0 + $1.fileSize }
    }

    var canCombine: Bool {
        files.count >= 2 && !processingState.isProcessing
    }

    var estimatedCompressedSize: Int64 {
        compressEstimatedSize
    }

    var filesSummary: String {
        if files.isEmpty { return "No files added" }
        let pageText = totalPages == 1 ? "page" : "pages"
        return "\(files.count) files · \(totalPages) \(pageText) · \(totalFileSize.formattedFileSize)"
    }

    // MARK: - File Management

    /// Add files from URLs (drag-drop or file picker)
    func addFiles(urls: [URL]) {
        // Start accessing security-scoped resources
        let accessedURLs = urls.map { url -> URL in
            _ = url.startAccessingSecurityScopedResource()
            return url
        }

        let result = FileValidatorService.validateBatch(urls: accessedURLs, existingFiles: files)

        // Add valid files
        files.append(contentsOf: result.valid)

        // Collect errors
        if !result.errors.isEmpty {
            validationErrors = result.errors.map { $0.localizedDescription }
            // Auto-clear errors after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.validationErrors = []
            }
        }

        // Stop accessing security-scoped resources
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    /// Remove a specific file
    func removeFile(_ file: PDFFileItem) {
        files.removeAll { $0.id == file.id }
    }

    /// Move files for reordering
    func moveFiles(from source: IndexSet, to destination: Int) {
        files.move(fromOffsets: source, toOffset: destination)
    }

    /// Clear all files
    func clearAll() {
        files.removeAll()
        processingState = .idle
        progress = 0.0
        validationErrors = []
    }

    // MARK: - Combine

    /// Combine all files into a single PDF
    func combineFiles() async {
        guard canCombine else { return }

        await MainActor.run {
            processingState = .processing(message: "Merging \(files.count) files...")
            progress = 0.0
        }

        do {
            // Step 1: Merge
            let mergedURL = try await mergerService.merge(
                files: files,
                progress: { [weak self] p in
                    Task { @MainActor in
                        if self?.compressionSettings.isEnabled ?? false {
                            self?.progress = p * 0.6  // 60% for merge, 40% for compress
                        } else {
                            self?.progress = p
                        }
                    }
                }
            )

            var finalURL = mergedURL

            // Step 2: Compress (optional)
            if compressionSettings.isEnabled {
                await MainActor.run {
                    processingState = .processing(message: "Compressing output...")
                }

                finalURL = try await compressorService.compress(
                    inputURL: mergedURL,
                    settings: compressionSettings,
                    progress: { [weak self] p in
                        Task { @MainActor in
                            self?.progress = 0.6 + (p * 0.4)
                        }
                    }
                )

                // Clean up temp merged file if we compressed to a new one
                if finalURL != mergedURL {
                    try? FileManager.default.removeItem(at: mergedURL)
                }
            }

            await MainActor.run {
                progress = 1.0
                processingState = .success(
                    message: "PDF combined successfully!",
                    outputURL: finalURL
                )
            }

            // Prompt save dialog
            await promptSaveDialog(tempURL: finalURL)

        } catch {
            await MainActor.run {
                processingState = .error(message: error.localizedDescription)
                progress = 0.0
            }
        }
    }

    // MARK: - Compress (standalone)

    /// Load a file for compression without compressing yet
    func loadFileForCompression(url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        guard let fileItem = PDFFileItem(url: url) else {
            processingState = .error(message: "Could not read PDF file")
            return
        }

        compressInputFile = fileItem
        compressOriginalSize = fileItem.fileSize
        compressOutputURL = nil
        compressResultSize = 0
        compressEstimatedSize = 0
        processingState = .idle
        progress = 0.0

        // Compute initial estimate
        updateEstimate()
    }

    /// Update estimated size based on current slider level (debounced)
    func updateEstimate() {
        guard let fileItem = compressInputFile else { return }
        let fileURL = fileItem.url
        let originalSize = fileItem.fileSize
        let settings = compressionSettings
        isEstimating = true

        Task.detached { [weak self] in
            guard let self = self else { return }
            let estimate = await self.compressorService.estimateSize(
                for: fileURL,
                settings: settings,
                originalSize: originalSize
            )
            await MainActor.run {
                self.compressEstimatedSize = estimate
                self.isEstimating = false
            }
        }
    }

    /// Compress the currently loaded file with current compression level
    func performCompression() async {
        guard let fileItem = compressInputFile else { return }

        let url = fileItem.url
        _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        await MainActor.run {
            processingState = .processing(message: "Compressing \(fileItem.fileName)...")
            progress = 0.0
        }

        do {
            // Clean up previous output if any
            if let oldOutput = compressOutputURL {
                try? FileManager.default.removeItem(at: oldOutput)
            }

            let settings = CompressionSettings(
                compressionLevel: compressionSettings.compressionLevel,
                isEnabled: true
            )

            let outputURL = try await compressorService.compress(
                inputURL: url,
                settings: settings,
                progress: { [weak self] p in
                    Task { @MainActor in
                        self?.progress = p
                    }
                }
            )

            let resultSize = outputURL.fileSize ?? 0

            await MainActor.run {
                compressOutputURL = outputURL
                compressResultSize = resultSize
                progress = 1.0
                processingState = .success(
                    message: "Compressed: \(compressOriginalSize.formattedFileSize) → \(resultSize.formattedFileSize)",
                    outputURL: outputURL
                )
            }
        } catch {
            await MainActor.run {
                processingState = .error(message: error.localizedDescription)
                progress = 0.0
            }
        }
    }

    /// Clear compression result (e.g. when quality changes)
    func clearCompressResult() {
        if let oldOutput = compressOutputURL {
            try? FileManager.default.removeItem(at: oldOutput)
        }
        compressOutputURL = nil
        compressResultSize = 0
        processingState = .idle
        progress = 0.0
    }

    /// Reset compress state completely
    func resetCompressState() {
        if let oldOutput = compressOutputURL {
            try? FileManager.default.removeItem(at: oldOutput)
        }
        compressInputFile = nil
        compressOutputURL = nil
        compressOriginalSize = 0
        compressResultSize = 0
        compressEstimatedSize = 0
        isEstimating = false
        processingState = .idle
        progress = 0.0
    }

    // MARK: - File Dialog

    /// Show a save dialog for the merged/compressed PDF
    @MainActor
    func promptSaveDialog(tempURL: URL) async {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = tempURL.lastPathComponent
        savePanel.title = "Save Combined PDF"
        savePanel.message = "Choose where to save the combined PDF file"

        let response = savePanel.runModal()
        if response == .OK, let destinationURL = savePanel.url {
            do {
                // Remove existing file if needed
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: tempURL, to: destinationURL)

                processingState = .success(
                    message: "Saved to \(destinationURL.lastPathComponent)",
                    outputURL: destinationURL
                )

                // Open in Finder
                NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: "")
            } catch {
                processingState = .error(message: "Failed to save: \(error.localizedDescription)")
            }
        }

        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Dismiss

    func dismissResult() {
        processingState = .idle
        progress = 0.0
    }
}
