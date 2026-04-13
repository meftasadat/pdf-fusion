import SwiftUI
import UniformTypeIdentifiers

struct ConvertView: View {
    @Environment(PDFViewModel.self) private var viewModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Convert to Images")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Export every page as an individual image file")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.convertInputFile == nil {
                        convertDropZone
                    } else {
                        exportControls
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

    private var convertDropZone: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Color.accentGradient)
            }

            VStack(spacing: 4) {
                Text("Drop a PDF File Here")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("or click to select a file to convert")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            Button(action: openConvertFilePicker) {
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
            viewModel.loadFileForConversion(url: url)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    // MARK: - Export Controls

    private var exportControls: some View {
        @Bindable var vm = viewModel

        return VStack(spacing: 20) {
            // File Info Card
            if let file = viewModel.convertInputFile {
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

                    Button(action: { viewModel.resetConvertState() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .glassMorphism(cornerRadius: 12)
            }

            // Export Settings Card
            VStack(spacing: 18) {
                // Format Picker
                VStack(spacing: 10) {
                    HStack {
                        Text("IMAGE FORMAT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textTertiary)
                            .tracking(1)

                        Spacer()
                    }

                    HStack(spacing: 0) {
                        ForEach(ImageExportFormat.allCases) { format in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    vm.imageExportSettings.format = format
                                    if !viewModel.convertOutputURLs.isEmpty {
                                        viewModel.convertOutputURLs = []
                                        viewModel.convertTotalSize = 0
                                        viewModel.processingState = .idle
                                    }
                                    viewModel.updateConvertEstimate()
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Text(format.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(format.description)
                                        .font(.system(size: 10))
                                        .foregroundColor(viewModel.imageExportSettings.format == format ? .white.opacity(0.7) : .textTertiary)
                                }
                                .foregroundColor(viewModel.imageExportSettings.format == format ? .white : .textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.imageExportSettings.format == format
                                              ? AnyShapeStyle(Color.accentGradient)
                                              : AnyShapeStyle(Color.white.opacity(0.05)))
                                )
                            }
                            .buttonStyle(.plain)

                            if format != ImageExportFormat.allCases.last {
                                Spacer().frame(width: 8)
                            }
                        }
                    }
                }

                Divider()
                    .background(Color.borderDefault)

                // DPI Slider
                VStack(spacing: 10) {
                    HStack {
                        Text("RESOLUTION (DPI)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textTertiary)
                            .tracking(1)

                        Spacer()

                        // Quality badge
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.imageExportSettings.qualityIcon)
                                .font(.system(size: 10))
                            Text(viewModel.imageExportSettings.qualityLabel)
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

                    // DPI value display
                    Text("\(viewModel.imageExportSettings.dpiInt) DPI")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(dpiGradient)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: viewModel.imageExportSettings.dpiInt)

                    // DPI slider
                    VStack(spacing: 8) {
                        DPISlider(
                            value: $vm.imageExportSettings.dpi,
                            range: ImageExportSettings.minDPI...ImageExportSettings.maxDPI
                        ) {
                            if !viewModel.convertOutputURLs.isEmpty {
                                viewModel.convertOutputURLs = []
                                viewModel.convertTotalSize = 0
                                viewModel.processingState = .idle
                            }
                            viewModel.updateConvertEstimate()
                        }

                        HStack {
                            Text("72 DPI")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textTertiary)

                            Spacer()

                            Text("600 DPI")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }

                // JPEG Quality (only for JPEG format)
                if viewModel.imageExportSettings.format == .jpeg {
                    Divider()
                        .background(Color.borderDefault)

                    VStack(spacing: 10) {
                        HStack {
                            Text("JPEG QUALITY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.textTertiary)
                                .tracking(1)

                            Spacer()

                            Text("\(Int(viewModel.imageExportSettings.jpegQuality * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentBlue)
                        }

                        Slider(value: $vm.imageExportSettings.jpegQuality, in: 0.1...1.0, step: 0.05) {
                            Text("Quality")
                        }
                        .tint(Color.accentBlue)
                        .onChange(of: viewModel.imageExportSettings.jpegQuality) {
                            if !viewModel.convertOutputURLs.isEmpty {
                                viewModel.convertOutputURLs = []
                                viewModel.convertTotalSize = 0
                                viewModel.processingState = .idle
                            }
                            viewModel.updateConvertEstimate()
                        }

                        HStack {
                            Text("Smaller File")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textTertiary)

                            Spacer()

                            Text("Best Quality")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }

                Divider()
                    .background(Color.borderDefault)

                // Estimated output
                HStack {
                    if let file = viewModel.convertInputFile {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 11))
                                .foregroundColor(.textTertiary)
                            Text("\(file.pageCount) images")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        if viewModel.isEstimatingConvert {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.statusSuccess)
                        }
                        Text("Est: ~\(viewModel.convertEstimatedSize.formattedFileSize) total")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.statusSuccess)
                    }
                }

                // Per-page estimate
                if let file = viewModel.convertInputFile, file.pageCount > 0, viewModel.convertEstimatedSize > 0 {
                    let perPage = viewModel.convertEstimatedSize / Int64(file.pageCount)
                    HStack(spacing: 4) {
                        Text("~\(perPage.formattedFileSize) per image")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.textTertiary)

                        Text("·")
                            .foregroundColor(.textTertiary)

                        Text("\(viewModel.imageExportSettings.format.rawValue.uppercased())")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textTertiary)

                        Text("·")
                            .foregroundColor(.textTertiary)

                        Text("\(viewModel.imageExportSettings.dpiInt) DPI")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            .padding(20)
            .glassMorphism(cornerRadius: 14)

            // Result card
            if !viewModel.convertOutputURLs.isEmpty {
                resultCard
            }

            // Convert button
            if viewModel.convertInputFile != nil && viewModel.convertOutputURLs.isEmpty {
                Button(action: {
                    Task { await viewModel.performImageExport() }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 14))
                        Text("Convert to \(viewModel.imageExportSettings.format.rawValue) Images")
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

    private var resultCard: some View {
        VStack(spacing: 14) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.statusSuccess.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.statusSuccess)
            }

            VStack(spacing: 4) {
                Text("Export Complete!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("\(viewModel.convertOutputURLs.count) images · \(viewModel.convertTotalSize.formattedFileSize)")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }

            if case .success(_, let outputURL) = viewModel.processingState {
                Button(action: {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: outputURL.path)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Reveal in Finder")
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

            Button(action: { viewModel.resetConvertState() }) {
                Text("Convert Another PDF")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentPurple)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .glassMorphism(cornerRadius: 14)
    }

    // MARK: - Gradient

    private var dpiGradient: LinearGradient {
        let normalized = (viewModel.imageExportSettings.dpi - ImageExportSettings.minDPI) / (ImageExportSettings.maxDPI - ImageExportSettings.minDPI)
        let color1: Color = normalized < 0.5 ? .accentBlue : .accentPurple
        let color2: Color = normalized < 0.5 ? .statusSuccess : .accentBlue
        return LinearGradient(colors: [color1, color2], startPoint: .leading, endPoint: .trailing)
    }

    // MARK: - File Picker

    private func openConvertFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.title = "Select PDF to Convert"

        if panel.runModal() == .OK, let url = panel.url {
            viewModel.loadFileForConversion(url: url)
        }
    }
}

// MARK: - Custom DPI Slider

struct DPISlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onChange: () -> Void

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let trackWidth = geo.size.width
            let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbX = normalizedValue * trackWidth

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
                                Color(hex: "0984e3"),
                                Color(hex: "6c5ce7"),
                                Color(hex: "a29bfe"),
                                Color(hex: "fd79a8")
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
                            .stroke(Color.accentBlue.opacity(0.3), lineWidth: 2)
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
                        let normalized = min(max(drag.location.x / trackWidth, 0), 1)
                        let rawValue = range.lowerBound + normalized * (range.upperBound - range.lowerBound)
                        // Snap to nearest 6 DPI for cleaner values
                        value = (rawValue / 6.0).rounded() * 6.0
                        value = min(max(value, range.lowerBound), range.upperBound)
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
