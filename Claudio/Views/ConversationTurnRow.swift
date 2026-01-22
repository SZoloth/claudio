import SwiftUI

/// Row displaying a single conversation turn (user request + Claude response)
struct ConversationTurnRow: View {
    let turn: ConversationTurn

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // User request
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(turn.userRequest)
                        .font(.system(size: 13))
                        .lineLimit(2)
                }

                Spacer()
            }

            // Claude response or status indicator
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    switch turn.status {
                    case .pending, .processing:
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Processing...")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                    case .completed:
                        if let response = turn.claudeResponse {
                            Text(response)
                                .font(.system(size: 13))
                                .lineLimit(3)
                        }

                    case .failed:
                        Label("Failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }

                Spacer()
            }

            // Timestamp and duration
            HStack {
                Text(turn.relativeTimeString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                if let duration = turn.processingDurationString {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(duration)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: turn.status.icon)
                    .foregroundColor(turn.status.color)
                    .font(.system(size: 10))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

/// Compact row for conversation list
struct ConversationTurnCompactRow: View {
    let turn: ConversationTurn

    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            Circle()
                .fill(turn.status.color)
                .frame(width: 6, height: 6)

            // Request preview
            Text(turn.userRequest)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Timestamp
            Text(turn.relativeTimeString)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 12) {
        ConversationTurnRow(turn: ConversationTurn(
            timestamp: Date().addingTimeInterval(-120),
            userRequest: "What time is it?",
            claudeResponse: "It's **10:30 AM MST** on Thursday, January 22, 2026.",
            status: .completed,
            responseTimestamp: Date().addingTimeInterval(-105)
        ))

        ConversationTurnRow(turn: ConversationTurn(
            timestamp: Date().addingTimeInterval(-30),
            userRequest: "Tell me a joke about programming",
            status: .pending
        ))

        Divider()

        ConversationTurnCompactRow(turn: ConversationTurn(
            timestamp: Date().addingTimeInterval(-300),
            userRequest: "What's the weather like today?",
            claudeResponse: "It's sunny and 72°F.",
            status: .completed
        ))
    }
    .frame(width: 300)
    .padding()
}
