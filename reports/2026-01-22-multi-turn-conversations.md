# Feature: Multi-Turn Voice Conversations

**Date**: 2026-01-22
**Priority**: High
**Requester**: User

## Problem

Currently each voice request is a single-shot `claude -p` call with no conversation memory. Users want ongoing back-and-forth conversations that maintain context.

## Current Flow

```
Wake word → Transcribe → claude -p "$text" → Speak response → Done
```

Each request is independent. No conversation continuity.

## Desired Flow

```
Wake word → Transcribe → Add to conversation → Claude responds with context → Speak
           ↑                                                                    |
           └────────────────── Continue until timeout ──────────────────────────┘
```

## Technical Approach

Claude Code supports conversation resumption:
- `--continue` - resumes most recent conversation in current directory
- `--resume <session_id>` - resumes specific session
- `--session-id <uuid>` - use explicit session ID

### Proposed Implementation

1. **Session tracking**: Store active session ID in `~/.config/brabble/active-session`
2. **Time-based continuity**: If last interaction < 2 minutes ago, continue session
3. **Hook script changes**:
   - Check if active session exists and is recent
   - If yes: `claude --resume $SESSION_ID -p "$text"`
   - If no: `claude -p "$text"` and capture new session ID
4. **Explicit commands**: "new conversation" voice command resets session

### Alternative: Different Wake Words

- "Claude" = new conversation
- "Hey Claude" or "Continue" = continue existing

## UX Considerations

- User shouldn't have to think about sessions
- Reasonable timeout (2-5 min?) for auto-continuing
- Clear audio feedback when starting fresh vs continuing
- Claudio UI should show session state

## Files to Modify

- `/Users/samuelz/agent-tools/brabble-claude-hook.sh` - add session management
- `Claudio/ViewModels/ClaudioViewModel.swift` - track active session
- `Claudio/Views/MenuBarView.swift` - show conversation mode indicator

## Open Questions

1. What timeout feels right? 2 minutes? 5 minutes?
2. Should there be an explicit "end conversation" command?
3. How to handle errors mid-conversation?
