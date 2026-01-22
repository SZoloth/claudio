# Claudio

A native macOS menu bar app for the [brabble](https://github.com/steipete/brabble) voice daemon.

## Features

- **Live Transcriptions** - See what brabble hears in real-time
- **Processing Indicator** - Visual feedback when Claude is thinking
- **Wake Word Display** - Shows configured wake word(s) from brabble config
- **Multi-Turn Sessions** - Conversations grouped by time proximity
- **Conversation History** - Review past voice interactions with search/filter
- **Daemon Status** - Monitor brabble's health at a glance

## Requirements

- macOS 14.0 (Sonoma) or later
- [brabble](https://github.com/steipete/brabble) voice daemon installed and running

## Installation

### Build from Source

```bash
cd ~/claudio
./build.sh
open build/Claudio.app
```

Or open `Claudio.xcodeproj` in Xcode and build.

## Usage

1. **Start brabble** - Ensure the voice daemon is running
2. **Launch Claudio** - Click the waveform icon in your menu bar
3. **Talk to Claude** - Say "Claude, ..." and watch the UI update

### Menu Bar Icon

| Status | Color | Meaning |
|--------|-------|---------|
| 🟢 | Green | brabble running |
| 🔵 | Blue (pulsing) | Claude processing |
| ⚪ | Gray | brabble stopped |
| 🟠 | Orange | Unknown status |
| 🔴 | Red | Error |

### Keyboard Shortcuts

- **Cmd+Shift+H** - Open conversation history window
- **Cmd+,** - Open settings

## Architecture

```
Claudio/
├── App/           # @main entry point
├── Models/        # Data structures
├── ViewModels/    # @Observable state
├── Services/      # File watching, parsing
└── Views/         # SwiftUI components
```

### Log Files Monitored

- `~/Library/Application Support/brabble/brabble.log`
- `~/Library/Application Support/brabble/transcripts.log`
- `~/Library/Application Support/brabble/claude-hook.log`

## Development

```bash
# Build
xcodebuild -project Claudio.xcodeproj -scheme Claudio build

# Run ralph for task management
./scripts/ralph/ralph.sh --tool claude 20
```

## License

MIT
