import SwiftUI

/// Live transcription display view
struct TranscriptionView: View {
    let text: String

    @State private var showCursor: Bool = true

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
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                showCursor.toggle()
            }
        }
    }
}
