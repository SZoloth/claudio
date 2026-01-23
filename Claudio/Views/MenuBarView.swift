import SwiftUI
import AppKit

/// Main popover view for menu bar
struct MenuBarView: View {
    @Bindable var viewModel: ClaudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            StatusHeader(viewModel: viewModel)

            Divider()

            if viewModel.logStatus.hasIssues {
                LogStatusMessage(status: viewModel.logStatus, compact: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                Divider()
            }

            // Stats view
            StatsView(stats: viewModel.sessionStats)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Live transcription display
            if let transcription = viewModel.currentTranscription, !transcription.isEmpty {
                TranscriptionView(text: transcription)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.currentTranscription)
            } else if let previous = viewModel.previousTranscription, !previous.isEmpty {
                PreviousTranscriptionIndicator(text: previous)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.previousTranscription)
            }

            // Processing indicator
            if viewModel.isProcessing {
                ProcessingBanner()
            }

            // Recent sessions
            if viewModel.sessions.isEmpty {
                EmptyConversationsView(wakeWord: viewModel.wakeWordConfig.word)
            } else {
                SessionsList(
                    sessions: viewModel.recentSessionsForPopover,
                    pinnedSessionIDs: viewModel.pinnedSessionIDs
                )
            }

            Divider()

            // Actions
            ActionsBar(viewModel: viewModel)
        }
        .frame(width: 320)
    }
}

// MARK: - Components

struct StatusHeader: View {
    @Bindable var viewModel: ClaudioViewModel
    private let settings = AppSettings()

    private var hasStatusIndicators: Bool {
        settings.transcribeOnlyMode ||
        settings.screenContextMode != .off ||
        settings.agenticMode ||
        (settings.agenticMode && MCPConfigReader.hasServers)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode indicators
            HStack(spacing: 8) {
                // Transcribe mode indicator
                if settings.transcribeOnlyMode {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 10))
                        Text("Transcribe Mode")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
                }

                // SC-007: Screen context indicator
                if settings.screenContextMode != .off {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 10))
                        Text(settings.screenContextMode == .always ? "Screen: Always" : "Screen: On-Demand")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.blue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(4)
                }

                // AG-005: Agentic mode indicator
                if settings.agenticMode {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 10))
                        Text("Agentic")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.purple)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(4)
                }

                // MCP-003: MCP servers indicator (only when agentic mode enabled)
                if settings.agenticMode && MCPConfigReader.hasServers {
                    HStack(spacing: 4) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.system(size: 10))
                        Text("MCP: \(MCPConfigReader.serverCount)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.cyan)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(4)
                }
            }
            .padding(.top, hasStatusIndicators ? 8 : 0)
            .padding(.bottom, hasStatusIndicators ? 4 : 0)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        StatusIndicator(
                            status: viewModel.daemonInfo.status,
                            isProcessing: viewModel.isProcessing,
                            size: 10
                        )
                        Text("brabble")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text(viewModel.statusText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    // Wake word display
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(viewModel.wakeWordConfig.displayString)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(.secondary)

                    if let uptime = viewModel.daemonInfo.uptimeString {
                        Text(uptime)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
            }
            .padding(12)
        }
    }
}

struct ProcessingBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Claude is thinking...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
    }
}

struct SessionsList: View {
    let sessions: [ConversationSession]
    let pinnedSessionIDs: Set<String>

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(sessions) { session in
                    SessionRow(
                        session: session,
                        isPinned: pinnedSessionIDs.contains(session.stableID)
                    )
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 300)
    }
}

struct SessionRow: View {
    let session: ConversationSession
    let isPinned: Bool
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Session header (always visible)
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    // Status indicator
                    Circle()
                        .fill(session.statusColor)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(session.title)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(.primary)

                            if isPinned {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.yellow)
                            }
                        }

                        HStack(spacing: 6) {
                            // Turn count
                            Label("\(session.turnCount)", systemImage: "bubble.left.and.bubble.right")
                                .font(.system(size: 10))

                            // Duration if available
                            if let duration = session.durationString {
                                Text("•")
                                Text(duration)
                                    .font(.system(size: 10))
                            }

                            // Time
                            Text("•")
                            Text(session.relativeTimeString)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Expanded turns
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(session.turns) { turn in
                        ConversationTurnRow(turn: turn)
                            .padding(.leading, 16)
                    }
                }
                .padding(.top, 4)
            }
        }
    }
}

struct ConversationsList: View {
    let conversations: [ConversationTurn]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(conversations) { turn in
                    ConversationTurnRow(turn: turn)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 300)
    }
}

struct EmptyConversationsView: View {
    let wakeWord: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No conversations yet")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Text("Say \"\(wakeWord)\" to start")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ActionsBar: View {
    @Bindable var viewModel: ClaudioViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        HStack {
            Button(action: { openWindow(id: "history") }) {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Spacer()

            Button(action: { viewModel.checkDaemonStatus() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Refresh status")

            Button(action: { copyLastResponse() }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Copy last response")
            .disabled(viewModel.latestConversation?.claudeResponse == nil)

            Button(action: { openLogFolder() }) {
                Image(systemName: "folder")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Open log folder")

            SettingsLink {
                Image(systemName: "gear")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Image(systemName: "power")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Quit Claudio")
        }
        .padding(12)
    }

    private func copyLastResponse() {
        guard let response = viewModel.latestConversation?.claudeResponse else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(response, forType: .string)
    }

    private func openLogFolder() {
        NSWorkspace.shared.open(Constants.brabbleAppSupportPath)
    }
}

#Preview {
    let viewModel = ClaudioViewModel()
    return MenuBarView(viewModel: viewModel)
}
