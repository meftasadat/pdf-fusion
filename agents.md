# PDFStitch — AI Agent Context

## Project Overview

**PDFStitch** (branded "PDF Stitch") is a native macOS application for combining and compressing PDF files. It is built with **SwiftUI** and **PDFKit**, targeting **macOS 14.0+ (Sonoma)**. The app is fully offline — all processing happens locally, with zero cloud dependencies.

- **Bundle ID:** `com.pdfstitch.app`
- **Current Version:** 1.1.0 (build 5)
- **License:** MIT
- **Landing Page:** https://meftasadat.github.io/pdf-stitch/
- **Homebrew:** `brew tap meftasadat/tap && brew install --cask pdf-stitch`

> **Naming note:** The project was originally called "PDF Fusion" and was renamed to "PDFStitch" / "PDF Stitch". The Git repository slug is `pdf-stitch` on GitHub, but the local directory is `pdf-combiner`. Always use "PDFStitch" (code identifiers) or "PDF Stitch" (display name) — never "PDF Fusion".

---

## Tech Stack

| Layer           | Technology                              |
| --------------- | --------------------------------------- |
| UI Framework    | SwiftUI (declarative, `@Observable`)    |
| PDF Engine      | PDFKit + CoreGraphics                   |
| Language        | Swift 5.9                               |
| Min Deployment  | macOS 14.0                              |
| IDE / Build     | Xcode 16.0+                             |
| Project Gen     | XcodeGen (`project.yml` → `.xcodeproj`) |
| CI/CD           | GitHub Actions (macOS 15 runner)        |
| Distribution    | DMG via GitHub Releases + Homebrew Cask |

---

## Repository Structure

```
pdf-combiner/                    # Repo root (GitHub slug: pdf-stitch)
├── PDFStitch/                   # All Swift source code
│   ├── PDFStitchApp.swift       # @main app entry — WindowGroup, menu commands
│   ├── ContentView.swift        # Root view (sidebar + detail layout)
│   ├── Models/
│   │   ├── PDFFileItem.swift    # Represents a loaded PDF (url, pageCount, fileSize)
│   │   ├── CompressionSettings.swift  # Continuous 0.0–1.0 compression level → DPI/JPEG quality
│   │   └── AppSettings.swift    # User preferences
│   ├── Services/
│   │   ├── PDFMergerService.swift      # Merges multiple PDFs into one
│   │   ├── PDFCompressorService.swift  # Page-by-page image-based compression
│   │   └── FileValidatorService.swift  # Validates dropped/picked files
│   ├── ViewModels/
│   │   └── PDFViewModel.swift   # Central @Observable VM — all app state + business logic
│   ├── Views/
│   │   ├── Combine/             # PDF merge UI (file list, drag-drop zone, reordering)
│   │   ├── Compress/            # Standalone compression UI (slider, size estimate)
│   │   ├── Components/          # Shared UI atoms (progress bars, states)
│   │   ├── Settings/            # Preferences view
│   │   └── Sidebar/             # macOS sidebar navigation
│   ├── Utilities/
│   │   ├── Color+Theme.swift    # Custom color palette & dark mode tokens
│   │   └── FileSize+Formatter.swift  # Int64 → human-readable file size
│   └── Assets.xcassets/         # App icon + color assets
├── project.yml                  # XcodeGen spec — single source of truth for project config
├── run.sh                       # Quick build-and-launch script (Debug config)
├── build/                       # Local Xcode DerivedData (gitignored)
├── docs/                        # GitHub Pages landing page
│   ├── index.html               # Landing page HTML
│   ├── styles.css               # Landing page styles
│   └── assets/                  # Logo, feature screenshots
├── .github/workflows/
│   └── release.yml              # Tag-triggered CI: build → create DMG → GitHub Release
├── README.md
├── LICENSE                      # MIT
└── .gitignore
```

---

## Architecture

The app follows **MVVM** with a single shared `PDFViewModel`:

- **`PDFViewModel`** (`@Observable`) holds all state: file list, compression settings, processing state, progress, and estimated sizes. Views bind directly to it via SwiftUI's `@Environment`.
- **Services** are stateless and called from the ViewModel:
  - `PDFMergerService.merge(files:progress:)` — sequential page append
  - `PDFCompressorService.compress(inputURL:settings:progress:)` — renders each page to a bitmap, re-encodes as JPEG at the target DPI/quality
  - `PDFCompressorService.estimateSize(for:settings:originalSize:)` — samples a few pages to predict output size without doing a full compress
  - `FileValidatorService.validateBatch(urls:existingFiles:)` — checks file type, readability, duplicates
- **`ProcessingState`** enum (idle / processing / success / error) drives UI overlays and progress indicators.

### Key Design Decisions

1. **XcodeGen over raw `.xcodeproj`** — The Xcode project file is generated from `project.yml`. When making structural changes (adding targets, changing build settings), edit `project.yml` and run `xcodegen generate`.
2. **Ad-hoc code signing** — The app uses `CODE_SIGN_IDENTITY: "-"` (no Apple Developer account required). Users must right-click → Open on first launch.
3. **Continuous compression slider** — Compression uses a single `compressionLevel: Double` (0.0–1.0) that derives DPI (150→36) and JPEG quality (0.60→0.1) linearly. No discrete presets.
4. **Image-based compression** — Each PDF page is rendered to a CGImage then re-encoded as a JPEG-compressed PDF page via CoreGraphics. This is lossy but produces dramatic file size reductions.

---

## Build & Run

### Prerequisites

- macOS 14.0+, Xcode 16.0+
- XcodeGen: `brew install xcodegen`

### Quick Start

```bash
# Generate the Xcode project from project.yml
xcodegen generate

# Build and launch (Debug)
./run.sh

# Or open in Xcode
open PDFStitch.xcodeproj
```

### Release Build (CLI)

```bash
xcodebuild -project PDFStitch.xcodeproj -scheme PDFStitch -configuration Release build
```

---

## CI/CD & Releases

The release pipeline is fully automated via `.github/workflows/release.yml`:

1. Push a Git tag matching `v*` (e.g., `git tag v1.1.0 && git push --tags`)
2. GitHub Actions (macOS 15 runner) installs XcodeGen, generates the project, builds Release, creates a DMG via `create-dmg`, and publishes a GitHub Release with the `.dmg` attached.

### Versioning

Version numbers live in `project.yml`:
- `MARKETING_VERSION` — user-facing version (e.g., `1.1.0`)
- `CURRENT_PROJECT_VERSION` — build number (integer, e.g., `5`)

After updating versions in `project.yml`, regenerate the Xcode project with `xcodegen generate`.

---

## Landing Page

The `docs/` folder contains a static GitHub Pages site (`index.html` + `styles.css`). It is served at `https://meftasadat.github.io/pdf-stitch/`. Update this directly — no build step required.

---

## Common Tasks

| Task | How |
|------|-----|
| Add a new Swift file | Create the file under `PDFStitch/`, then run `xcodegen generate` |
| Change build settings | Edit `project.yml`, then `xcodegen generate` |
| Bump version | Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml` |
| Cut a release | Commit, tag `vX.Y.Z`, push tag — CI handles the rest |
| Update landing page | Edit `docs/index.html` and `docs/styles.css` directly |
| Update Homebrew cask | Maintained in a separate repo: `meftasadat/homebrew-tap` |

---

## Conventions

- **Swift style:** Standard Swift conventions — `UpperCamelCase` for types, `lowerCamelCase` for properties/methods.
- **Async patterns:** Services use `async/await`. Progress callbacks are closure-based `(Double) -> Void`. UI updates are dispatched to `@MainActor`.
- **State management:** Single `@Observable` ViewModel injected into the SwiftUI environment. No Combine publishers.
- **File operations:** Always use security-scoped resource access (`startAccessingSecurityScopedResource` / `stopAccessingSecurityScopedResource`) when handling user-selected URLs.
- **Temp files:** Intermediate merge/compress outputs go to `FileManager.default.temporaryDirectory` and are cleaned up after save.
