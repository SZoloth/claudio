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

            // SC-002: Screen Context section
            screenContextSection

            // AG-002: Agentic Mode section
            agenticModeSection

            // WC-003: Wake Commands section
            wakeCommandsSection

            // MCP-002: MCP Servers section
            mcpServersSection

            // T-007: Provider section
            providerSection

            // T-008: API Key section
            apiKeySection

            // T-009: Model section
            modelSection

            // T-010: Behavior section
            behaviorSection

            Section {
                Toggle(isOn: $launchAtLogin) {
                    Label("Launch at login", systemImage: "power")
                }
                .onChange(of: launchAtLogin) { _, newValue in
                    setLaunchAtLogin(newValue)
                }
                .toggleStyle(.switch)
            } header: {
                Label("General", systemImage: "gear")
            }

            Section {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundStyle(.blue)
                }

                LabeledContent("Build") {
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("About", systemImage: "info.circle")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    PathRow(label: "Transcripts", path: Constants.transcriptsLogPath.path)
                    PathRow(label: "Daemon Log", path: Constants.brabbleLogPath.path)
                    PathRow(label: "Hook Log", path: Constants.claudeHookLogPath.path)
                    PathRow(label: "Hook Config", path: SettingsWriter.configPath)
                }
            } header: {
                Label("Log Paths", systemImage: "folder")
            }

            Section {
                Link(destination: URL(string: "https://github.com/snarktank/brabble")!) {
                    Label("brabble Documentation", systemImage: "book")
                }

                Link(destination: URL(string: "https://github.com/snarktank/claudio")!) {
                    Label("Claudio on GitHub", systemImage: "link")
                }
            } header: {
                Label("Resources", systemImage: "link.circle")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, idealWidth: 450, minHeight: 500)
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
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Operating Mode", selection: $settings.transcribeOnlyMode) {
                    Label("Conversation", systemImage: "bubble.left.and.bubble.right.fill")
                        .tag(false)
                    Label("Transcribe Only", systemImage: "mic.fill")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.transcribeOnlyMode) { _, _ in
                    writeConfigAsync()
                }

                // Mode status indicator with color
                HStack(spacing: 8) {
                    Circle()
                        .fill(settings.transcribeOnlyMode ? Color.orange : Color.blue)
                        .frame(width: 8, height: 8)

                    Text(settings.transcribeOnlyMode ? "Transcribe Mode Active" : "Conversation Mode Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(settings.transcribeOnlyMode ? Color.orange : Color.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(settings.transcribeOnlyMode ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                )

                if settings.transcribeOnlyMode {
                    Text("Transcribe speech, clean up with AI, copy to clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Mode", systemImage: "switch.2")
        }
    }

    // MARK: - Screen Context Section (SC-002)

    private var screenContextSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Screen Context", selection: $settings.screenContextMode) {
                    ForEach(ScreenContextMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.screenContextMode) { _, _ in
                    writeConfigAsync()
                }

                // Mode description
                HStack(spacing: 8) {
                    Image(systemName: settings.screenContextMode == .off ? "camera.slash" : "camera.fill")
                        .foregroundStyle(settings.screenContextMode == .off ? Color.secondary : Color.blue)

                    Text(settings.screenContextMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if settings.screenContextMode == .onDemand {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trigger phrases:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\"look at\", \"see this\", \"what's this\", \"this error\", \"on screen\", \"showing\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
        } header: {
            Label("Screen Context", systemImage: "camera.viewfinder")
        }
    }

    // MARK: - Agentic Mode Section (AG-002)

    private var agenticModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settings.agenticMode) {
                    Label("Enable Agentic Mode", systemImage: "cpu.fill")
                }
                .toggleStyle(.switch)
                .tint(.purple)
                .onChange(of: settings.agenticMode) { _, _ in
                    writeConfigAsync()
                }

                // Mode status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(settings.agenticMode ? Color.purple : Color.secondary)
                        .frame(width: 8, height: 8)

                    Text(settings.agenticMode ? "Agentic Mode Active" : "Prompt-Only Mode")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(settings.agenticMode ? Color.purple : Color.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(settings.agenticMode ? Color.purple.opacity(0.15) : Color.gray.opacity(0.1))
                )

                // Warning when enabled
                if settings.agenticMode {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tool Access Enabled")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Claude can execute tools and take actions on your system. Use with caution.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    Text("When disabled, Claude only responds to prompts without taking actions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Agentic Mode", systemImage: "wand.and.stars")
        }
    }

    // MARK: - Wake Commands Section (WC-003)

    private var wakeCommandsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(settings.wakeCommands) { command in
                    WakeCommandRow(command: command) { updatedCommand in
                        updateWakeCommand(updatedCommand)
                    }
                }

                // Info text
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Wake commands prepend instructions to your voice input")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Wake Commands", systemImage: "text.bubble")
        }
    }

    private func updateWakeCommand(_ command: WakeCommand) {
        var commands = settings.wakeCommands
        if let index = commands.firstIndex(where: { $0.id == command.id }) {
            commands[index] = command
            settings.wakeCommands = commands
            writeConfigAsync()
        }
    }

    // MARK: - MCP Servers Section (MCP-002)

    private var mcpServersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                let servers = MCPConfigReader.readServers()

                if servers.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                        Text("No MCP servers configured in Claude settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(servers) { server in
                        MCPServerRow(server: server)
                    }

                    // Info message about agentic mode
                    if !settings.agenticMode {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text("Enable Agentic Mode to use MCP tools with voice commands")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(servers.count) MCP server\(servers.count == 1 ? "" : "s") available")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        } header: {
            Label("MCP Servers", systemImage: "puzzlepiece.extension")
        }
    }

    // MARK: - Provider Section (T-007)

    private var providerSection: some View {
        Section {
            Picker("Provider", selection: $settings.provider) {
                ForEach(LLMProvider.allCases) { provider in
                    Label {
                        Text(provider.displayName)
                    } icon: {
                        Image(systemName: provider.iconName)
                            .foregroundStyle(provider.color)
                    }
                    .tag(provider)
                }
            }
            .onChange(of: settings.provider) { _, newProvider in
                // Update API key saved status for new provider
                apiKeySaved = KeychainService.hasAPIKey(for: newProvider.rawValue)
                apiKeyInput = ""
                writeConfigAsync()
            }

            // Current provider status
            HStack(spacing: 8) {
                Image(systemName: settings.provider.iconName)
                    .foregroundStyle(settings.provider.color)
                Text("Using \(settings.provider.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Label("LLM Provider", systemImage: "cpu")
        }
    }

    // MARK: - API Key Section (T-008)

    private var apiKeySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: settings.provider.iconName)
                        .foregroundStyle(settings.provider.color)
                    Text("API Key for \(settings.provider.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    SecureField("Enter API key...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)

                    if apiKeySaved && apiKeyInput.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Saved")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .help("API key saved securely in Keychain")
                    }

                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKeyInput.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(settings.provider.color)
                }

                if settings.provider == .claude {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Claude uses CLI authentication. API key is optional.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Label("API Key", systemImage: "key.fill")
        }
    }

    // MARK: - Model Section (T-009)

    private var modelSection: some View {
        Section {
            if settings.provider == .ollama {
                // Ollama: text field for custom model
                VStack(alignment: .leading, spacing: 8) {
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
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }

                    Text("Enter the Ollama model name (e.g., llama3, mistral, codellama)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                // Claude/OpenAI: picker from predefined models
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Model", selection: $settings.model) {
                        ForEach(settings.provider.models, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .onChange(of: settings.model) { _, _ in
                        writeConfigAsync()
                    }

                    // Current model indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(settings.provider.color)
                            .frame(width: 6, height: 6)
                        Text("Active: \(settings.model)")
                            .font(.caption)
                            .foregroundStyle(settings.provider.color)
                    }
                }
            }
        } header: {
            Label("Model", systemImage: "cube.box")
        }
    }

    // MARK: - Behavior Section (T-010)

    private var behaviorSection: some View {
        Section {
            HStack {
                Toggle(isOn: $settings.copyToClipboard) {
                    Label("Copy response to clipboard", systemImage: "doc.on.clipboard")
                }
                .onChange(of: settings.copyToClipboard) { _, _ in
                    writeConfigAsync()
                }
                .toggleStyle(.switch)
                .tint(.blue)
            }

            HStack {
                Toggle(isOn: $settings.speakResponse) {
                    Label("Speak response aloud", systemImage: "speaker.wave.2")
                }
                .onChange(of: settings.speakResponse) { _, _ in
                    writeConfigAsync()
                }
                .toggleStyle(.switch)
                .tint(.green)
            }

            // SVR-002: Streaming response toggle (only when speech enabled)
            if settings.speakResponse {
                HStack {
                    Toggle(isOn: $settings.streamingResponse) {
                        Label("Stream response", systemImage: "waveform.path")
                    }
                    .onChange(of: settings.streamingResponse) { _, _ in
                        writeConfigAsync()
                    }
                    .toggleStyle(.switch)
                    .tint(.cyan)
                }

                // Streaming mode description
                HStack(spacing: 8) {
                    Image(systemName: settings.streamingResponse ? "hare.fill" : "tortoise.fill")
                        .foregroundStyle(settings.streamingResponse ? .cyan : .secondary)
                    Text(settings.streamingResponse
                        ? "Speaks words as they arrive (faster feedback)"
                        : "Waits for complete response before speaking")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Status indicators
            HStack(spacing: 16) {
                if settings.copyToClipboard {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Clipboard")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                if settings.speakResponse {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Speech")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                if !settings.copyToClipboard && !settings.speakResponse {
                    Text("No output options enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("Behavior", systemImage: "gearshape.2")
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

struct MCPServerRow: View {
    let server: MCPServerInfo

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: server.iconName)
                .font(.system(size: 12))
                .foregroundStyle(.cyan)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.displayName)
                    .font(.system(size: 12, weight: .medium))

                if let command = server.command {
                    Text(command)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Type badge
            Text(server.type)
                .font(.system(size: 9, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(server.type == "http" ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                )
                .foregroundStyle(server.type == "http" ? .blue : .secondary)
        }
        .padding(.vertical, 4)
    }
}

struct WakeCommandRow: View {
    let command: WakeCommand
    let onUpdate: (WakeCommand) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Enable/disable toggle
            Toggle("", isOn: Binding(
                get: { command.isEnabled },
                set: { newValue in
                    var updated = command
                    updated.isEnabled = newValue
                    onUpdate(updated)
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.green)

            // Command info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(command.isEnabled ? .green : .secondary)
                    Text("\"\(command.trigger)\"")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(command.isEnabled ? .primary : .secondary)
                }

                Text(command.action)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
}
