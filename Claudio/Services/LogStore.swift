import Foundation

final class LogStore {
    struct Snapshot {
        let transcriptions: [Transcription]
        let turns: [ConversationTurn]
        let sessions: [ConversationSession]
        let isProcessing: Bool
        let stats: SessionStats
        let logStatus: LogStatus
    }

    var onSnapshotUpdate: ((Snapshot) -> Void)?
    var onBrabbleEvents: (([BrabbleEvent]) -> Void)?

    private let fileWatcher = FileWatcherService()
    private let transcriptParser = TranscriptLogParser()
    private let hookParser = ClaudeHookLogParser()
    private let brabbleParser = BrabbleLogParser()
    private let statsService = StatsService()

    private var transcriptions: [Transcription] = []
    private var turns: [ConversationTurn] = []
    private var transcriptionsToday: [Transcription] = []
    private var turnsToday: [ConversationTurn] = []
    private var issueCounts = BrabbleIssueCounts()
    private var pendingRequest: ClaudeHookEntry?
    private var pendingTurnIndex: Int?
    private var pendingTurnIndexToday: Int?
    private var transcriptTail = LogTailState()
    private var hookTail = LogTailState()
    private var brabbleTail = LogTailState()
    private var currentDay = Calendar.current.startOfDay(for: Date())
    private var logStatus: LogStatus = .empty

    func start() {
        loadInitialData()
        setupWatchers()
    }

    func stop() {
        fileWatcher.stopAll()
    }

    // MARK: - Setup

    private func loadInitialData() {
        let allTranscriptions = transcriptParser.parseLogFile(at: Constants.transcriptsLogPath)
        transcriptionsToday = allTranscriptions.filter { isInCurrentDay($0.timestamp) }
        transcriptions = Array(allTranscriptions.suffix(Constants.maxRecentTranscriptions))

        let allTurns = hookParser.parseLogFile(at: Constants.claudeHookLogPath)
        turnsToday = allTurns.filter { isInCurrentDay($0.timestamp) }
        turns = Array(allTurns.suffix(Constants.maxRecentTurns))

        if let pending = allTurns.last,
           pending.status == .pending,
           let index = turns.lastIndex(where: { $0.id == pending.id }) {
            pendingRequest = ClaudeHookEntry(timestamp: pending.timestamp, type: .received, content: pending.userRequest)
            pendingTurnIndex = index
            pendingTurnIndexToday = turnsToday.lastIndex(where: { $0.id == pending.id })
        }

        issueCounts = countBrabbleIssues(for: currentDay)
        logStatus = computeLogStatus()

        LogTailReader.syncToEOF(of: Constants.transcriptsLogPath, state: &transcriptTail)
        LogTailReader.syncToEOF(of: Constants.claudeHookLogPath, state: &hookTail)
        LogTailReader.syncToEOF(of: Constants.brabbleLogPath, state: &brabbleTail)

        publishSnapshot()
    }

    private func setupWatchers() {
        fileWatcher.watch(Constants.transcriptsLogPath) { [weak self] in
            self?.handleTranscriptsChanged()
        }

        fileWatcher.watch(Constants.claudeHookLogPath) { [weak self] in
            self?.handleHookLogChanged()
        }

        fileWatcher.watch(Constants.brabbleLogPath) { [weak self] in
            self?.handleBrabbleLogChanged()
        }
    }

    // MARK: - Handlers

    private func handleTranscriptsChanged() {
        let result = LogTailReader.readNewLines(from: Constants.transcriptsLogPath, state: &transcriptTail)
        if result.didReset {
            transcriptions.removeAll()
            transcriptionsToday.removeAll()
        }

        let newTranscriptions = result.lines.compactMap { transcriptParser.parseLine($0) }
        for transcription in newTranscriptions {
            appendTranscription(transcription)
        }

        trimTranscriptions()
        logStatus = computeLogStatus()
        publishSnapshot()
    }

    private func handleHookLogChanged() {
        let result = LogTailReader.readNewLines(from: Constants.claudeHookLogPath, state: &hookTail)
        if result.didReset {
            resetTurnsState()
        }

        let entries = result.lines.compactMap { hookParser.parseLine($0) }
        if !entries.isEmpty {
            processHookEntries(entries)
        }

        trimTurns()
        logStatus = computeLogStatus()
        publishSnapshot()
    }

    private func handleBrabbleLogChanged() {
        let result = LogTailReader.readNewLines(from: Constants.brabbleLogPath, state: &brabbleTail)
        if result.didReset {
            issueCounts = BrabbleIssueCounts()
        }

        let events = result.lines.compactMap { brabbleParser.parseLine($0) }
        if !events.isEmpty {
            updateIssueCounts(from: events)
            onBrabbleEvents?(events)
        }

        logStatus = computeLogStatus()
        publishSnapshot()
    }

    // MARK: - Turns

    private func processHookEntries(_ entries: [ClaudeHookEntry]) {
        for entry in entries {
            switch entry.type {
            case .received:
                if pendingRequest != nil {
                    markPendingAsFailed()
                }
                pendingRequest = entry
                let turn = ConversationTurn(
                    timestamp: entry.timestamp,
                    userRequest: entry.content,
                    status: .pending
                )
                appendTurn(turn, isPending: true)

            case .response:
                if pendingRequest != nil {
                    completePendingTurn(with: entry)
                    pendingRequest = nil
                }
            }
        }
    }

    private func appendTurn(_ turn: ConversationTurn, isPending: Bool) {
        updateDayIfNeeded(for: turn.timestamp)

        turns.append(turn)
        if turns.count > Constants.maxRecentTurns {
            turns.removeFirst(turns.count - Constants.maxRecentTurns)
        }

        if isInCurrentDay(turn.timestamp) {
            turnsToday.append(turn)
            if isPending {
                pendingTurnIndexToday = turnsToday.count - 1
            }
        }

        if isPending {
            pendingTurnIndex = turns.count - 1
        }
    }

    private func markPendingAsFailed() {
        if let index = pendingTurnIndex, turns.indices.contains(index) {
            turns[index].status = .failed
        }
        if let index = pendingTurnIndexToday, turnsToday.indices.contains(index) {
            turnsToday[index].status = .failed
        }
        pendingTurnIndex = nil
        pendingTurnIndexToday = nil
    }

    private func completePendingTurn(with response: ClaudeHookEntry) {
        if let index = pendingTurnIndex, turns.indices.contains(index) {
            var turn = turns[index]
            turn.status = .completed
            turn.claudeResponse = response.content
            turn.responseTimestamp = response.timestamp
            turns[index] = turn
        }

        if let index = pendingTurnIndexToday, turnsToday.indices.contains(index) {
            var turn = turnsToday[index]
            turn.status = .completed
            turn.claudeResponse = response.content
            turn.responseTimestamp = response.timestamp
            turnsToday[index] = turn
        }

        pendingTurnIndex = nil
        pendingTurnIndexToday = nil
    }

    private func resetTurnsState() {
        turns.removeAll()
        turnsToday.removeAll()
        pendingRequest = nil
        pendingTurnIndex = nil
        pendingTurnIndexToday = nil
    }

    private func trimTurns() {
        if turns.count > Constants.maxRecentTurns {
            turns.removeFirst(turns.count - Constants.maxRecentTurns)
        }
    }

    // MARK: - Transcriptions

    private func appendTranscription(_ transcription: Transcription) {
        updateDayIfNeeded(for: transcription.timestamp)

        transcriptions.append(transcription)
        if transcriptions.count > Constants.maxRecentTranscriptions {
            transcriptions.removeFirst(transcriptions.count - Constants.maxRecentTranscriptions)
        }

        if isInCurrentDay(transcription.timestamp) {
            transcriptionsToday.append(transcription)
        }
    }

    private func trimTranscriptions() {
        if transcriptions.count > Constants.maxRecentTranscriptions {
            transcriptions.removeFirst(transcriptions.count - Constants.maxRecentTranscriptions)
        }
    }

    // MARK: - Stats

    private func updateIssueCounts(from events: [BrabbleEvent]) {
        for event in events {
            let timestamp: Date
            let message: String?
            let isError: Bool

            switch event {
            case .error(let msg, let date):
                timestamp = date
                message = msg
                isError = true
            case .info(let msg, let date):
                timestamp = date
                message = msg
                isError = false
            default:
                continue
            }

            updateDayIfNeeded(for: timestamp)

            guard isInCurrentDay(timestamp) else { continue }
            if isError {
                issueCounts.errorCount += 1
            }

            guard let message else { continue }
            if message.contains("input overflow") {
                issueCounts.overflowCount += 1
            }
            if message.contains("no speech detected") {
                issueCounts.noSpeechCount += 1
            }
        }
    }

    // MARK: - Utilities

    private func publishSnapshot() {
        let sessions = ConversationSession.groupTurnsIntoSessions(turns)
        let stats = statsService.calculateStats(
            transcriptions: transcriptionsToday,
            turns: turnsToday,
            issueCounts: issueCounts
        )

        let snapshot = Snapshot(
            transcriptions: transcriptions,
            turns: turns,
            sessions: sessions,
            isProcessing: pendingRequest != nil || turns.last?.status == .pending || turns.last?.status == .processing,
            stats: stats,
            logStatus: logStatus
        )

        onSnapshotUpdate?(snapshot)
    }

    private func updateDayIfNeeded(for date: Date) {
        if !Calendar.current.isDate(date, inSameDayAs: currentDay) {
            currentDay = Calendar.current.startOfDay(for: date)
            transcriptionsToday.removeAll()
            turnsToday.removeAll()
            issueCounts = BrabbleIssueCounts()
            pendingTurnIndexToday = nil
        }
    }

    private func isInCurrentDay(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: currentDay)
    }

    private func computeLogStatus() -> LogStatus {
        let paths = [
            Constants.transcriptsLogPath,
            Constants.claudeHookLogPath,
            Constants.brabbleLogPath
        ]

        var missing: [URL] = []
        var empty: [URL] = []
        var latestActivity: Date?

        for path in paths {
            if !FileManager.default.fileExists(atPath: path.path) {
                missing.append(path)
                continue
            }

            let attributes = try? FileManager.default.attributesOfItem(atPath: path.path)
            let size = attributes?[.size] as? UInt64 ?? 0
            if size == 0 {
                empty.append(path)
            }

            if let modDate = attributes?[.modificationDate] as? Date {
                if latestActivity == nil || modDate > latestActivity! {
                    latestActivity = modDate
                }
            }
        }

        return LogStatus(missingPaths: missing, emptyPaths: empty, lastActivity: latestActivity)
    }

    private func countBrabbleIssues(for day: Date) -> BrabbleIssueCounts {
        guard let content = try? String(contentsOf: Constants.brabbleLogPath, encoding: .utf8) else {
            return BrabbleIssueCounts()
        }

        let dateString = formatDateForLogMatching(day)
        let lines = content.components(separatedBy: .newlines)

        var counts = BrabbleIssueCounts()
        for line in lines {
            guard line.contains(dateString) else { continue }
            if line.contains("input overflow") {
                counts.overflowCount += 1
            }
            if line.contains("no speech detected") {
                counts.noSpeechCount += 1
            }
            if line.contains("level=ERROR") {
                counts.errorCount += 1
            }
        }

        return counts
    }

    private func formatDateForLogMatching(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
