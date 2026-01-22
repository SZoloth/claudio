import Foundation

/// Application-wide constants and paths
enum Constants {
    /// Brabble Application Support directory
    static var brabbleAppSupportPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Application Support/brabble")
    }

    /// Brabble config directory
    static var brabbleConfigPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/brabble")
    }

    /// Voice sessions directory
    static var voiceSessionsPath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".claude/voice-sessions")
    }

    // MARK: - Log Files

    /// Main brabble daemon log
    static var brabbleLogPath: URL {
        brabbleAppSupportPath.appendingPathComponent("brabble.log")
    }

    /// Transcriptions log (all captured audio)
    static var transcriptsLogPath: URL {
        brabbleAppSupportPath.appendingPathComponent("transcripts.log")
    }

    /// Claude hook request/response log
    static var claudeHookLogPath: URL {
        brabbleAppSupportPath.appendingPathComponent("claude-hook.log")
    }

    /// PID file for daemon status
    static var pidFilePath: URL {
        brabbleAppSupportPath.appendingPathComponent("brabble.pid")
    }

    // MARK: - Config Files

    /// Brabble configuration
    static var configFilePath: URL {
        brabbleConfigPath.appendingPathComponent("config.toml")
    }

    // MARK: - UI Constants

    /// Maximum number of recent conversations to show in popover
    static let maxRecentConversations = 5

    /// Maximum number of recent transcriptions to show
    static let maxRecentTranscriptions = 10

    /// File watcher debounce interval (seconds)
    static let fileWatcherDebounceInterval: TimeInterval = 0.5

    /// Daemon status check interval (seconds)
    static let daemonCheckInterval: TimeInterval = 5.0
}
