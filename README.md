# PDF Fusion: Native PDF Combiner & Compressor for macOS

A lightning-fast, completely native macOS application designed to effortlessly **combine**, **merge**, and **compress PDF files** locally. PDF Fusion features a premium, responsive dark-mode interface built with modern SwiftUI, allowing you to manage your documents securely without ever uploading sensitive files to the cloud.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Downloads](https://img.shields.io/github/downloads/meftasadat/pdf-fusion/total.svg)
![License](https://img.shields.io/badge/License-MIT-green)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/meftasadat)

<div align="center">
  <br/>
  <a href="https://github.com/meftasadat/pdf-fusion/releases/download/v1.0.4/PDFFusion-v1.0.4.dmg">
    <img src="https://img.shields.io/badge/Download_for_Mac-v1.0.4-000000?style=for-the-badge&logo=apple&logoColor=white" alt="Download for Mac" />
  </a>
  &nbsp;&nbsp;
  <a href="https://meftasadat.github.io/pdf-fusion/">
    <img src="https://img.shields.io/badge/Official_Website-Visit_Now-0052FF?style=for-the-badge&logo=safari&logoColor=white" alt="Official Website" />
  </a>
  <br/>
  <p align="center">
    <i>Experience the full landing page and feature walkthroughs at <a href="https://meftasadat.github.io/pdf-fusion/">meftasadat.github.io/pdf-fusion/</a></i>
  </p>
  <br/>
</div>

---

## Key Features

- 📄 **Combine & Merge PDFs** — Bring multiple PDF files together into a single, continuous document with one click.
- 🗜️ **Advanced PDF Compression** — Reduce PDF file sizes drastically using smart downsampling. Customize DPI and JPEG quality levels to find the perfect balance between clarity and file size.
- 🎯 **Intuitive Drag & Drop** — Add files instantly by dragging them directly from Finder into the app's drop zone.
- 🔄 **Reorder Files** — Easily drag-and-drop to rearrange your files into your preferred sequence before merging them.
- 🌙 **Premium Dark Mode UI** — Enjoy a visually stunning, meticulously designed interface optimized for modern Mac displays.
- ⚡ **Offline & Secure** — Built on Apple's native PDFKit and CoreGraphics. Maximum performance with total privacy—100% offline processing.

## Installation

### Homebrew (Recommended)

The easiest way to install and keep PDF Fusion up-to-date on your Mac:

```bash
brew tap meftasadat/tap
brew install --cask pdf-fusion
```

### Manual Download

1. Go to the [Releases page](https://github.com/meftasadat/pdf-fusion/releases)
2. Download the latest `.dmg` installer file.
3. Open the downloaded DMG and drag **PDF Fusion** into your Applications folder.
4. *Note: As an ad-hoc signed open source project, you'll need to Right-click the app → "Open" on your very first launch.*

## Building from Source

Are you a Swift developer? PDF Fusion is fully open-source and easy to compile.

### Prerequisites

- macOS 14.0+ (Sonoma or later)
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/meftasadat/pdf-fusion.git
cd pdf-fusion

# Generate the Xcode project
xcodegen generate

# Build and run using Xcode
open PDFFusion.xcodeproj

# Or compile headless from the command line:
xcodebuild -project PDFFusion.xcodeproj -scheme PDFFusion -configuration Release build
```

## Tech Stack & Architecture

- **SwiftUI** — Modern, declarative, reactive UI components
- **PDFKit & CoreGraphics** — Apple's incredibly fast, native document rendering frameworks
- **XcodeGen** — Clean project file generation from `project.yml` for zero Git-merge conflicts

```
PDFFusion/
├── Models/              # Data models (PDFFileItem, CompressionSettings)
├── Services/            # Core logic (PDFMergerService, PDFCompressorService)
├── Utilities/           # Theme colors, file size formatters
├── ViewModels/          # MVVM reactive state managers
├── Views/
│   ├── Combine/         # PDF combining and reordering interface
│   ├── Compress/        # Customizable PDF compression UI
│   ├── Components/      # Reusable visual components and progress states
│   ├── Settings/        # Application preferences and defaults
│   └── Sidebar/         # Main macOS window navigation
├── Assets.xcassets/     # Application icons and custom color tokens
└── PDFFusionApp.swift   # Main application lifecycle entry point
```

## License

MIT License — see the [LICENSE](LICENSE) file for full details. Build on top of it, fork it, and enjoy!
