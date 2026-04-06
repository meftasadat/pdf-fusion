import SwiftUI

struct ActionBar: View {
    @Environment(PDFViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        HStack(spacing: 16) {
            // File summary
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.filesSummary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)

                if viewModel.compressionSettings.isEnabled {
                    Text("Compression: \(viewModel.compressionSettings.compressionPercent)%")
                        .font(.system(size: 11))
                        .foregroundColor(.accentPurple)
                }
            }

            Spacer()

            // Compression Toggle
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.compressionSettings.isEnabled ? .accentPurple : .textTertiary)

                Text("Compress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.compressionSettings.isEnabled ? .textPrimary : .textSecondary)

                Toggle("", isOn: $vm.compressionSettings.isEnabled)
                    .toggleStyle(.switch)
                    .scaleEffect(0.7)
                    .frame(width: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )
            )

            // Compression Level Slider (shown when compression enabled)
            if viewModel.compressionSettings.isEnabled {
                HStack(spacing: 8) {
                    Text("\(viewModel.compressionSettings.compressionPercent)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentPurple)
                        .frame(width: 32)

                    Slider(value: $vm.compressionSettings.compressionLevel, in: 0...1, step: 0.05)
                        .frame(width: 120)
                        .tint(.accentPurple)
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Combine Button
            Button(action: {
                Task { await viewModel.combineFiles() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 12))
                    Text("Combine PDFs")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            viewModel.canCombine
                                ? AnyShapeStyle(Color.accentGradient)
                                : AnyShapeStyle(Color.gray.opacity(0.3))
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canCombine)
            .onHover { hovering in
                if hovering && viewModel.canCombine {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(Color.appBackground)
                .overlay(
                    Rectangle()
                        .fill(Color.borderDefault)
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.compressionSettings.isEnabled)
    }
}
