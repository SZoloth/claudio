import SwiftUI

/// Live transcription display view
struct TranscriptionView: View {
    let text: String

    @State private var showCursor: Bool = true
    @State private var cursorTimer: Timer?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)

            // Blinking cursor
            Rectangle()
                .fill(Color.primary)
                .frame(width: 2, height: 14)
                .opacity(showCursor ? 1 : 0)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .onAppear {
            startCursorBlink()
        }
        .onDisappear {
            stopCursorBlink()
        }
    }

    private func startCursorBlink() {
        cursorTimer?.invalidate()
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                showCursor.toggle()
            }
        }
    }

    private func stopCursorBlink() {
        cursorTimer?.invalidate()
        cursorTimer = nil
    }
}

/// Shows truncated previous transcription text
struct PreviousTranscriptionIndicator: View {
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Text("Previous:")
                .font(.system(size: 11, weight: .medium))

            Text(truncatedText)
                .font(.system(size: 11))
                .lineLimit(1)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var truncatedText: String {
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
}
