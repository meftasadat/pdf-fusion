import Foundation
import UniformTypeIdentifiers

/// Supported image export formats
enum ImageExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpeg = "JPEG"

    var id: String { rawValue }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }

    var description: String {
        switch self {
        case .png: return "Lossless, larger files"
        case .jpeg: return "Lossy, smaller files"
        }
    }
}

/// Settings for PDF-to-image export
struct ImageExportSettings {
    /// Output image format
    var format: ImageExportFormat = .png

    /// Target DPI for rendering (72–600)
    var dpi: Double = 150.0

    /// JPEG quality (0.0–1.0), only used when format is .jpeg
    var jpegQuality: Double = 0.85

    // MARK: - Computed Properties

    /// DPI scale relative to PDF base (72 DPI)
    var dpiScale: CGFloat {
        CGFloat(dpi / 72.0)
    }

    /// Human-readable quality label based on DPI
    var qualityLabel: String {
        switch dpi {
        case ..<100: return "Draft"
        case ..<150: return "Low"
        case ..<200: return "Medium"
        case ..<300: return "High"
        case ..<450: return "Very High"
        default: return "Ultra"
        }
    }

    /// SF Symbol for quality badge
    var qualityIcon: String {
        switch dpi {
        case ..<150: return "circle"
        case ..<250: return "circle.lefthalf.filled"
        case ..<400: return "circle.fill"
        default: return "star.fill"
        }
    }

    /// DPI as integer for display
    var dpiInt: Int {
        Int(dpi)
    }

    /// Min/max DPI range
    static let minDPI: Double = 72.0
    static let maxDPI: Double = 600.0
}
