import Foundation

/// Service that calculates session statistics from log files
final class StatsService {
    private let fileWatcher = FileWatcherService()
    private let claudeHookParser = ClaudeHookLogParser()
    private let transcriptParser = TranscriptLogParser()

    private var onStatsUpdated: ((SessionStats) -> Void)?

    /// Current stats (computed on demand)
    func calculateCurrentStats() -> SessionStats {
        let today = Calendar.current.startOfDay(for: Date())

        // Parse transcriptions for today
        let transcriptions = transcriptParser.parseLogFile(at: Constants.transcriptsLogPath)
        let todayTranscriptions = transcriptions.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }

        // Parse conversations for today
        let turns = claudeHookParser.parseLogFile(at: Constants.claudeHookLogPath)
        let todayTurns = turns.filter {
            Calendar.current.isDate($0.timestamp, inSameDayAs: today)
        }

        // Calculate response times from completed turns
        let responseTimes = todayTurns.compactMap { $0.processingDuration }

        // Count requests and responses
        let requestCount = todayTurns.count
        let responseCount = todayTurns.filter { $0.status == .completed }.count

        // Parse brabble log for error/warning counts
        let (overflowCount, noSpeechCount, errorCount) = countBrabbleIssues(for: today)

        return SessionStats(
            transcriptionCount: todayTranscriptions.count,
            requestCount: requestCount,
            responseCount: responseCount,
            overflowCount: overflowCount,
            noSpeechCount: noSpeechCount,
            errorCount: errorCount,
            responseTimes: responseTimes
        )
    }

    /// Start watching logs and call handler when stats update
    func startWatching(onUpdate: @escaping (SessionStats) -> Void) {
        self.onStatsUpdated = onUpdate

        // Watch all relevant log files
        fileWatcher.watch(Constants.claudeHookLogPath) { [weak self] in
            self?.notifyUpdate()
        }

        fileWatcher.watch(Constants.transcriptsLogPath) { [weak self] in
            self?.notifyUpdate()
        }

        fileWatcher.watch(Constants.brabbleLogPath) { [weak self] in
            self?.notifyUpdate()
        }

        // Initial calculation
        notifyUpdate()
    }

    func stopWatching() {
        fileWatcher.stopAll()
        onStatsUpdated = nil
    }

    // MARK: - Private

    private func notifyUpdate() {
        let stats = calculateCurrentStats()
        onStatsUpdated?(stats)
    }

    /// Count overflow, no speech, and error events from brabble log for today
    private func countBrabbleIssues(for today: Date) -> (overflow: Int, noSpeech: Int, errors: Int) {
        guard let content = try? String(contentsOf: Constants.brabbleLogPath, encoding: .utf8) else {
            return (0, 0, 0)
        }

        let todayString = formatDateForLogMatching(today)
        let lines = content.components(separatedBy: .newlines)

        var overflowCount = 0
        var noSpeechCount = 0
        var errorCount = 0

        for line in lines {
            // Check if line is from today
            guard line.contains(todayString) else { continue }

            // Count patterns (matching claudio-report.sh grep patterns)
            if line.contains("input overflow") {
                overflowCount += 1
            }
            if line.contains("no speech detected") {
                noSpeechCount += 1
            }
            if line.contains("level=ERROR") {
                errorCount += 1
            }
        }

        return (overflowCount, noSpeechCount, errorCount)
    }

    /// Format date to match log timestamp format (YYYY-MM-DD)
    private func formatDateForLogMatching(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
