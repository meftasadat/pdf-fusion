import Foundation
import PDFKit
import AppKit

/// Represents a single PDF file added to the combine queue
struct PDFFileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let fileName: String
    let pageCount: Int
    let fileSize: Int64
    let thumbnail: NSImage?

    init?(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let document = PDFDocument(url: url) else { return nil }

        self.url = url
        self.fileName = url.lastPathComponent
        self.pageCount = document.pageCount
        self.fileSize = url.fileSize ?? 0

        // Generate thumbnail from first page
        if let firstPage = document.page(at: 0) {
            let pageRect = firstPage.bounds(for: .mediaBox)
            let scale: CGFloat = 60.0 / max(pageRect.width, pageRect.height)
            let thumbnailSize = NSSize(
                width: pageRect.width * scale,
                height: pageRect.height * scale
            )
            self.thumbnail = firstPage.thumbnail(of: CGSize(width: thumbnailSize.width, height: thumbnailSize.height), for: .mediaBox)
        } else {
            self.thumbnail = nil
        }
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PDFFileItem, rhs: PDFFileItem) -> Bool {
        lhs.id == rhs.id
    }
}
