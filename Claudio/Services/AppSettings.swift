import SwiftUI

/// Screen context mode options
enum ScreenContextMode: String, CaseIterable, Identifiable {
    case off = "off"
    case onDemand = "on-demand"
    case always = "always"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .onDemand: return "On-Demand"
        case .always: return "Always"
        }
    }

    var description: String {
        switch self {
        case .off: return "Screen context disabled"
        case .onDemand: return "Captures screen when you say \"look at this\", \"what's this\", etc."
        case .always: return "Always includes screenshot with voice commands"
        }
    }
}

/// LLM provider options
enum LLMProvider: String, CaseIterable, Identifiable {
    case claude = "claude"
    case openai = "openai"
    case ollama = "ollama"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .openai: return "OpenAI"
        case .ollama: return "Ollama"
        }
    }

    /// Available models for this provider
    var models: [String] {
        switch self {
        case .claude:
            return ["opus", "sonnet", "haiku"]
        case .openai:
            return ["gpt-4o", "gpt-4o-mini", "o1", "o3-mini"]
        case .ollama:
            return [] // User specifies custom model name
        }
    }

    /// Default model for this provider
    var defaultModel: String {
        switch self {
        case .claude: return "opus"
        case .openai: return "gpt-4o"
        case .ollama: return "llama3"
        }
    }

    /// SF Symbol icon name for this provider
    var iconName: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .openai: return "sparkles"
        case .ollama: return "laptopcomputer"
        }
    }

    /// Brand color for this provider
    var color: Color {
        switch self {
        case .claude: return .orange
        case .openai: return .green
        case .ollama: return .purple
        }
    }
}

/// App settings with @AppStorage persistence
@Observable
class AppSettings {
    // Storage keys
    private enum Keys {
        static let provider = "settings.provider"
        static let model = "settings.model"
        static let copyToClipboard = "settings.copyToClipboard"
        static let transcribeOnlyMode = "settings.transcribeOnlyMode"
        static let speakResponse = "settings.speakResponse"
        static let ollamaModel = "settings.ollamaModel"
        static let screenContextMode = "settings.screenContextMode"
        static let agenticMode = "settings.agenticMode"
        static let wakeCommands = "settings.wakeCommands"
    }

    /// Selected LLM provider
    var provider: LLMProvider {
        get {
            let rawValue = UserDefaults.standard.string(forKey: Keys.provider) ?? LLMProvider.claude.rawValue
            return LLMProvider(rawValue: rawValue) ?? .claude
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.provider)
            // Reset model to provider default when switching providers
            if !newValue.models.contains(model) && newValue != .ollama {
                model = newValue.defaultModel
            }
        }
    }

    /// Selected model name
    var model: String {
        get {
            UserDefaults.standard.string(forKey: Keys.model) ?? LLMProvider.claude.defaultModel
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.model)
        }
    }

    /// Custom model name for Ollama
    var ollamaModel: String {
        get {
            UserDefaults.standard.string(forKey: Keys.ollamaModel) ?? "llama3"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.ollamaModel)
        }
    }

    /// Copy response to clipboard
    var copyToClipboard: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.copyToClipboard)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.copyToClipboard)
        }
    }

    /// Transcribe-only mode (no LLM conversation)
    var transcribeOnlyMode: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.transcribeOnlyMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.transcribeOnlyMode)
        }
    }

    /// Speak response aloud
    var speakResponse: Bool {
        get {
            // Default to true for backward compatibility
            if UserDefaults.standard.object(forKey: Keys.speakResponse) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.speakResponse)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.speakResponse)
        }
    }

    /// The effective model to use (handles Ollama custom model)
    var effectiveModel: String {
        if provider == .ollama {
            return ollamaModel
        }
        return model
    }

    /// Screen context mode for voice commands
    var screenContextMode: ScreenContextMode {
        get {
            let rawValue = UserDefaults.standard.string(forKey: Keys.screenContextMode) ?? ScreenContextMode.off.rawValue
            return ScreenContextMode(rawValue: rawValue) ?? .off
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.screenContextMode)
        }
    }

    /// Agentic mode - allows Claude to use tools and take actions
    var agenticMode: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.agenticMode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.agenticMode)
        }
    }

    /// Custom wake commands for voice triggers
    var wakeCommands: [WakeCommand] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.wakeCommands),
                  let commands = try? JSONDecoder().decode([WakeCommand].self, from: data) else {
                return WakeCommand.defaults
            }
            return commands
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.wakeCommands)
            }
        }
    }

    /// Get only enabled wake commands
    var enabledWakeCommands: [WakeCommand] {
        wakeCommands.filter { $0.isEnabled }
    }
}
