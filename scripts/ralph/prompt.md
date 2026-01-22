# Claudio Development Context

## Project Overview
Claudio is a native macOS menu bar app that provides a UI for the brabble voice daemon. It shows live transcriptions, processing indicators, and conversation history.

## Tech Stack
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI with @Observable (macOS 14+)
- **Architecture**: MVVM
- **Build System**: Xcode / xcodebuild

## Key Patterns

### File Watching
Use DispatchSource for file monitoring:
```swift
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: [.write, .extend],
    queue: queue
)
```

### Menu Bar App
- Use `MenuBarExtra` scene with `.menuBarExtraStyle(.window)` for popover
- Set `LSUIElement = YES` in Info.plist to hide dock icon

### State Management
- Use `@Observable` (not `@ObservableObject`) for iOS 17+/macOS 14+
- Wire file watchers to update @Observable properties

## Log File Formats

### brabble.log
```
time=2026-01-22T10:25:59.390-07:00 level=INFO msg="heard: \"Claude, what time is it?\""
```

### transcripts.log
```
2026-01-22T10:25:59.390-07:00 What time is it?
```

### claude-hook.log
```
[2026-01-22 10:16:13] Received: what time is it?
[2026-01-22 10:16:29] Response: It's **10:16 AM MST**...
```

## File Paths
- Logs: `~/Library/Application Support/brabble/`
- Config: `~/.config/brabble/config.toml`
- Voice sessions: `~/.claude/voice-sessions/`

## Build Commands
```bash
# Build
xcodebuild -project Claudio.xcodeproj -scheme Claudio build

# Run
open build/Claudio.app

# Clean
xcodebuild clean
```

## Testing
1. Launch app - verify menu bar icon appears
2. Check daemon status indicator
3. Test with brabble: say "Claude, ..." and verify UI updates
4. Test Cmd+Shift+H for history window
