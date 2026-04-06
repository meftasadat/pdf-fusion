import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Environment(PDFViewModel.self) private var viewModel
    @State private var isTargeted = false
    @State private var isHovered = false

    var body: some View {
        let isEmpty = viewModel.files.isEmpty

        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.accentGradient)
                    .symbolEffect(.pulse, options: .repeating, value: isTargeted)
            }
            .scaleEffect(isTargeted ? 1.1 : 1.0)

            VStack(spacing: 4) {
                Text(isTargeted ? "Release to Add" : "Drop PDF Files Here")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("or click 'Add Files' to browse")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }

            // Add Files Button
            Button(action: openFilePicker) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add Files")
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
            .onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isEmpty ? 220 : 140)
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
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .dropDestination(for: URL.self) { urls, _ in
            let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
            guard !pdfURLs.isEmpty else { return false }
            viewModel.addFiles(urls: pdfURLs)
            return true
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf]
        panel.title = "Select PDF Files"
        panel.message = "Choose one or more PDF files to combine"

        if panel.runModal() == .OK {
            viewModel.addFiles(urls: panel.urls)
        }
    }
}
