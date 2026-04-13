import Foundation

/// Navigation tabs in the sidebar
enum AppTab: String, CaseIterable, Identifiable {
    case combine = "Combine"
    case compress = "Compress"
    case convert = "Convert"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .combine: return "doc.on.doc"
        case .compress: return "arrow.down.doc"
        case .convert: return "photo.on.rectangle.angled"
        case .settings: return "gearshape"
        }
    }

    var description: String {
        switch self {
        case .combine: return "Merge multiple PDFs into one"
        case .compress: return "Reduce PDF file size"
        case .convert: return "Convert PDF pages to images"
        case .settings: return "App preferences"
        }
    }
}
