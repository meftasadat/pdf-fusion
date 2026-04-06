import SwiftUI

struct FileListView: View {
    @Environment(PDFViewModel.self) private var viewModel

    var body: some View {
        VStack(spacing: 2) {
            // List Header
            HStack {
                Text("FILES TO COMBINE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textTertiary)
                    .tracking(1)

                Spacer()

                Text("\(viewModel.files.count) files")
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            // File rows
            ForEach(Array(viewModel.files.enumerated()), id: \.element.id) { index, file in
                FileRowView(file: file, index: index + 1) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.removeFile(file)
                    }
                }
            }
            .onMove { source, destination in
                viewModel.moveFiles(from: source, to: destination)
            }
        }
    }
}
