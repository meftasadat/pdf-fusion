# PDF Fusion

A native macOS app to **combine** and **compress** PDF files with a modern, premium dark-mode interface.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 📄 **Combine PDFs** — Merge multiple PDF files into a single document
- 🗜️ **Compress PDFs** — Reduce file sizes with configurable quality settings
- 🎯 **Drag & Drop** — Simply drag files into the app
- 🔄 **Reorder** — Rearrange pages before combining
- 🌙 **Dark Mode** — Beautiful, premium dark-themed UI built with SwiftUI
- ⚡ **Fast** — Native performance with PDFKit

## Installation

### Homebrew (Recommended)

```bash
brew tap meftasadat/tap
brew install --cask pdf-fusion
```

### Manual Download

1. Go to [Releases](https://github.com/meftasadat/pdf-fusion/releases)
2. Download the latest `.dmg` file
3. Open the DMG and drag **PDF Fusion** to your Applications folder
4. Right-click the app → Open (first launch only, since the app is ad-hoc signed)

## Building from Source

### Prerequisites

- macOS 14.0+
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
# Clone the repo
git clone https://github.com/meftasadat/pdf-fusion.git
cd pdf-fusion

# Generate the Xcode project
xcodegen generate

# Build and run
open PDFFusion.xcodeproj
# Or build from command line:
xcodebuild -project PDFFusion.xcodeproj -scheme PDFFusion -configuration Release build
```

## Tech Stack

- **SwiftUI** — Modern declarative UI
- **PDFKit** — Apple's native PDF framework
- **XcodeGen** — Project file generation from `project.yml`

## Project Structure

```
PDFFusion/
├── Models/              # Data models (PDFFileItem, CompressionSettings)
├── Services/            # Core logic (merger, compressor, validator)
├── Utilities/           # Theme colors, formatters
├── ViewModels/          # MVVM view models
├── Views/
│   ├── Combine/         # PDF combining interface
│   ├── Compress/        # PDF compression interface
│   ├── Components/      # Reusable UI components
│   ├── Settings/        # App settings
│   └── Sidebar/         # Navigation sidebar
├── Assets.xcassets/     # App icons, colors
└── PDFFusionApp.swift   # App entry point
```

## License

MIT License — see [LICENSE](LICENSE) for details.
