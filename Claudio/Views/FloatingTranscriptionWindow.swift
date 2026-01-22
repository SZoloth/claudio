import SwiftUI
import AppKit

/// Manages a floating panel window for live transcription
@MainActor
final class TranscriptionPanelController {
    static let shared = TranscriptionPanelController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    private init() {}

    func show(text: String) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        // Update content
        hostingView?.rootView = AnyView(TranscriptionPanelContent(text: text))

        // Position near top center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 500
            let windowHeight: CGFloat = 60
            let x = screenFrame.midX - windowWidth / 2
            let y = screenFrame.maxY - windowHeight - 20
            panel.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 60),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        let hostingView = NSHostingView(rootView: AnyView(TranscriptionPanelContent(text: "")))
        panel.contentView = hostingView
        self.hostingView = hostingView
        self.panel = panel
    }
}

/// Content view for the floating transcription panel
struct TranscriptionPanelContent: View {
    let text: String
    @State private var showCursor = true

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform")
                .font(.system(size: 14))
                .foregroundStyle(.blue)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Rectangle()
                .fill(Color.primary)
                .frame(width: 2, height: 16)
                .opacity(showCursor ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        )
        .padding(6)
        .onAppear {
            startCursorAnimation()
        }
    }

    private func startCursorAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                showCursor.toggle()
            }
        }
    }
}
