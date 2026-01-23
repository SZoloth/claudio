import SwiftUI

/// Animated status indicator dot
struct StatusIndicator: View {
    let status: DaemonStatus
    let isProcessing: Bool
    var size: CGFloat = 8

    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(displayColor)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing && isProcessing ? 1.3 : 1.0)
            .animation(
                isProcessing ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = isProcessing
            }
            .onChange(of: isProcessing) { _, newValue in
                isPulsing = newValue
            }
    }

    private var displayColor: Color {
        if isProcessing {
            return .blue
        }
        return status.color
    }
}

/// Menu bar label with icon and status dot
struct MenuBarLabel: View {
    let status: DaemonStatus
    let isProcessing: Bool

    var body: some View {
        HStack(spacing: 3) {
            Text("🦞")
                .font(.system(size: 14))

            StatusIndicator(status: status, isProcessing: isProcessing, size: 6)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            StatusIndicator(status: .running, isProcessing: false)
            StatusIndicator(status: .stopped, isProcessing: false)
            StatusIndicator(status: .error, isProcessing: false)
            StatusIndicator(status: .unknown, isProcessing: false)
        }

        StatusIndicator(status: .running, isProcessing: true, size: 12)

        MenuBarLabel(status: .running, isProcessing: false)
        MenuBarLabel(status: .running, isProcessing: true)
    }
    .padding()
}
