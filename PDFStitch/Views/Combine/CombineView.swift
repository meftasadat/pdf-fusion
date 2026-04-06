import SwiftUI

struct CombineView: View {
    @Environment(PDFViewModel.self) private var viewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Combine PDFs")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)

                        Text("Drag & drop PDF files or click to add")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    if !viewModel.files.isEmpty {
                        Button(action: { viewModel.clearAll() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                Text("Clear All")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.statusError)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.statusError.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Validation Errors
                if !viewModel.validationErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.validationErrors, id: \.self) { error in
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.statusWarning)
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(.statusWarning)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content
                VStack(spacing: 16) {
                    // Drop Zone
                    DropZoneView()

                    // File List
                    if !viewModel.files.isEmpty {
                        FileListView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Action Bar
                if !viewModel.files.isEmpty {
                    ActionBar()
                }

                // Success / Error banner
                if case .success(let message, _) = viewModel.processingState {
                    ResultBanner(message: message, isSuccess: true) {
                        viewModel.dismissResult()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if case .error(let message) = viewModel.processingState {
                    ResultBanner(message: message, isSuccess: false) {
                        viewModel.dismissResult()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.files.count)
            .animation(.easeInOut(duration: 0.2), value: viewModel.validationErrors)

            // Processing Overlay
            if viewModel.processingState.isProcessing {
                ProgressOverlay()
            }
        }
    }
}

// MARK: - Result Banner

struct ResultBanner: View {
    let message: String
    let isSuccess: Bool
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isSuccess ? .statusSuccess : .statusError)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textPrimary)
                .lineLimit(1)

            Spacer()

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(isSuccess ? Color.statusSuccess.opacity(0.1) : Color.statusError.opacity(0.1))
                .overlay(
                    Rectangle()
                        .fill(isSuccess ? Color.statusSuccess : Color.statusError)
                        .frame(height: 2),
                    alignment: .top
                )
        )
    }
}
