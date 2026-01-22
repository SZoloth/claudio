import Foundation
import SwiftUI

/// Status of a conversation turn's processing
enum TurnStatus: String, Codable {
    case pending     // Request sent, waiting for response
    case processing  // Claude is actively processing
    case completed   // Response received
    case failed      // Error occurred

    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .processing: return "sparkles"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

/// A single turn in a conversation (user request + Claude response)
struct ConversationTurn: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let userRequest: String
    var claudeResponse: String?
    var status: TurnStatus
    var responseTimestamp: Date?

    init(
        id: UUID = UUID(),
        timestamp: Date,
        userRequest: String,
        claudeResponse: String? = nil,
        status: TurnStatus = .pending,
        responseTimestamp: Date? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.userRequest = userRequest
        self.claudeResponse = claudeResponse
        self.status = status
        self.responseTimestamp = responseTimestamp
    }

    /// Relative time string for display
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    /// Duration between request and response
    var processingDuration: TimeInterval? {
        guard let responseTime = responseTimestamp else { return nil }
        return responseTime.timeIntervalSince(timestamp)
    }

    /// Formatted processing duration string
    var processingDurationString: String? {
        guard let duration = processingDuration else { return nil }
        if duration < 1 {
            return "<1s"
        } else if duration < 60 {
            return String(format: "%.0fs", duration)
        } else {
            return String(format: "%.1fm", duration / 60)
        }
    }
}
