import Foundation

struct LogStatus: Equatable {
    let missingPaths: [URL]
    let emptyPaths: [URL]
    let lastActivity: Date?

    var hasIssues: Bool {
        !missingPaths.isEmpty || !emptyPaths.isEmpty
    }

    var missingFileNames: [String] {
        missingPaths.map { $0.lastPathComponent }
    }

    var emptyFileNames: [String] {
        emptyPaths.map { $0.lastPathComponent }
    }

    static let empty = LogStatus(missingPaths: [], emptyPaths: [], lastActivity: nil)
}
