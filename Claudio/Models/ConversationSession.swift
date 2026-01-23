import Foundation
import SwiftUI
import CryptoKit

/// A session containing multiple conversation turns grouped by temporal proximity
struct ConversationSession: Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    var turns: [ConversationTurn]

    /// Time gap threshold for grouping turns into sessions (5 minutes)
    static let sessionGapThreshold: TimeInterval = 5 * 60

    init(id: UUID = UUID(), startTime: Date, turns: [ConversationTurn] = []) {
        self.id = id
        self.startTime = startTime
        self.turns = turns
    }

    // MARK: - Computed Properties

    /// End time of the session (last turn's response time or request time)
    var endTime: Date {
        guard let lastTurn = turns.last else { return startTime }
        return lastTurn.responseTimestamp ?? lastTurn.timestamp
    }

    /// Duration of the session
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// Number of turns in the session
    var turnCount: Int {
        turns.count
    }

    /// Whether the session is currently active (has pending turn)
    var isActive: Bool {
        turns.last?.status == .pending || turns.last?.status == .processing
    }

    /// Session status based on latest turn
    var status: TurnStatus {
        turns.last?.status ?? .completed
    }

    /// Status color for UI
    var statusColor: Color {
        status.color
    }

    /// Relative time string for display
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: startTime, relativeTo: Date())
    }

    /// Session title (first user request, truncated)
    var title: String {
        guard let firstRequest = turns.first?.userRequest else {
            return "Empty session"
        }
        if firstRequest.count > 50 {
            return String(firstRequest.prefix(47)) + "..."
        }
        return firstRequest
    }

    /// Formatted duration string
    var durationString: String? {
        guard duration > 0 else { return nil }
        if duration < 60 {
            return String(format: "%.0fs", duration)
        } else if duration < 3600 {
            return String(format: "%.0fm", duration / 60)
        } else {
            return String(format: "%.1fh", duration / 3600)
        }
    }

    /// Stable identifier derived from start time and first request content
    var stableID: String {
        let firstRequest = turns.first?.userRequest ?? ""
        let base = "\(startTime.timeIntervalSince1970)|\(firstRequest)"
        let digest = SHA256.hash(data: Data(base.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Static Methods

    /// Group conversation turns into sessions based on time gaps
    static func groupTurnsIntoSessions(_ turns: [ConversationTurn]) -> [ConversationSession] {
        guard !turns.isEmpty else { return [] }

        // Sort turns by timestamp (oldest first for grouping)
        let sortedTurns = turns.sorted { $0.timestamp < $1.timestamp }

        var sessions: [ConversationSession] = []
        var currentSession = ConversationSession(startTime: sortedTurns[0].timestamp)

        for turn in sortedTurns {
            if let lastTurn = currentSession.turns.last {
                let lastTime = lastTurn.responseTimestamp ?? lastTurn.timestamp
                let gap = turn.timestamp.timeIntervalSince(lastTime)

                if gap > sessionGapThreshold {
                    // Start new session
                    sessions.append(currentSession)
                    currentSession = ConversationSession(startTime: turn.timestamp)
                }
            }
            currentSession.turns.append(turn)
        }

        // Append final session
        sessions.append(currentSession)

        // Return in reverse chronological order (newest first)
        return sessions.reversed()
    }
}
