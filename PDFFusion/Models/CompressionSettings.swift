import Foundation

/// Settings for PDF compression using a continuous compression level
struct CompressionSettings {
    /// Compression level from 0.0 (no compression / best quality) to 1.0 (max compression / smallest file)
    var compressionLevel: Double = 0.5
    var isEnabled: Bool = false

    /// Display percentage (0–100)
    var compressionPercent: Int {
        Int(compressionLevel * 100)
    }

    /// Target DPI for image downsampling
    /// Ranges from 300 DPI (level 0) down to 36 DPI (level 1)
    var targetDPI: CGFloat {
        let maxDPI: Double = 300
        let minDPI: Double = 36
        return CGFloat(maxDPI - (compressionLevel * (maxDPI - minDPI)))
    }

    /// JPEG quality factor (0.0 - 1.0)
    /// Ranges from 0.95 (level 0) down to 0.1 (level 1)
    var imageQuality: CGFloat {
        let maxQuality: Double = 0.95
        let minQuality: Double = 0.1
        return CGFloat(maxQuality - (compressionLevel * (maxQuality - minQuality)))
    }

    /// Human-readable quality label based on current level
    var qualityLabel: String {
        switch compressionLevel {
        case 0..<0.2: return "Minimal"
        case 0.2..<0.4: return "Light"
        case 0.4..<0.6: return "Medium"
        case 0.6..<0.8: return "Heavy"
        default: return "Maximum"
        }
    }

    /// Icon for the current compression level
    var qualityIcon: String {
        switch compressionLevel {
        case 0..<0.3: return "leaf"
        case 0.3..<0.7: return "slider.horizontal.3"
        default: return "bolt"
        }
    }
}
