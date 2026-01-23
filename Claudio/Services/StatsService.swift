import Foundation

struct BrabbleIssueCounts: Equatable {
    var overflowCount: Int = 0
    var noSpeechCount: Int = 0
    var errorCount: Int = 0
}

/// Service that calculates session statistics from in-memory data
final class StatsService {
    /// Current stats (computed on demand)
    func calculateStats(
        transcriptions: [Transcription],
        turns: [ConversationTurn],
        issueCounts: BrabbleIssueCounts
    ) -> SessionStats {
        let today = Calendar.current.startOfDay(for: Date())

        let todayTranscriptions = transcriptions.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }

        let todayTurns = turns.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }

        let responseTimes = todayTurns.compactMap { $0.processingDuration }
        let requestCount = todayTurns.count
        let responseCount = todayTurns.filter { $0.status == .completed }.count

        return SessionStats(
            transcriptionCount: todayTranscriptions.count,
            requestCount: requestCount,
            responseCount: responseCount,
            overflowCount: issueCounts.overflowCount,
            noSpeechCount: issueCounts.noSpeechCount,
            errorCount: issueCounts.errorCount,
            responseTimes: responseTimes
        )
    }
}
