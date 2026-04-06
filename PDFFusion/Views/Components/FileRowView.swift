import SwiftUI

struct FileRowView: View {
    let file: PDFFileItem
    let index: Int
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Index / Drag handle
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.textTertiary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.05))
                )

            // Thumbnail
            Group {
                if let thumbnail = file.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentPurple)
                }
            }
            .frame(width: 36, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Label("\(file.pageCount) pages", systemImage: "doc.text")
                    Label(file.fileSize.formattedFileSize, systemImage: "internaldrive")
                }
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
            }

            Spacer()

            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(.textTertiary)
                .opacity(isHovered ? 1 : 0.3)

            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textTertiary)
                    .opacity(isHovered ? 1 : 0)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassMorphism(cornerRadius: 10)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
