import SwiftUI

struct LogStatusMessage: View {
    let status: LogStatus
    let compact: Bool

    private var titleText: String {
        if !status.missingPaths.isEmpty {
            return "Logs not found"
        }
        return "No log data yet"
    }

    private var detailLines: [String] {
        var lines: [String] = []
        if !status.missingFileNames.isEmpty {
            lines.append("Missing: \(status.missingFileNames.joined(separator: ", "))")
        }
        if !status.emptyFileNames.isEmpty {
            lines.append("Empty: \(status.emptyFileNames.joined(separator: ", "))")
        }
        return lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(titleText)
                    .font(.system(size: compact ? 11 : 13, weight: .semibold))
            }

            ForEach(detailLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: compact ? 10 : 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(compact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(8)
    }
}
