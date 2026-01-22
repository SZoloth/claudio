import SwiftUI

@main
struct ClaudioApp: App {
    @State private var viewModel = ClaudioViewModel()

    var body: some Scene {
        // Menu bar popover
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            MenuBarLabel(
                status: viewModel.daemonInfo.status,
                isProcessing: viewModel.isProcessing
            )
        }
        .menuBarExtraStyle(.window)

        // Full history window (opened via button or keyboard shortcut)
        Window("Conversation History", id: "history") {
            ConversationHistoryView(viewModel: viewModel)
        }
        .keyboardShortcut("h", modifiers: [.command, .shift])
        .defaultSize(width: 600, height: 500)

        // Settings window
        Settings {
            SettingsView()
        }
    }
}
