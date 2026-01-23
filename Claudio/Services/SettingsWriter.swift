import Foundation

/// Service that writes settings to hook-config.sh for bash script access
struct SettingsWriter {
    private static let configDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/claudio")
    private static let configFile = configDir.appendingPathComponent("hook-config.sh")

    /// Write current settings to the hook config file
    /// - Parameter settings: The app settings to write
    static func writeHookConfig(settings: AppSettings) {
        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: configDir,
            withIntermediateDirectories: true
        )

        // Get API key for current provider
        let apiKey = KeychainService.getAPIKey(for: settings.provider.rawValue) ?? ""

        // Build config content
        var lines = [
            "#!/bin/bash",
            "# Claudio hook configuration",
            "# Auto-generated - do not edit manually",
            "",
            "export CLAUDIO_PROVIDER=\"\(settings.provider.rawValue)\"",
            "export CLAUDIO_MODEL=\"\(settings.effectiveModel)\"",
            "export CLAUDIO_COPY_CLIPBOARD=\"\(settings.copyToClipboard ? "true" : "false")\"",
            "export CLAUDIO_TRANSCRIBE_ONLY=\"\(settings.transcribeOnlyMode ? "true" : "false")\"",
            "export CLAUDIO_SPEAK_RESPONSE=\"\(settings.speakResponse ? "true" : "false")\"",
            "export CLAUDIO_SCREEN_CONTEXT=\"\(settings.screenContextMode.rawValue)\"",
            "export CLAUDIO_AGENTIC_MODE=\"\(settings.agenticMode ? "true" : "false")\"",
        ]

        // WC-004: Export enabled wake commands as JSON
        let enabledCommands = settings.enabledWakeCommands
        if !enabledCommands.isEmpty {
            let commandsData = enabledCommands.map { ["trigger": $0.trigger, "action": $0.action] }
            if let jsonData = try? JSONSerialization.data(withJSONObject: commandsData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Escape single quotes for bash
                let escapedJson = jsonString.replacingOccurrences(of: "'", with: "'\\''")
                lines.append("export CLAUDIO_WAKE_COMMANDS='\(escapedJson)'")
            }
        }

        // Only write API key if it exists (don't expose empty string)
        if !apiKey.isEmpty {
            lines.append("export CLAUDIO_API_KEY=\"\(apiKey)\"")
        }

        let content = lines.joined(separator: "\n") + "\n"

        do {
            try content.write(to: configFile, atomically: true, encoding: .utf8)
            // Make it executable
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: configFile.path
            )
        } catch {
            print("Failed to write hook config: \(error)")
        }
    }

    /// Get the path to the config file
    static var configPath: String {
        configFile.path
    }
}
