import SwiftUI

/// Live transcription display view
struct TranscriptionView: View {
    let text: String

    @State private var showCursor: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.system(size: 13))

            // Blinking cursor
            Rectangle()
                .fill(Color.primary)
                .frame(width: 2, height: 14)
                .opacity(showCursor ? 1 : 0)
        }
        .onAppear {
            startCursorBlink()
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                showCursor.toggle()
            }
        }
    }
}
