import Foundation

/// A single transcription captured by brabble
struct Transcription: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let text: String
    let isWakeWordTriggered: Bool

    init(id: UUID = UUID(), timestamp: Date, text: String, isWakeWordTriggered: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
        self.isWakeWordTriggered = isWakeWordTriggered
    }

    /// Relative time string for display (e.g., "2m ago", "Just now")
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
