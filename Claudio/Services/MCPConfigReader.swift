import Foundation

/// Represents an MCP server configuration
struct MCPServerInfo: Identifiable {
    let id: String
    let name: String
    let command: String?
    let type: String  // "stdio" or "http"

    var displayName: String {
        // Convert kebab-case to Title Case
        name.split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var iconName: String {
        switch type {
        case "http": return "network"
        default: return "terminal"
        }
    }
}

/// Service to read MCP server configuration from Claude settings
struct MCPConfigReader {
    private static let settingsPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")

    /// Read all configured MCP servers
    static func readServers() -> [MCPServerInfo] {
        guard let data = try? Data(contentsOf: settingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let mcpServers = json["mcpServers"] as? [String: Any] else {
            return []
        }

        return mcpServers.compactMap { (name, config) -> MCPServerInfo? in
            guard let configDict = config as? [String: Any] else { return nil }

            let type = configDict["type"] as? String ?? "stdio"
            let command = configDict["command"] as? String

            return MCPServerInfo(
                id: name,
                name: name,
                command: command,
                type: type
            )
        }.sorted { $0.name < $1.name }
    }

    /// Check if any MCP servers are configured
    static var hasServers: Bool {
        !readServers().isEmpty
    }

    /// Get count of configured servers
    static var serverCount: Int {
        readServers().count
    }
}
