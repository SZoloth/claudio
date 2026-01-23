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

    /// Log availability status
    var logStatus: LogStatus = .empty

    /// Wake word configuration from brabble config
    var wakeWordConfig: WakeWordConfig = .defaultConfig

    /// Conversation sessions (grouped turns)
    var sessions: [ConversationSession] = []

    /// Pinned session IDs
    var pinnedSessionIDs: Set<String> = []

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

    private let logStore = LogStore()
    private let pinnedStore = PinnedSessionsStore()
    private let claudeHookParser = ClaudeHookLogParser()
    private let processRunner = ProcessRunner()

    private var daemonCheckTimer: Timer?

    // MARK: - Lifecycle

    init() {
        loadWakeWordConfig()
        pinnedSessionIDs = pinnedStore.loadPinnedIDs()
        setupLogStore()
        startDaemonMonitoring()
    }

    deinit {
        logStore.stop()
        daemonCheckTimer?.invalidate()
    }

    // MARK: - Setup

    private func loadWakeWordConfig() {
        wakeWordConfig = ConfigParser.parseWakeConfig(at: Constants.configFilePath)
    }

    private func setupLogStore() {
        logStore.onSnapshotUpdate = { [weak self] snapshot in
            Task { @MainActor in
                self?.recentTranscriptions = snapshot.transcriptions.reversed()
                self?.conversations = snapshot.turns.reversed()
                self?.sessions = snapshot.sessions
                self?.isProcessing = snapshot.isProcessing
                self?.sessionStats = snapshot.stats
                self?.logStatus = snapshot.logStatus
            }
        }

        logStore.onBrabbleEvents = { [weak self] events in
            Task { @MainActor in
                self?.handleBrabbleEvents(events)
            }
        }

        logStore.start()
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

    func loadAllConversations() -> [ConversationTurn] {
        claudeHookParser.parseLogFile(at: Constants.claudeHookLogPath).reversed()
    }

    private func handleBrabbleEvents(_ events: [BrabbleEvent]) {
        for event in events {
            switch event {
            case .heard(let text, _):
                // Update live transcription display
                updateTranscription(text)
            case .hookExecuted:
                // Hook started - processing begins
                if !isProcessing {
                    isProcessing = true
                    clearTranscription()
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

    func togglePin(_ session: ConversationSession) {
        let id = session.stableID
        if pinnedSessionIDs.contains(id) {
            pinnedSessionIDs.remove(id)
        } else {
            pinnedSessionIDs.insert(id)
        }
        pinnedStore.savePinnedIDs(pinnedSessionIDs)
    }

    func isSessionPinned(_ session: ConversationSession) -> Bool {
        pinnedSessionIDs.contains(session.stableID)
    }

    /// Update current transcription, preserving previous value
    func updateTranscription(_ text: String?) {
        // When receiving new non-nil text while current has value, move current to previous
        if let newText = text, !newText.isEmpty, currentTranscription != nil {
            previousTranscription = currentTranscription
        }
        currentTranscription = text

        // Show/hide floating transcription panel (dispatch to main actor)
        Task { @MainActor in
            if let text = text, !text.isEmpty {
                TranscriptionPanelController.shared.show(text: text)
            } else {
                TranscriptionPanelController.shared.hide()
            }
        }
    }

    /// Clear current transcription (called when processing begins)
    func clearTranscription() {
        currentTranscription = nil
        // previousTranscription is preserved
        Task { @MainActor in
            TranscriptionPanelController.shared.hide()
        }
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
        let pinned = sessions.filter { isSessionPinned($0) }
        let unpinned = sessions.filter { !isSessionPinned($0) }
        return Array((pinned + unpinned).prefix(3))
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
