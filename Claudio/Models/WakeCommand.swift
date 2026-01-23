import Foundation

/// A custom wake command that triggers specific Claude behaviors
struct WakeCommand: Identifiable, Codable, Equatable {
    let id: UUID
    var trigger: String      // Phrase to match in transcription
    var action: String       // Instruction to prepend to prompt
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        trigger: String,
        action: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.trigger = trigger
        self.action = action
        self.isEnabled = isEnabled
    }

    /// Check if this command matches the given transcription
    func matches(_ transcription: String) -> Bool {
        guard isEnabled else { return false }
        let lowerTranscription = transcription.lowercased()
        let lowerTrigger = trigger.lowercased()
        return lowerTranscription.contains(lowerTrigger)
    }

    /// Default wake commands
    static var defaults: [WakeCommand] {
        [
            WakeCommand(
                trigger: "summarize this",
                action: "Please provide a concise summary of the following:"
            ),
            WakeCommand(
                trigger: "explain this",
                action: "Please explain the following in simple terms:"
            ),
            WakeCommand(
                trigger: "fix this",
                action: "Please identify and fix any issues with the following:"
            ),
            WakeCommand(
                trigger: "review this",
                action: "Please provide a thorough code review of the following:"
            )
        ]
    }
}
