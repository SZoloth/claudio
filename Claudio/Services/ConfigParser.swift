import Foundation

/// Parsed wake word configuration from brabble config.toml
struct WakeWordConfig {
    let word: String
    let aliases: [String]

    /// All wake words (primary + aliases)
    var allWords: [String] {
        [word] + aliases
    }

    /// Display string for UI (e.g., "clawd" or "clawd / claude")
    var displayString: String {
        if aliases.isEmpty {
            return "\"\(word)\""
        }
        let allQuoted = allWords.map { "\"\($0)\"" }
        return allQuoted.joined(separator: " or ")
    }

    /// Default config when file can't be parsed
    static let defaultConfig = WakeWordConfig(word: "claude", aliases: [])
}

/// Parses brabble configuration files
enum ConfigParser {

    /// Parse wake word configuration from config.toml
    static func parseWakeConfig(at path: URL) -> WakeWordConfig {
        guard let content = try? String(contentsOf: path, encoding: .utf8) else {
            return .defaultConfig
        }

        return parseWakeConfig(from: content)
    }

    /// Parse wake word from TOML content string
    static func parseWakeConfig(from content: String) -> WakeWordConfig {
        // Find [wake] section
        guard let wakeRange = content.range(of: "[wake]") else {
            return .defaultConfig
        }

        // Extract section content (until next section or EOF)
        let sectionStart = wakeRange.upperBound
        let sectionContent: String
        if let nextSection = content.range(of: "\n[", range: sectionStart..<content.endIndex) {
            sectionContent = String(content[sectionStart..<nextSection.lowerBound])
        } else {
            sectionContent = String(content[sectionStart...])
        }

        // Parse word = 'value'
        let word = parseStringValue(key: "word", from: sectionContent) ?? "claude"

        // Parse aliases = ['value1', 'value2']
        let aliases = parseArrayValue(key: "aliases", from: sectionContent)

        return WakeWordConfig(word: word, aliases: aliases)
    }

    // MARK: - Private Helpers

    private static func parseStringValue(key: String, from content: String) -> String? {
        // Match: key = 'value' or key = "value"
        let pattern = #"\b\#(key)\s*=\s*['"]([^'"]+)['"]"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: content,
                range: NSRange(content.startIndex..., in: content)
              ),
              let valueRange = Range(match.range(at: 1), in: content)
        else {
            return nil
        }
        return String(content[valueRange])
    }

    private static func parseArrayValue(key: String, from content: String) -> [String] {
        // Match: key = ['value1', 'value2'] or key = ["value1", "value2"]
        let pattern = #"\b\#(key)\s*=\s*\[([^\]]*)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: content,
                range: NSRange(content.startIndex..., in: content)
              ),
              let arrayRange = Range(match.range(at: 1), in: content)
        else {
            return []
        }

        let arrayContent = String(content[arrayRange])

        // Extract quoted strings from array content
        let valuePattern = #"['"]([^'"]+)['"]"#
        guard let valueRegex = try? NSRegularExpression(pattern: valuePattern) else {
            return []
        }

        let matches = valueRegex.matches(
            in: arrayContent,
            range: NSRange(arrayContent.startIndex..., in: arrayContent)
        )

        return matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: arrayContent) else {
                return nil
            }
            return String(arrayContent[range])
        }
    }
}
