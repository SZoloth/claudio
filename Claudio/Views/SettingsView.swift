import SwiftUI
import ServiceManagement

/// Settings view for Claudio preferences
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }

                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
            }

            Section("Log Paths") {
                VStack(alignment: .leading, spacing: 8) {
                    PathRow(label: "Transcripts", path: Constants.transcriptsLogPath.path)
                    PathRow(label: "Daemon Log", path: Constants.brabbleLogPath.path)
                    PathRow(label: "Hook Log", path: Constants.claudeHookLogPath.path)
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com/snarktank/brabble")!) {
                    Label("brabble Documentation", systemImage: "book")
                }

                Link(destination: URL(string: "https://github.com/snarktank/claudio")!) {
                    Label("Claudio on GitHub", systemImage: "link")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)"
            showingError = true
            // Revert the toggle
            launchAtLogin = !enabled
        }
    }
}

struct PathRow: View {
    let label: String
    let path: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
            Spacer()
            Text(path)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Button(action: { copyToClipboard(path) }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .help("Copy path")
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#Preview {
    SettingsView()
}
