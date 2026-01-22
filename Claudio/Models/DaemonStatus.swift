import Foundation
import SwiftUI

/// Status of the brabble daemon
enum DaemonStatus: String, Codable {
    case running     // Daemon is active and listening
    case stopped     // Daemon is not running
    case error       // Daemon has an error
    case unknown     // Cannot determine status

    var color: Color {
        switch self {
        case .running: return .green
        case .stopped: return .gray
        case .error: return .red
        case .unknown: return .orange
        }
    }

    var displayText: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .error: return "Error"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .running: return "checkmark.circle.fill"
        case .stopped: return "stop.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

/// Extended daemon information
struct DaemonInfo: Equatable {
    var status: DaemonStatus
    var pid: Int?
    var uptime: TimeInterval?
    var lastActivity: Date?

    init(status: DaemonStatus = .unknown, pid: Int? = nil, uptime: TimeInterval? = nil, lastActivity: Date? = nil) {
        self.status = status
        self.pid = pid
        self.uptime = uptime
        self.lastActivity = lastActivity
    }

    var uptimeString: String? {
        guard let uptime = uptime else { return nil }
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
