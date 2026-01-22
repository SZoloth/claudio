import Foundation

/// Raw parsed entry from claude-hook.log
struct ClaudeHookEntry {
    let timestamp: Date
    let type: EntryType
    let content: String

    enum EntryType {
        case received
        case response
    }
}

/// Parser for claude-hook.log format
/// Format: [YYYY-MM-DD HH:MM:SS] Received: text
///         [YYYY-MM-DD HH:MM:SS] Response: text
final class ClaudeHookLogParser {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Parse a single log line
    func parseLine(_ line: String) -> ClaudeHookEntry? {
        guard !line.isEmpty else { return nil }

        // Format: [2026-01-22 10:16:13] Received: what time is it?
        let pattern = #"\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] (Received|Response): (.+)"#

        guard let match = line.firstMatch(of: try! Regex(pattern)) else {
            return nil
        }

        let timestampString = String(match.output[1].substring!)
        let typeString = String(match.output[2].substring!)
        let content = String(match.output[3].substring!)

        guard let timestamp = dateFormatter.date(from: timestampString) else {
            return nil
        }

        let type: ClaudeHookEntry.EntryType = typeString == "Received" ? .received : .response

        return ClaudeHookEntry(timestamp: timestamp, type: type, content: content)
    }

    /// Parse log content and correlate requests with responses
    func parseAndCorrelate(_ content: String) -> [ConversationTurn] {
        let lines = content.components(separatedBy: .newlines)
        let entries = lines.compactMap { parseLine($0) }

        var turns: [ConversationTurn] = []
        var pendingRequest: ClaudeHookEntry?

        for entry in entries {
            switch entry.type {
            case .received:
                // If there's a pending request without response, mark it as failed
                if let pending = pendingRequest {
                    turns.append(ConversationTurn(
                        timestamp: pending.timestamp,
                        userRequest: pending.content,
                        claudeResponse: nil,
                        status: .failed
                    ))
                }
                pendingRequest = entry

            case .response:
                if let request = pendingRequest {
                    // Match response with pending request
                    turns.append(ConversationTurn(
                        timestamp: request.timestamp,
                        userRequest: request.content,
                        claudeResponse: entry.content,
                        status: .completed,
                        responseTimestamp: entry.timestamp
                    ))
                    pendingRequest = nil
                } else {
                    // Response without matching request (orphaned)
                    // Skip or log warning
                }
            }
        }

        // Handle any remaining pending request
        if let pending = pendingRequest {
            turns.append(ConversationTurn(
                timestamp: pending.timestamp,
                userRequest: pending.content,
                claudeResponse: nil,
                status: .pending
            ))
        }

        return turns
    }

    /// Parse log file and return correlated conversation turns
    func parseLogFile(at url: URL) -> [ConversationTurn] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parseAndCorrelate(content)
    }

    /// Get only the most recent conversation turns
    func parseRecentTurns(at url: URL, count: Int = 10) -> [ConversationTurn] {
        let turns = parseLogFile(at: url)
        return Array(turns.suffix(count))
    }

    /// Check if there's a pending request (no response yet)
    func hasPendingRequest(at url: URL) -> Bool {
        let turns = parseLogFile(at: url)
        return turns.last?.status == .pending
    }
}
