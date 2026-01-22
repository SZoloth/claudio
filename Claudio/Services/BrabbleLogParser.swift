import Foundation

/// Parsed event from brabble.log
enum BrabbleEvent: Equatable {
    case heard(text: String, timestamp: Date)
    case wakeWordMatched(word: String, timestamp: Date)
    case hookExecuted(command: String, timestamp: Date)
    case hookOutput(output: String, timestamp: Date)
    case error(message: String, timestamp: Date)
    case info(message: String, timestamp: Date)
}

/// Parser for brabble.log format
/// Format: time=ISO level=LEVEL msg="content"
final class BrabbleLogParser {
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parse a single log line
    func parseLine(_ line: String) -> BrabbleEvent? {
        guard !line.isEmpty else { return nil }

        // Extract components using regex
        // Note: msgPattern handles escaped quotes like \"
        let timePattern = #"time=([^\s]+)"#
        let levelPattern = #"level=(\w+)"#
        let msgPattern = #"msg="((?:[^"\\]|\\.)*)""#

        guard let timeMatch = line.firstMatch(of: try! Regex(timePattern)),
              let levelMatch = line.firstMatch(of: try! Regex(levelPattern)),
              let msgMatch = line.firstMatch(of: try! Regex(msgPattern)) else {
            return nil
        }

        let timeString = String(timeMatch.output[1].substring!)
        let level = String(levelMatch.output[1].substring!)
        // Unescape quotes in the message
        let rawMessage = String(msgMatch.output[1].substring!)
        let message = rawMessage.replacingOccurrences(of: "\\\"", with: "\"")

        // Parse timestamp
        guard let timestamp = parseTimestamp(timeString) else {
            return nil
        }

        // Parse based on message content
        return parseMessage(message, level: level, timestamp: timestamp)
    }

    /// Parse multiple lines from log content
    func parseLog(_ content: String) -> [BrabbleEvent] {
        content.components(separatedBy: .newlines)
            .compactMap { parseLine($0) }
    }

    /// Parse log file
    func parseLogFile(at url: URL) -> [BrabbleEvent] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parseLog(content)
    }

    /// Get only the most recent events (tail of log)
    func parseRecentEvents(at url: URL, count: Int = 50) -> [BrabbleEvent] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
        let recentLines = lines.suffix(count)
        return recentLines.compactMap { parseLine($0) }
    }

    // MARK: - Private

    private func parseTimestamp(_ string: String) -> Date? {
        // Try with fractional seconds first
        if let date = isoFormatter.date(from: string) {
            return date
        }
        // Fall back to no fractional seconds
        return isoFormatterNoFraction.date(from: string)
    }

    private func parseMessage(_ message: String, level: String, timestamp: Date) -> BrabbleEvent? {
        // Check for specific event patterns
        if message.hasPrefix("heard:") {
            let text = message.dropFirst(6).trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return .heard(text: text, timestamp: timestamp)
        }

        if message.contains("wake word matched") || message.contains("wake word detected") {
            let word = extractQuotedContent(from: message) ?? "claude"
            return .wakeWordMatched(word: word, timestamp: timestamp)
        }

        if message.hasPrefix("executing hook:") || message.contains("hook exec") {
            let command = extractQuotedContent(from: message) ?? message
            return .hookExecuted(command: command, timestamp: timestamp)
        }

        if message.hasPrefix("hook output:") {
            let output = message.dropFirst(12).trimmingCharacters(in: .whitespaces)
            return .hookOutput(output: output, timestamp: timestamp)
        }

        // Generic events based on level
        switch level.uppercased() {
        case "ERROR", "FATAL":
            return .error(message: message, timestamp: timestamp)
        default:
            return .info(message: message, timestamp: timestamp)
        }
    }

    private func extractQuotedContent(from string: String) -> String? {
        let pattern = #""([^"]+)""#
        if let match = string.firstMatch(of: try! Regex(pattern)) {
            return String(match.output[1].substring!)
        }
        return nil
    }
}
