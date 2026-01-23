import Foundation

struct LogTailState {
    var offset: UInt64 = 0
    var remainder: String = ""
}

struct LogTailReadResult {
    let lines: [String]
    let didReset: Bool
}

enum LogTailReader {
    static func syncToEOF(of url: URL, state: inout LogTailState) {
        state.offset = fileSize(of: url)
        state.remainder = ""
    }

    static func readNewLines(from url: URL, state: inout LogTailState) -> LogTailReadResult {
        guard FileManager.default.fileExists(atPath: url.path) else {
            state = LogTailState()
            return LogTailReadResult(lines: [], didReset: true)
        }

        let size = fileSize(of: url)
        var didReset = false
        if size < state.offset {
            state.offset = 0
            state.remainder = ""
            didReset = true
        }

        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return LogTailReadResult(lines: [], didReset: didReset)
        }

        do {
            try handle.seek(toOffset: state.offset)
        } catch {
            try? handle.close()
            return LogTailReadResult(lines: [], didReset: didReset)
        }

        let data = handle.readDataToEndOfFile()
        try? handle.close()
        state.offset = size

        guard var chunk = String(data: data, encoding: .utf8), !chunk.isEmpty else {
            return LogTailReadResult(lines: [], didReset: didReset)
        }

        if !state.remainder.isEmpty {
            chunk = state.remainder + chunk
            state.remainder = ""
        }

        var lines = chunk.components(separatedBy: .newlines)
        if !chunk.hasSuffix("\n"), let last = lines.popLast() {
            state.remainder = last
        }

        let trimmedLines = lines.filter { !$0.isEmpty }
        return LogTailReadResult(lines: trimmedLines, didReset: didReset)
    }

    private static func fileSize(of url: URL) -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? UInt64 ?? 0
    }
}
