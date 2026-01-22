import SwiftUI

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
}
