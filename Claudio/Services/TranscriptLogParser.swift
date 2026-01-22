import Foundation

/// Parser for transcripts.log format
/// Format: ISO_TIMESTAMP TEXT
final class TranscriptLogParser {
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

    /// Parse a single transcript line
    func parseLine(_ line: String) -> Transcription? {
        guard !line.isEmpty else { return nil }

        // Format: 2026-01-22T10:25:59.390-07:00 What is the weather?
        // Find the first space after the timestamp
        let components = line.split(separator: " ", maxSplits: 1)
        guard components.count == 2 else { return nil }

        let timestampString = String(components[0])
        let text = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard let timestamp = parseTimestamp(timestampString) else {
            return nil
        }

        // Check if it looks like a wake word triggered request
        let isWakeWordTriggered = text.lowercased().hasPrefix("claude")

        return Transcription(
            timestamp: timestamp,
            text: text,
            isWakeWordTriggered: isWakeWordTriggered
        )
    }

    /// Parse multiple lines from log content
    func parseLog(_ content: String) -> [Transcription] {
        content.components(separatedBy: .newlines)
            .compactMap { parseLine($0) }
    }

    /// Parse log file
    func parseLogFile(at url: URL) -> [Transcription] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        return parseLog(content)
    }

    /// Get only the most recent transcriptions
    func parseRecentTranscriptions(at url: URL, count: Int = 20) -> [Transcription] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
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
}
