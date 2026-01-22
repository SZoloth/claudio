import Foundation
import SwiftUI

/// Health status based on success rate
enum HealthStatus {
    case good      // >90% success
    case warning   // 70-90% success
    case poor      // <70% success
    case unknown   // no data

    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .good: return "Healthy"
        case .warning: return "Warning"
        case .poor: return "Issues"
        case .unknown: return "No data"
        }
    }
}

/// Aggregated session statistics for today
struct SessionStats {
    let transcriptionCount: Int
    let requestCount: Int
    let responseCount: Int
    let overflowCount: Int
    let noSpeechCount: Int
    let errorCount: Int
    let responseTimes: [TimeInterval]

    /// Success rate as a percentage (0-100)
    var successRate: Double {
        guard requestCount > 0 else { return 0 }
        return Double(responseCount) / Double(requestCount) * 100
    }

    /// Formatted success rate string
    var successRateString: String {
        String(format: "%.0f%%", successRate)
    }

    /// Average response time in seconds
    var averageResponseTime: TimeInterval? {
        guard !responseTimes.isEmpty else { return nil }
        return responseTimes.reduce(0, +) / Double(responseTimes.count)
    }

    /// Formatted average response time
    var averageResponseTimeString: String? {
        guard let avg = averageResponseTime else { return nil }
        return String(format: "%.1fs", avg)
    }

    /// Minimum response time
    var minResponseTime: TimeInterval? {
        responseTimes.min()
    }

    /// Maximum response time
    var maxResponseTime: TimeInterval? {
        responseTimes.max()
    }

    /// Health status based on success rate
    var healthStatus: HealthStatus {
        guard requestCount > 0 else { return .unknown }
        if successRate >= 90 { return .good }
        if successRate >= 70 { return .warning }
        return .poor
    }

    /// Total warning count (overflow + no speech)
    var warningCount: Int {
        overflowCount + noSpeechCount
    }

    /// Empty stats instance
    static let empty = SessionStats(
        transcriptionCount: 0,
        requestCount: 0,
        responseCount: 0,
        overflowCount: 0,
        noSpeechCount: 0,
        errorCount: 0,
        responseTimes: []
    )
}
