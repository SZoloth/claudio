import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Full window view showing complete conversation history organized by sessions
struct ConversationHistoryView: View {
    @Bindable var viewModel: ClaudioViewModel
    @State private var searchText = ""
    @State private var selectedFilter: ConversationFilter = .all
    @State private var allTurns: [ConversationTurn] = []

    enum ConversationFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case pending = "Pending"
        case failed = "Failed"

        var status: TurnStatus? {
            switch self {
            case .all: return nil
            case .completed: return .completed
            case .pending: return .pending
            case .failed: return .failed
            }
        }
    }

    var filteredSessions: [ConversationSession] {
        var sessions = ConversationSession.groupTurnsIntoSessions(allTurns)

        // Filter by status
        if let status = selectedFilter.status {
            sessions = sessions.compactMap { session in
                let filteredTurns = session.turns.filter { $0.status == status }
                if filteredTurns.isEmpty { return nil }
                var newSession = session
                newSession.turns = filteredTurns
                return newSession
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            sessions = sessions.compactMap { session in
                let filteredTurns = session.turns.filter { turn in
                    turn.userRequest.localizedCaseInsensitiveContains(searchText) ||
                    (turn.claudeResponse?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
                if filteredTurns.isEmpty { return nil }
                var newSession = session
                newSession.turns = filteredTurns
                return newSession
            }
        }

        let pinnedSessions = sessions.filter { viewModel.isSessionPinned($0) }
        let unpinnedSessions = sessions.filter { !viewModel.isSessionPinned($0) }
        return pinnedSessions + unpinnedSessions
    }

    var totalTurnCount: Int {
        filteredSessions.reduce(0) { $0 + $1.turnCount }
    }

    private func copySessionMarkdown(_ session: ConversationSession) {
        let markdown = sessionMarkdown(session)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
    }

    private func exportSessionMarkdown(_ session: ConversationSession) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.markdown]
        panel.nameFieldStringValue = "session-\(sessionFileSlug(session)).md"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let markdown = sessionMarkdown(session)
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func sessionMarkdown(_ session: ConversationSession) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var lines: [String] = []
        lines.append("# Session \(dateFormatter.string(from: session.startTime))")
        lines.append("")
        lines.append("Turns: \(session.turnCount)")
        lines.append("Duration: \(session.durationString ?? \"-\")")
        lines.append("")

        for (index, turn) in session.turns.enumerated() {
            lines.append("## Turn \(index + 1)")
            lines.append("")
            lines.append("**User:** \(turn.userRequest)")
            lines.append("")

            if let response = turn.claudeResponse {
                lines.append("**Claude:** \(response)")
            } else {
                lines.append("**Claude:** _\(statusLabel(for: turn.status))_")
            }

            if let duration = turn.processingDurationString {
                lines.append("")
                lines.append("_Response time: \(duration)_")
            }

            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func statusLabel(for status: TurnStatus) -> String {
        switch status {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    private func sessionFileSlug(_ session: ConversationSession) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: session.startTime)
    }

    private func refreshAllTurns() {
        DispatchQueue.global(qos: .utility).async {
            let turns = viewModel.loadAllConversations()
            DispatchQueue.main.async {
                allTurns = turns
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search conversations...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ConversationFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }
            .padding()

            Divider()

            // Sessions list
            if filteredSessions.isEmpty {
                EmptyHistoryView(
                    hasFilter: !searchText.isEmpty || selectedFilter != .all,
                    wakeWord: viewModel.wakeWordConfig.word,
                    logStatus: viewModel.logStatus
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredSessions) { session in
                            SessionDetailCard(
                                session: session,
                                isPinned: viewModel.isSessionPinned(session),
                                onTogglePin: { viewModel.togglePin(session) },
                                onCopyMarkdown: { copySessionMarkdown(session) },
                                onExportMarkdown: { exportSessionMarkdown(session) }
                            )
                        }
                    }
                    .padding()
                }
            }

            // Status bar
            HStack {
                Text("\(filteredSessions.count) sessions • \(totalTurnCount) conversations")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                if viewModel.isProcessing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Processing...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            refreshAllTurns()
        }
        .onChange(of: viewModel.conversations) { _, _ in
            refreshAllTurns()
        }
    }
}

/// Session card showing all turns in a session
struct SessionDetailCard: View {
    let session: ConversationSession
    let isPinned: Bool
    let onTogglePin: () -> Void
    let onCopyMarkdown: () -> Void
    let onExportMarkdown: () -> Void
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Session header
            HStack(spacing: 8) {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    HStack {
                        // Status indicator
                        Circle()
                            .fill(session.statusColor)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text("Session")
                                    .font(.system(size: 13, weight: .semibold))

                                Text(session.startTime, style: .date)
                                    .font(.system(size: 12))

                                Text(session.startTime, style: .time)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Label("\(session.turnCount) turn\(session.turnCount == 1 ? "" : "s")",
                                      systemImage: "bubble.left.and.bubble.right")
                                    .font(.system(size: 11))

                                if let duration = session.durationString {
                                    Text("•")
                                    Text("Duration: \(duration)")
                                        .font(.system(size: 11))
                                }
                            }
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: { onTogglePin() }) {
                    Image(systemName: isPinned ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(isPinned ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(isPinned ? "Unpin session" : "Pin session")

                Menu {
                    Button("Copy Markdown") { onCopyMarkdown() }
                    Button("Export Markdown...") { onExportMarkdown() }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .help("Share session")
            }
            .padding(12)
            .background(Color.gray.opacity(0.08))

            // Turns
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(session.turns) { turn in
                        ConversationDetailRow(turn: turn)
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.03))
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ConversationDetailRow: View {
    let turn: ConversationTurn
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: turn.status.icon)
                    .foregroundColor(turn.status.color)
                    .font(.system(size: 11))

                Text(turn.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                if let duration = turn.processingDurationString {
                    Text("(\(duration))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
            }

            // User request
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))

                Text(turn.userRequest)
                    .font(.system(size: 12))
                    .lineLimit(isExpanded ? nil : 2)
            }

            // Claude response
            if let response = turn.claudeResponse {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.system(size: 14))

                    Text(response)
                        .font(.system(size: 12))
                        .lineLimit(isExpanded ? nil : 3)
                }
            } else if turn.status == .pending {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)

                    ProgressView()
                        .scaleEffect(0.6)

                    Text("Waiting for response...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

struct EmptyHistoryView: View {
    let hasFilter: Bool
    let wakeWord: String
    let logStatus: LogStatus

    var body: some View {
        VStack(spacing: 12) {
            if !hasFilter && logStatus.hasIssues {
                LogStatusMessage(status: logStatus, compact: false)

                Button("Open log folder") {
                    NSWorkspace.shared.open(Constants.brabbleAppSupportPath)
                }
                .buttonStyle(.bordered)
            } else {
                Image(systemName: hasFilter ? "magnifyingglass" : "bubble.left.and.bubble.right")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))

                Text(hasFilter ? "No matching conversations" : "No conversations yet")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(hasFilter ? "Try adjusting your search or filter" : "Start a conversation with \"\(wakeWord), ...\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let viewModel = ClaudioViewModel()
    return ConversationHistoryView(viewModel: viewModel)
}
