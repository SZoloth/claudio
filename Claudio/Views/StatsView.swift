import SwiftUI

/// Collapsible stats view showing today's metrics
struct StatsView: View {
    let stats: SessionStats
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    // Health indicator
                    Circle()
                        .fill(stats.healthStatus.color)
                        .frame(width: 8, height: 8)

                    Text("Today's Stats")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    // Quick summary when collapsed
                    if !isExpanded {
                        HStack(spacing: 6) {
                            Text(stats.successRateString)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                            if let avgTime = stats.averageResponseTimeString {
                                Text("•")
                                Text(avgTime)
                                    .font(.system(size: 10, design: .monospaced))
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Expanded details
            if isExpanded {
                StatsDetailView(stats: stats)
                    .padding(.top, 4)
            }
        }
    }
}

/// Detailed stats breakdown
struct StatsDetailView: View {
    let stats: SessionStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Health status row
            HStack {
                Image(systemName: stats.healthStatus.icon)
                    .foregroundColor(stats.healthStatus.color)
                    .font(.system(size: 12))
                Text(stats.healthStatus.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(stats.healthStatus.color)
                Spacer()
            }
            .padding(.horizontal, 8)

            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                StatItem(label: "Transcriptions", value: "\(stats.transcriptionCount)")
                StatItem(label: "Success Rate", value: stats.successRateString)
                StatItem(label: "Avg Response", value: stats.averageResponseTimeString ?? "—")
                StatItem(label: "Requests", value: "\(stats.requestCount)")
            }
            .padding(.horizontal, 8)

            // Warnings section (if any)
            if stats.warningCount > 0 {
                Divider()
                    .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 10))
                        Text("Warnings")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.orange)

                    HStack(spacing: 12) {
                        if stats.overflowCount > 0 {
                            WarningItem(label: "Overflow", count: stats.overflowCount)
                        }
                        if stats.noSpeechCount > 0 {
                            WarningItem(label: "No speech", count: stats.noSpeechCount)
                        }
                        if stats.errorCount > 0 {
                            WarningItem(label: "Errors", count: stats.errorCount)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

/// Single stat item
struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Warning count item
struct WarningItem: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundColor(.secondary)
    }
}

#Preview {
    let sampleStats = SessionStats(
        transcriptionCount: 15,
        requestCount: 8,
        responseCount: 7,
        overflowCount: 45,
        noSpeechCount: 23,
        errorCount: 0,
        responseTimes: [14.5, 16.2, 18.1, 15.8, 17.0]
    )
    return StatsView(stats: sampleStats)
        .frame(width: 300)
        .padding()
}
