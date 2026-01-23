# Claudio Backlog

## Bugs
- History window does not open from the menu bar (button only flips an unused flag; no `openWindow(id: "history")` call). Files: `Claudio/Views/MenuBarView.swift`, `Claudio/ViewModels/ClaudioViewModel.swift`.

## Security
- API key is written to `~/.config/claudio/hook-config.sh` and file permissions are set to `0o755`, making the secret world-readable. Tighten to `0o600` and consider removing plaintext export entirely. File: `Claudio/Services/SettingsWriter.swift`.

## Reliability
- File watcher may stop after log rotation/rename and double-close file descriptors (manual close + cancel handler). Reattach on `.rename`/`.delete` and let cancel handler own fd cleanup. File: `Claudio/Services/FileWatcherService.swift`.

## Performance
- Full log file reloads on every change. Replace with incremental parsing (track file offsets) and avoid duplicate watchers between view model and stats service. Files: `Claudio/ViewModels/ClaudioViewModel.swift`, `Claudio/Services/StatsService.swift`.
- Cursor blink timers are never invalidated and can accumulate. Use a timer with invalidation on disappear or a SwiftUI animation instead. Files: `Claudio/Views/TranscriptionView.swift`, `Claudio/Views/FloatingTranscriptionWindow.swift`.

## UX
- Add a visible state when log files are missing or empty (e.g., “Logs not found” and a link to create/locate). Views: menu bar popover and history.
- Provide quick actions in the popover (e.g., “Copy last response”, “Open log folder”).

## Capabilities
- Add export/share for sessions (markdown/text) and per-session copy.
- Optional: session tagging or pinning for quick access.
