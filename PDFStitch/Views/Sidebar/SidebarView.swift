import SwiftUI

struct SidebarView: View {
    @Environment(PDFViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            // App Header
            VStack(spacing: 8) {
                Image(systemName: "doc.on.doc.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.accentGradient)

                Text("PDF Stitch")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    SidebarButton(
                        tab: tab,
                        isSelected: viewModel.selectedTab == tab
                    ) {
                        vm.selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Buy me a coffee
            Link(destination: URL(string: "https://buymeacoffee.com/meftasadat")!) {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(Color(red: 1.0, green: 0.86, blue: 0.0))
                    Text("Buy me a coffee")
                        .foregroundColor(.white)
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)

            // Version info
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            Text("v\(appVersion)")
                .font(.system(size: 11))
                .foregroundColor(.textTertiary)
                .padding(.bottom, 16)
        }
        .background(
            Color.appBackground.opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(Color.borderDefault)
                        .frame(width: 1),
                    alignment: .trailing
                )
        )
    }
}

// MARK: - Sidebar Button

struct SidebarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundColor(isSelected ? .white : .textSecondary)

                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .textSecondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(Color.accentGradient)
                            : AnyShapeStyle(isHovered ? Color.white.opacity(0.05) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
