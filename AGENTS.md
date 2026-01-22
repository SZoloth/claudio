# Claudio Agent Guidelines

## Overview
Claudio is a native macOS menu bar app that provides a visual UI for the brabble voice daemon. It monitors log files in real-time and displays transcriptions, processing status, and conversation history.

## Key Paths

### Brabble Logs
Location: `~/Library/Application Support/brabble/`
- `brabble.log` - daemon events (heard, wake word, hook execution)
- `transcripts.log` - all captured transcriptions
- `claude-hook.log` - request/response pairs from Claude hook

### Configuration
- `~/.config/brabble/config.toml` - brabble configuration
- `~/.claude/voice-sessions/` - voice session data

### Build Output
- `~/claudio/build/` - compiled app and derived data

## Log Formats

### brabble.log
```
time=2026-01-22T10:25:59.390-07:00 level=INFO msg="heard: \"Claude, what time is it?\""
time=2026-01-22T10:25:59.500-07:00 level=INFO msg="wake word detected"
time=2026-01-22T10:25:59.600-07:00 level=INFO msg="executing hook: brabble-claude-hook.sh"
```

### transcripts.log
```
2026-01-22T10:25:59.390-07:00 Claude, what time is it?
2026-01-22T10:30:12.100-07:00 Hey Claude, tell me a joke
```

### claude-hook.log
```
[2026-01-22 10:16:13] Received: what time is it?
[2026-01-22 10:16:29] Response: It's **10:16 AM MST** on Thursday, January 22, 2026.
```

## Architecture Patterns

### File Watching
Use `DispatchSource.makeFileSystemObjectSource` for file monitoring:
```swift
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: [.write, .extend, .rename, .delete],
    queue: queue
)
```
This is preferred over FSEvents for single-file monitoring.

### State Management
Use `@Observable` (macOS 14+) instead of `@ObservableObject`:
```swift
@Observable
final class ClaudioViewModel {
    var isProcessing = false  // No @Published needed
}
```

### Menu Bar App
- `MenuBarExtra` with `.menuBarExtraStyle(.window)` for popover UI
- `LSUIElement = YES` in Info.plist hides dock icon
- Separate `Window` scene for full history view

## SF Symbols
- `waveform` - audio/voice indicator
- `sparkles` - Claude/AI indicator
- `person.circle.fill` - user indicator
- Status indicators: `checkmark.circle.fill`, `exclamationmark.triangle.fill`, `clock`, `stop.circle.fill`

## Color Conventions
- **Green** - running/completed
- **Blue** - processing/user
- **Purple** - Claude/assistant
- **Orange** - pending/warning
- **Red** - error/failed
- **Gray** - stopped/inactive

## Build & Run

```bash
# Build
./build.sh
# or
xcodebuild -project Claudio.xcodeproj -scheme Claudio build

# Run
open build/Claudio.app

# Clean
rm -rf build/
```

## Testing Checklist
1. [ ] App shows in menu bar with waveform icon
2. [ ] No dock icon visible (LSUIElement working)
3. [ ] Popover opens on menu bar click
4. [ ] Status dot reflects daemon state
5. [ ] File changes trigger UI updates
6. [ ] Processing indicator animates when Claude is thinking
7. [ ] Cmd+Shift+H opens history window
8. [ ] Settings toggle for launch at login works

## Reference Projects
- `~/unwrapped` - existing SwiftUI project with MVVM patterns
- `~/agent-tools/brabble-claude-hook.sh` - the Claude hook script

## Common Issues

### File watcher not triggering
- Ensure the log file exists (created if missing)
- Check file descriptor is valid (fd >= 0)
- Verify debounce interval isn't too long

### Menu bar icon not appearing
- Check `LSUIElement` is set to `YES` in Info.plist
- Ensure `@main` attribute is on the App struct
- Verify `MenuBarExtra` is in the `body` of the App

### Daemon status always "stopped"
- Check PID file path matches brabble's output location
- Verify process check with `kill -0 <pid>` manually
- Look for stale PID files when daemon crashes
