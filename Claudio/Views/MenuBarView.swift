import SwiftUI

/// Main popover view for menu bar
struct MenuBarView: View {
    @Bindable var viewModel: ClaudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            StatusHeader(viewModel: viewModel)

            Divider()

            // Stats view
            StatsView(stats: viewModel.sessionStats)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            // Live transcription display
            if let transcription = viewModel.currentTranscription, !transcription.isEmpty {
                TranscriptionView(text: transcription)
            }

            // Processing indicator
            if viewModel.isProcessing {
                ProcessingBanner()
            }

            // Recent sessions
            if viewModel.sessions.isEmpty {
                EmptyConversationsView(wakeWord: viewModel.wakeWordConfig.word)
            } else {
                SessionsList(sessions: viewModel.recentSessionsForPopover)
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

    var body: some View {
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

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
            .padding(12)
        }
        .frame(maxHeight: 300)
    }
}

struct SessionRow: View {
    let session: ConversationSession
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
                        Text(session.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.primary)

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

    var body: some View {
        HStack {
            Button(action: { viewModel.openHistoryWindow() }) {
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
}

#Preview {
    let viewModel = ClaudioViewModel()
    return MenuBarView(viewModel: viewModel)
}
