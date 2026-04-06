import SwiftUI

@main
struct PDFFusionApp: App {
    @State private var viewModel = PDFViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 680)
        .commands {
            // File menu commands
            CommandGroup(after: .newItem) {
                Button("Add PDF Files...") {
                    openFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)

                Divider()

                Button("Combine PDFs") {
                    Task { await viewModel.combineFiles() }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!viewModel.canCombine)

                Button("Clear All") {
                    viewModel.clearAll()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(viewModel.files.isEmpty)
            }
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
