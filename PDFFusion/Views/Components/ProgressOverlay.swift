import SwiftUI

struct ProgressOverlay: View {
    @Environment(PDFViewModel.self) private var viewModel

    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Progress card
            VStack(spacing: 24) {
                // Animated progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 80, height: 80)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            Color.accentGradient,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)

                    // Percentage text
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }

                // Status message
                if case .processing(let message) = viewModel.processingState {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentGradient)
                            .frame(width: geo.size.width * viewModel.progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                    }
                }
                .frame(height: 6)
                .frame(maxWidth: 200)
            }
            .padding(40)
            .frame(width: 300)
            .glassMorphism(cornerRadius: 20)
        }
        .interactiveDismissDisabled()
    }
}
