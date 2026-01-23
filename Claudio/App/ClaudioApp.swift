import SwiftUI

@main
struct ClaudioApp: App {
    @State private var viewModel = ClaudioViewModel()
    @Environment(\.openWindow) private var openWindow

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

        // Settings window - using Window for better control
        Settings {
            SettingsView()
                .onAppear {
                    // Bring settings window to front when it appears
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        for window in NSApplication.shared.windows {
                            if window.title.contains("Settings") || window.identifier?.rawValue.contains("settings") == true {
                                window.level = .floating
                                window.makeKeyAndOrderFront(nil)
                            }
                        }
                    }
                }
        }
    }
}
