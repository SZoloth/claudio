import Foundation
import SwiftUI

/// Main view model for Claudio app state
@Observable
final class ClaudioViewModel {
    // MARK: - Published State

    /// Current daemon status
    var daemonInfo: DaemonInfo = DaemonInfo()

    /// Recent transcriptions (all captured audio)
    var recentTranscriptions: [Transcription] = []

    /// Conversation history (request/response pairs)
    var conversations: [ConversationTurn] = []

    /// Whether Claude is currently processing a request
    var isProcessing: Bool = false

    /// Any error message to display
    var errorMessage: String?

    /// Whether the full history window is open
    var isHistoryWindowOpen: Bool = false

    /// Wake word configuration from brabble config
    var wakeWordConfig: WakeWordConfig = .defaultConfig

    /// Conversation sessions (grouped turns)
    var sessions: [ConversationSession] = []

    /// Today's session statistics
    var sessionStats: SessionStats = .empty

    /// Current live transcription text being displayed
    var currentTranscription: String?

    /// Previous transcription for context indicator
    var previousTranscription: String?

    /// Current active session (if any)
    var currentSession: ConversationSession? {
        sessions.first { $0.isActive }
    }

    // MARK: - Services

    private let fileWatcher = FileWatcherService()
    private let brabbleParser = BrabbleLogParser()
    private let transcriptParser = TranscriptLogParser()
    private let claudeHookParser = ClaudeHookLogParser()
    private let processRunner = ProcessRunner()
    private let statsService = StatsService()

    private var daemonCheckTimer: Timer?

    // MARK: - Lifecycle

    init() {
        loadWakeWordConfig()
        setupFileWatchers()
        startDaemonMonitoring()
        loadInitialData()
        setupStatsWatching()
    }

    deinit {
        fileWatcher.stopAll()
        daemonCheckTimer?.invalidate()
        statsService.stopWatching()
    }

    // MARK: - Setup

    private func loadWakeWordConfig() {
        wakeWordConfig = ConfigParser.parseWakeConfig(at: Constants.configFilePath)
    }

    private func setupFileWatchers() {
        // Watch transcripts.log
        fileWatcher.watch(Constants.transcriptsLogPath) { [weak self] in
            self?.reloadTranscriptions()
        }

        // Watch claude-hook.log
        fileWatcher.watch(Constants.claudeHookLogPath) { [weak self] in
            self?.reloadConversations()
        }

        // Watch brabble.log for daemon events
        fileWatcher.watch(Constants.brabbleLogPath) { [weak self] in
            self?.handleBrabbleLogChange()
        }
    }

    private func startDaemonMonitoring() {
        // Check daemon status periodically
        daemonCheckTimer = Timer.scheduledTimer(
            withTimeInterval: Constants.daemonCheckInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkDaemonStatus()
        }

        // Initial check
        checkDaemonStatus()
    }

    private func loadInitialData() {
        reloadTranscriptions()
        reloadConversations()
    }

    private func setupStatsWatching() {
        statsService.startWatching { [weak self] stats in
            self?.sessionStats = stats
        }
    }

    // MARK: - Data Loading

    func reloadTranscriptions() {
        let transcriptions = transcriptParser.parseRecentTranscriptions(
            at: Constants.transcriptsLogPath,
            count: Constants.maxRecentTranscriptions
        )
        self.recentTranscriptions = transcriptions.reversed()
    }

    func reloadConversations() {
        let turns = claudeHookParser.parseRecentTurns(
            at: Constants.claudeHookLogPath,
            count: 50  // Load more for better session grouping
        )
        self.conversations = turns.reversed()

        // Group into sessions
        self.sessions = ConversationSession.groupTurnsIntoSessions(turns)

        // Update processing state
        self.isProcessing = turns.last?.status == .pending
    }

    func loadAllConversations() -> [ConversationTurn] {
        claudeHookParser.parseLogFile(at: Constants.claudeHookLogPath).reversed()
    }

    private func handleBrabbleLogChange() {
        // Parse recent events to detect processing state changes and transcriptions
        let events = brabbleParser.parseRecentEvents(at: Constants.brabbleLogPath, count: 10)

        // Check for events (most recent first)
        for event in events.reversed() {
            switch event {
            case .heard(let text, _):
                // Update live transcription display
                updateTranscription(text)
            case .hookExecuted:
                // Hook started - might be processing
                if !isProcessing {
                    isProcessing = true
                }
            default:
                break
            }
        }
    }

    // MARK: - Daemon Status

    func checkDaemonStatus() {
        let info = processRunner.checkBrabbleStatus()
        self.daemonInfo = info
    }

    // MARK: - Actions

    func clearError() {
        errorMessage = nil
    }

    func openHistoryWindow() {
        isHistoryWindowOpen = true
    }

    func closeHistoryWindow() {
        isHistoryWindowOpen = false
    }

    /// Update current transcription, preserving previous value
    func updateTranscription(_ text: String?) {
        // When receiving new non-nil text while current has value, move current to previous
        if let newText = text, !newText.isEmpty, currentTranscription != nil {
            previousTranscription = currentTranscription
        }
        currentTranscription = text
    }

    /// Clear current transcription (called when processing begins)
    func clearTranscription() {
        currentTranscription = nil
        // previousTranscription is preserved
    }

    // MARK: - Computed Properties

    /// Most recent transcription
    var latestTranscription: Transcription? {
        recentTranscriptions.first
    }

    /// Most recent conversation
    var latestConversation: ConversationTurn? {
        conversations.first
    }

    /// Recent conversations for popover (limited count)
    var recentConversationsForPopover: [ConversationTurn] {
        Array(conversations.prefix(Constants.maxRecentConversations))
    }

    /// Recent sessions for popover (limited count)
    var recentSessionsForPopover: [ConversationSession] {
        Array(sessions.prefix(3))  // Show up to 3 recent sessions
    }

    /// Status color for menu bar icon
    var statusColor: Color {
        if isProcessing {
            return .blue
        }
        return daemonInfo.status.color
    }

    /// Status text for display
    var statusText: String {
        if isProcessing {
            return "Processing..."
        }
        return daemonInfo.status.displayText
    }
}
