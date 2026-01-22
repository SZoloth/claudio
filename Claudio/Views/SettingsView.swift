import SwiftUI
import ServiceManagement

/// Settings view for Claudio preferences
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // Settings state
    @State private var settings = AppSettings()
    @State private var apiKeyInput = ""
    @State private var apiKeySaved = false
    @State private var ollamaModelInput = ""

    var body: some View {
        Form {
            // T-011: Mode section
            modeSection

            // T-007: Provider section
            providerSection

            // T-008: API Key section
            apiKeySection

            // T-009: Model section
            modelSection

            // T-010: Behavior section
            behaviorSection

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
                    PathRow(label: "Hook Config", path: SettingsWriter.configPath)
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
        .frame(width: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Load current state
            apiKeySaved = KeychainService.hasAPIKey(for: settings.provider.rawValue)
            ollamaModelInput = settings.ollamaModel
        }
        .onDisappear {
            // Write config when settings close
            SettingsWriter.writeHookConfig(settings: settings)
        }
    }

    // MARK: - Mode Section (T-011)

    private var modeSection: some View {
        Section("Mode") {
            Picker("Operating Mode", selection: $settings.transcribeOnlyMode) {
                Text("Conversation").tag(false)
                Text("Transcribe Only").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: settings.transcribeOnlyMode) { _, _ in
                writeConfigAsync()
            }

            if settings.transcribeOnlyMode {
                Text("Transcribe speech, clean up with AI, copy to clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Provider Section (T-007)

    private var providerSection: some View {
        Section("LLM Provider") {
            Picker("Provider", selection: $settings.provider) {
                ForEach(LLMProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .onChange(of: settings.provider) { _, newProvider in
                // Update API key saved status for new provider
                apiKeySaved = KeychainService.hasAPIKey(for: newProvider.rawValue)
                apiKeyInput = ""
                writeConfigAsync()
            }
        }
    }

    // MARK: - API Key Section (T-008)

    private var apiKeySection: some View {
        Section("API Key") {
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key for \(settings.provider.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    SecureField("Enter API key...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    if apiKeySaved && apiKeyInput.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .help("API key saved")
                    }

                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKeyInput.isEmpty)
                }

                if settings.provider == .claude {
                    Text("Claude uses the CLI authentication. API key is optional.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Model Section (T-009)

    private var modelSection: some View {
        Section("Model") {
            if settings.provider == .ollama {
                // Ollama: text field for custom model
                HStack {
                    TextField("Model name", text: $ollamaModelInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            settings.ollamaModel = ollamaModelInput
                            writeConfigAsync()
                        }

                    Button("Set") {
                        settings.ollamaModel = ollamaModelInput
                        writeConfigAsync()
                    }
                }

                Text("Enter the Ollama model name (e.g., llama3, mistral, codellama)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Claude/OpenAI: picker from predefined models
                Picker("Model", selection: $settings.model) {
                    ForEach(settings.provider.models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: settings.model) { _, _ in
                    writeConfigAsync()
                }
            }
        }
    }

    // MARK: - Behavior Section (T-010)

    private var behaviorSection: some View {
        Section("Behavior") {
            Toggle("Copy response to clipboard", isOn: $settings.copyToClipboard)
                .onChange(of: settings.copyToClipboard) { _, _ in
                    writeConfigAsync()
                }

            Toggle("Speak response aloud", isOn: $settings.speakResponse)
                .onChange(of: settings.speakResponse) { _, _ in
                    writeConfigAsync()
                }
        }
    }

    // MARK: - Actions

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

    private func saveAPIKey() {
        KeychainService.saveAPIKey(apiKeyInput, for: settings.provider.rawValue)
        apiKeySaved = true
        apiKeyInput = ""
        writeConfigAsync()
    }

    private func writeConfigAsync() {
        // Write config in background
        Task {
            SettingsWriter.writeHookConfig(settings: settings)
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
