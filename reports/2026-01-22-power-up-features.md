# Claudio Power-Up Features Report

Date: 2026-01-22
Priority: High
Type: Feature Enhancement

## Executive Summary

Transform Claudio from a voice transcription UI into a full voice AI agent platform. The current implementation uses `claude -p` (prompt-only mode) which limits Claude to just answering questions. These enhancements unlock Claude's agentic capabilities through voice.

## Feature 1: Screen Context Awareness

**Problem**: When users say "Claude, what's this error?" or "help me with what's on screen", Claude has no idea what they're looking at.

**Solution**: Add screenshot capture that can be sent with voice commands.

**Implementation**:
- Add `CLAUDIO_SCREEN_CONTEXT` setting (off, on-demand, always)
- "On-demand" triggers with phrases like "look at", "see this", "what's this"
- Capture screenshot via `screencapture -x /tmp/claudio-screen.png`
- Pass to Claude via `--image` flag or vision API
- Clean up temp files after use

**Acceptance Criteria**:
- Settings toggle for screen context mode
- Hook script detects context trigger phrases
- Screenshot captured and passed to Claude
- Works with both Claude CLI and API providers

## Feature 2: Agentic Execution Mode

**Problem**: The `-p` flag means Claude can only respond with text. It cannot run commands, edit files, or use MCP tools.

**Solution**: Add agentic mode that removes `-p` flag and allows tool use.

**Implementation**:
- Add `CLAUDIO_AGENTIC_MODE` setting (boolean)
- When enabled, use `claude --continue` without `-p`
- Add `CLAUDIO_ALLOWED_TOOLS` setting (comma-separated list or "all")
- Consider safety: require confirmation for destructive actions
- Log all tool executions for audit trail

**Acceptance Criteria**:
- Settings toggle for agentic mode
- Allowed tools configuration
- Hook script switches between prompt and agentic modes
- Tool executions logged to claude-hook.log

## Feature 3: Custom Wake Commands

**Problem**: All voice commands go through the same flow. Users can't have shortcuts for common actions.

**Solution**: Multiple wake words with different behaviors.

**Implementation**:
- Update brabble config to support multiple wake word hooks
- Add to Claudio settings UI:
  - "Claude" → Full conversation mode
  - "Dictate" → Transcribe-only to clipboard
  - "Screenshot" → Capture screen + send to Claude
  - "Quick" → Fast response using haiku model
  - "Agent" → Agentic mode with tool access
- Each wake word maps to a different hook or hook mode
- Settings UI to configure wake word behaviors

**Acceptance Criteria**:
- At least 4 configurable wake commands
- Settings UI shows wake word configuration
- Different wake words trigger different behaviors
- Wake word list syncs with brabble config

## Feature 4: MCP Tool Voice Access

**Problem**: Claude has access to powerful MCP tools (calendar, tasks, files) but voice commands can't use them.

**Solution**: Enable MCP tool access in voice mode.

**Implementation**:
- Agentic mode prerequisite
- Add `CLAUDIO_MCP_ENABLED` setting
- Configure which MCP servers are available to voice
- Common use cases:
  - "Add a task: buy groceries" → Things MCP
  - "What's on my calendar tomorrow?" → Calendar MCP
  - "Search my notes for X" → Relevant MCP
- Voice feedback for actions taken

**Acceptance Criteria**:
- MCP toggle in settings
- List of available MCP servers shown
- Voice commands can trigger MCP tools
- Confirmation spoken for actions taken

## Feature 5: Streaming Voice Response

**Problem**: Currently waits for full response before speaking. Long responses have awkward silence.

**Solution**: Stream response and speak as chunks arrive.

**Implementation**:
- For Claude CLI: pipe output through line-by-line reader
- Collect sentences/chunks and speak them incrementally
- Use `say` with background jobs for non-blocking
- Handle interruption gracefully (stop speaking on new wake word)
- Add `CLAUDIO_STREAMING_SPEECH` setting

**Acceptance Criteria**:
- Settings toggle for streaming speech
- Response spoken as it's generated
- No duplicate speaking of content
- Can be interrupted by new command

## Priority Order

1. **Screen Context** - Immediate usability win, relatively simple
2. **Agentic Mode** - Unlocks the real power
3. **Custom Wake Commands** - Better UX for common workflows
4. **MCP Tool Access** - Requires agentic mode first
5. **Streaming Response** - Polish/UX improvement

## Technical Notes

- All settings should write to `~/.config/claudio/hook-config.sh`
- Hook script must remain backward compatible
- Consider security implications of agentic mode
- Test with actual voice input, not just text

## Success Metrics

- Voice commands can take actions (not just answer questions)
- Screen context enables "what's this" workflows
- Reduced friction for common tasks via wake word shortcuts
- Users feel they have a capable assistant, not just dictation
