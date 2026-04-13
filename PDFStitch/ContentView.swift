import SwiftUI

struct ContentView: View {
    @Environment(PDFViewModel.self) private var viewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                switch viewModel.selectedTab {
                case .combine:
                    CombineView()
                case .compress:
                    CompressView()
                case .convert:
                    ConvertView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .background(Color.appBackground)
        .frame(minWidth: 750, minHeight: 550)
    }
}
