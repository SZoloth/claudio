import Foundation

/// Service for checking daemon process status
final class ProcessRunner {
    /// Check if brabble daemon is running by checking PID file
    func checkBrabbleStatus() -> DaemonInfo {
        let pidFile = Constants.pidFilePath

        // Check if PID file exists
        guard FileManager.default.fileExists(atPath: pidFile.path),
              let pidString = try? String(contentsOf: pidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = Int(pidString) else {
            return DaemonInfo(status: .stopped)
        }

        // Check if process is running
        if isProcessRunning(pid: pid) {
            // Get process start time for uptime calculation
            let uptime = getProcessUptime(pid: pid)
            let lastActivity = getLastLogActivity()

            return DaemonInfo(
                status: .running,
                pid: pid,
                uptime: uptime,
                lastActivity: lastActivity
            )
        } else {
            // PID file exists but process is not running - stale PID file
            return DaemonInfo(status: .stopped)
        }
    }

    /// Check if a process with given PID is running
    func isProcessRunning(pid: Int) -> Bool {
        // kill with signal 0 just checks if process exists
        let result = kill(Int32(pid), 0)
        return result == 0
    }

    /// Get process uptime by checking /proc or using ps
    func getProcessUptime(pid: Int) -> TimeInterval? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-o", "etime=", "-p", String(pid)]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !output.isEmpty else {
                return nil
            }

            return parseElapsedTime(output)
        } catch {
            return nil
        }
    }

    /// Parse elapsed time format from ps (e.g., "01:23:45" or "1-01:23:45")
    private func parseElapsedTime(_ string: String) -> TimeInterval? {
        let components = string.components(separatedBy: ":")

        switch components.count {
        case 2:
            // MM:SS
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else { return nil }
            return minutes * 60 + seconds

        case 3:
            // HH:MM:SS or D-HH:MM:SS
            var hours: Double = 0
            var hoursString = components[0]

            // Check for days
            if hoursString.contains("-") {
                let dayParts = hoursString.components(separatedBy: "-")
                guard dayParts.count == 2,
                      let days = Double(dayParts[0]) else { return nil }
                hours = days * 24
                hoursString = dayParts[1]
            }

            guard let h = Double(hoursString),
                  let minutes = Double(components[1]),
                  let seconds = Double(components[2]) else { return nil }

            return (hours + h) * 3600 + minutes * 60 + seconds

        default:
            return nil
        }
    }

    /// Get the timestamp of the last log file modification
    func getLastLogActivity() -> Date? {
        let logFiles = [
            Constants.brabbleLogPath,
            Constants.transcriptsLogPath,
            Constants.claudeHookLogPath
        ]

        var latestDate: Date?

        for logFile in logFiles {
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: logFile.path),
                  let modDate = attributes[.modificationDate] as? Date else {
                continue
            }

            if latestDate == nil || modDate > latestDate! {
                latestDate = modDate
            }
        }

        return latestDate
    }

    /// Run a shell command and return output
    func runCommand(_ command: String, arguments: [String] = []) -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            return (output, process.terminationStatus)
        } catch {
            return ("", -1)
        }
    }
}
