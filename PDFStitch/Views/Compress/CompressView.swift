import SwiftUI
import UniformTypeIdentifiers

struct CompressView: View {
    @Environment(PDFViewModel.self) private var viewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Compress PDF")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Reduce the file size of a PDF document")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.compressInputFile == nil {
                        compressDropZone
                    } else {
                        compressionControls
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // Processing overlay
            if viewModel.processingState.isProcessing {
                ProgressOverlay()
            }
        }
    }

    // MARK: - Drop Zone

    private var compressDropZone: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.accentGradient)
            }

            VStack(spacing: 4) {
                Text("Drop a PDF File Here")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("or click to select a file")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            Button(action: openCompressFilePicker) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 12, weight: .bold))
                    Text("Select File")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentGradient)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isTargeted ? Color.dropZoneActiveBackground : Color.dropZoneBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isTargeted ? Color.dropZoneActiveBorder : Color.dropZoneBorder,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                )
        )
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first(where: { $0.pathExtension.lowercased() == "pdf" }) else { return false }
            viewModel.loadFileForCompression(url: url)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    // MARK: - Compression Controls

    private var compressionControls: some View {
        @Bindable var vm = viewModel

        return VStack(spacing: 20) {
            // File Info Card
            if let file = viewModel.compressInputFile {
                HStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentGradient)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.fileName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)

                        HStack(spacing: 12) {
                            Label("\(file.pageCount) pages", systemImage: "doc.text")
                            Label(file.fileSize.formattedFileSize, systemImage: "internaldrive")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    Button(action: { viewModel.resetCompressState() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .glassMorphism(cornerRadius: 12)
            }

            // Compression Slider Card
            VStack(spacing: 18) {
                // Header
                HStack {
                    Text("COMPRESSION LEVEL")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textTertiary)
                        .tracking(1)

                    Spacer()

                    // Quality badge
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.compressionSettings.qualityIcon)
                            .font(.system(size: 10))
                        Text(viewModel.compressionSettings.qualityLabel)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.accentPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.accentPurple.opacity(0.12))
                    )
                }

                // Percentage display
                Text("\(viewModel.compressionSettings.compressionPercent)%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(compressionGradient)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: viewModel.compressionSettings.compressionPercent)

                // Slider
                VStack(spacing: 8) {
                    CompressionSlider(value: $vm.compressionSettings.compressionLevel) {
                        // Debounce: update estimate when slider changes
                        if viewModel.compressOutputURL != nil {
                            viewModel.clearCompressResult()
                        }
                        viewModel.updateEstimate()
                    }

                    // Labels
                    HStack {
                        Text("Best Quality")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textTertiary)

                        Spacer()

                        Text("Smallest File")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.textTertiary)
                    }
                }

                // Estimated size
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textTertiary)
                        Text("Original: \(viewModel.compressOriginalSize.formattedFileSize)")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        if viewModel.isEstimating {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.statusSuccess)
                        }
                        Text("Est: ~\(viewModel.compressEstimatedSize.formattedFileSize)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.statusSuccess)
                    }
                }

                // DPI & Quality info
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("DPI:")
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                        Text("\(Int(viewModel.compressionSettings.targetDPI))")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    }

                    HStack(spacing: 4) {
                        Text("JPEG:")
                            .font(.system(size: 10))
                            .foregroundColor(.textTertiary)
                        Text("\(Int(viewModel.compressionSettings.imageQuality * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(20)
            .glassMorphism(cornerRadius: 14)

            // Result card
            if let outputURL = viewModel.compressOutputURL {
                resultCard(outputURL: outputURL)
            }

            // Compress button
            if viewModel.compressInputFile != nil && viewModel.compressOutputURL == nil {
                Button(action: {
                    Task { await viewModel.performCompression() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 14))
                        Text("Compress at \(viewModel.compressionSettings.compressionPercent)%")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentGradient)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
    }

    // MARK: - Result Card

    private func resultCard(outputURL: URL) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textTertiary)
                    Text(viewModel.compressOriginalSize.formattedFileSize)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.textTertiary)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Compressed")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textTertiary)
                    Text(viewModel.compressResultSize.formattedFileSize)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.statusSuccess)
                }
            }

            let savings = viewModel.compressOriginalSize > 0
                ? Int(100 - (Double(viewModel.compressResultSize) / Double(viewModel.compressOriginalSize) * 100))
                : 0

            Text("Saved \(savings)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.statusSuccess)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.statusSuccess.opacity(0.15))
                )

            Button(action: {
                Task { await viewModel.promptSaveDialog(tempURL: outputURL) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Compressed PDF")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentGradient)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .glassMorphism(cornerRadius: 14)
    }

    // MARK: - Gradient

    private var compressionGradient: LinearGradient {
        let level = viewModel.compressionSettings.compressionLevel
        let color1: Color = level < 0.5
            ? .statusSuccess
            : .accentPurple
        let color2: Color = level < 0.5
            ? .accentBlue
            : .statusError
        return LinearGradient(colors: [color1, color2], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - File Picker

    private func openCompressFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.title = "Select PDF to Compress"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.loadFileForCompression(url: url)
        }
    }
}

// MARK: - Custom Compression Slider

struct CompressionSlider: View {
    @Binding var value: Double
    var onChange: () -> Void

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let thumbX = value * trackWidth

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 10)

                // Filled track with gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "00b894"),
                                Color(hex: "0984e3"),
                                Color(hex: "6c5ce7"),
                                Color(hex: "e17055")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, thumbX), height: 10)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 22 : 18, height: isDragging ? 22 : 18)
                    .shadow(color: Color.accentPurple.opacity(0.4), radius: isDragging ? 8 : 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.accentPurple.opacity(0.3), lineWidth: 2)
                    )
                    .offset(x: thumbX - (isDragging ? 11 : 9))
                    .animation(.easeInOut(duration: 0.15), value: isDragging)
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        isDragging = true
                        let newValue = min(max(drag.location.x / trackWidth, 0), 1)
                        // Snap to 5% increments for easier control
                        value = (newValue * 20).rounded() / 20
                    }
                    .onEnded { _ in
                        isDragging = false
                        onChange()
                    }
            )
        }
        .frame(height: 24)
    }
}
