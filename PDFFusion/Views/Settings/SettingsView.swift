import SwiftUI

struct SettingsView: View {
    @Environment(PDFViewModel.self) private var viewModel

    @AppStorage("defaultCompressionLevel") private var defaultCompressionLevel = 10
    @AppStorage("showThumbnails") private var showThumbnails = true
    @AppStorage("autoOpenAfterSave") private var autoOpenAfterSave = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Configure app preferences")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    // Compression Settings
                    settingsSection(title: "COMPRESSION") {
                        VStack(spacing: 12) {
                            settingsRow(
                                icon: "arrow.down.doc",
                                title: "Default Level",
                                subtitle: "Applied when compression is enabled"
                            ) {
                                HStack(spacing: 8) {
                                    Slider(value: Binding(
                                        get: { Double(defaultCompressionLevel) / 100.0 },
                                        set: { defaultCompressionLevel = Int($0 * 100) }
                                    ), in: 0...1, step: 0.05)
                                        .frame(width: 120)
                                        .tint(.accentPurple)
                                    Text("\(defaultCompressionLevel)%")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentPurple)
                                        .frame(width: 36)
                                }
                            }
                        }
                    }

                    // Display Settings
                    settingsSection(title: "DISPLAY") {
                        VStack(spacing: 0) {
                            settingsRow(
                                icon: "photo",
                                title: "Show Thumbnails",
                                subtitle: "Display PDF page thumbnails in the file list"
                            ) {
                                Toggle("", isOn: $showThumbnails)
                                    .toggleStyle(.switch)
                            }

                            Divider()
                                .background(Color.borderDefault)
                                .padding(.horizontal, -16)

                            settingsRow(
                                icon: "folder",
                                title: "Open After Save",
                                subtitle: "Reveal the file in Finder after saving"
                            ) {
                                Toggle("", isOn: $autoOpenAfterSave)
                                    .toggleStyle(.switch)
                            }
                        }
                    }

                    // About Section
                    settingsSection(title: "ABOUT") {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.on.doc.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color.accentGradient)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PDF Fusion")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)

                                    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                                    Text("Version \(appVersion)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textSecondary)
                                }

                                Spacer()
                            }

                            Text("A native macOS app for combining and compressing PDF files. Built with SwiftUI and PDFKit.")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Keyboard Shortcuts
                    settingsSection(title: "KEYBOARD SHORTCUTS") {
                        VStack(spacing: 8) {
                            shortcutRow("Add Files", shortcut: "⌘O")
                            shortcutRow("Combine PDFs", shortcut: "⇧⌘E")
                            shortcutRow("Clear All", shortcut: "⌘⌫")
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Reusable Components

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textTertiary)
                .tracking(1)

            VStack {
                content()
            }
            .padding(16)
            .glassMorphism(cornerRadius: 12)
        }
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentPurple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            trailing()
        }
        .padding(.vertical, 4)
    }

    private func shortcutRow(_ action: String, shortcut: String) -> some View {
        HStack {
            Text(action)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)

            Spacer()

            Text(shortcut)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.borderDefault, lineWidth: 1)
                        )
                )
        }
    }
}
