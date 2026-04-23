---
name: release
description: How to cut a new PDFStitch release (bump version, tag, push, update downstream)
---

# PDFStitch Release Skill

Step-by-step procedure for publishing a new version of PDF Stitch.

## Prerequisites

- All features for the release are merged to `main`
- XcodeGen is installed (`brew install xcodegen`)
- You have push access to `meftasadat/pdf-stitch`

## Steps

### 1. Bump Version in `project.yml`

Edit `project.yml` and update both version fields under `targets > PDFStitch > settings > base`:

```yaml
CURRENT_PROJECT_VERSION: <new_build_number>   # integer, increment by 1
MARKETING_VERSION: <X.Y.Z>                     # semver, e.g. 1.3.0
```

### 2. Regenerate Xcode Project

// turbo
```bash
xcodegen generate
```

This updates `PDFStitch.xcodeproj/project.pbxproj` to reflect the new version.

### 3. Update Download Links

Update the version in **all** download URLs across these files:

#### `docs/index.html`
Find all URLs matching `releases/download/vOLD/PDFStitch-vOLD.dmg` and replace `vOLD` with `vNEW`:
- Nav bar download button (line ~33)
- Hero section download button (line ~48)

#### `README.md`
Update the download badge URL and label (lines ~13-14):
```
releases/download/vX.Y.Z/PDFStitch-vX.Y.Z.dmg
Download_for_Mac-vX.Y.Z
```

### 4. Verify Build Locally (Optional)

```bash
./run.sh
```

Confirm the app launches and the About/sidebar shows the new version string.

### 5. Commit

```bash
git add -A
git commit -m "Release vX.Y.Z - <Brief Description>

- Feature 1
- Feature 2
- Bug fix, etc."
```

### 6. Tag

```bash
git tag vX.Y.Z
```

### 7. Push

```bash
git push origin main --tags
```

This triggers the **GitHub Actions CI pipeline** (`.github/workflows/release.yml`) which:
1. Installs XcodeGen on a macOS 15 runner
2. Generates the Xcode project
3. Builds a Release configuration
4. Creates a DMG via `create-dmg`
5. Publishes a GitHub Release with the DMG attached and auto-generated release notes

### 8. Verify CI

Check the [Actions tab](https://github.com/meftasadat/pdf-stitch/actions) to confirm the pipeline completes successfully and the release appears on the [Releases page](https://github.com/meftasadat/pdf-stitch/releases).

### 9. Update Homebrew Cask (Post-Release)

After the DMG is published on GitHub Releases:

1. Download the DMG from the release page
2. Get its SHA-256: `shasum -a 256 PDFStitch-vX.Y.Z.dmg`
3. Update `Casks/pdf-stitch.rb` in the `meftasadat/homebrew-tap` repo:
   - `version` → new version string
   - `sha256` → new checksum
   - `url` → new DMG URL
4. Commit and push the cask update

## Version History

| Version | Build | Tag    | Key Changes |
|---------|-------|--------|-------------|
| 1.0.0   | 1     | v1.0.0 | Initial release — PDF Fusion |
| 1.0.1   | 2     | v1.0.1 | CI fix: macOS 15 runner |
| 1.0.2   | 3     | v1.0.2 | Swift compilation fixes |
| 1.0.3   | 4     | v1.0.3 | Default compression settings |
| 1.0.4   | 4     | v1.0.4 | Landing page, dynamic versions, reorder fix, new logo |
| 1.1.0   | 5     | v1.1.0 | Rebrand to PDF Stitch |
| 1.2.0   | 6     | v1.2.0 | PDF to Image conversion |
