# PRD: Live Transcription Display

## Introduction

Add a live transcription view to the Claudio popover that shows real-time text as the user speaks to brabble. This provides immediate visual feedback that the voice daemon is hearing and transcribing speech, improving user confidence and the overall experience.

## Goals

- Show transcription text in real-time as the user speaks
- Provide clear visual feedback that brabble is actively listening
- Indicate when a previous transcription exists (for context)
- Integrate seamlessly with existing popover UI styling

## User Stories

### US-001: Create TranscriptionView component
**Description:** As a developer, I need a reusable SwiftUI view that displays transcription text with a blinking cursor.

**Acceptance Criteria:**
- [ ] Create `TranscriptionView.swift` in Views directory
- [ ] Accept transcription text as binding/parameter
- [ ] Display blinking cursor (vertical bar) after text
- [ ] Cursor blinks at standard rate (~1 second interval)
- [ ] Use subtle container with light background tint (matching ProcessingBanner style)
- [ ] Support multi-line text that expands naturally (no max height)
- [ ] Typecheck passes with `swift build`

### US-002: Track current transcription in ViewModel
**Description:** As the app, I need to track the current transcription text so the UI can display it.

**Acceptance Criteria:**
- [ ] Add `currentTranscription: String?` published property to AppState
- [ ] Add `previousTranscription: String?` published property to AppState
- [ ] Update `currentTranscription` when new transcription text is parsed from brabble logs
- [ ] Move current to previous when a new session/transcription starts
- [ ] Clear `currentTranscription` when processing begins (but keep `previousTranscription`)
- [ ] Typecheck passes with `swift build`

### US-003: Integrate TranscriptionView into MenuBarView
**Description:** As a user, I want to see my transcription appear in the popover as I speak.

**Acceptance Criteria:**
- [ ] Add TranscriptionView between StatusHeader and ProcessingBanner in MenuBarView
- [ ] Only show TranscriptionView when `currentTranscription` is non-nil and non-empty
- [ ] Animate appearance/disappearance with subtle fade
- [ ] View disappears when not actively transcribing
- [ ] Typecheck passes with `swift build`
- [ ] Build and run app to verify transcription appears when speaking

### US-004: Show previous transcription indicator
**Description:** As a user, I want to know if there was a previous transcription for context.

**Acceptance Criteria:**
- [ ] When `currentTranscription` is nil but `previousTranscription` exists, show subtle indicator
- [ ] Indicator text: "Previous: [truncated text...]" in muted style
- [ ] Truncate previous transcription to ~50 characters with ellipsis
- [ ] Tapping indicator could expand to show full text (optional/nice-to-have)
- [ ] Typecheck passes with `swift build`
- [ ] Build and run app to verify indicator appears after transcription completes

### US-005: Wire up transcription updates from log parsing
**Description:** As a developer, I need to connect the existing log parser to update the transcription state.

**Acceptance Criteria:**
- [ ] Identify where transcriptions are currently parsed (likely in LogWatcher or similar)
- [ ] Call AppState method to update `currentTranscription` when new text arrives
- [ ] Handle partial transcriptions (text updates as user speaks)
- [ ] Handle transcription completion (when user stops speaking)
- [ ] Typecheck passes with `swift build`
- [ ] Build and run app to verify real-time updates work

## Functional Requirements

- FR-1: Display transcription text with blinking cursor in popover
- FR-2: Show transcription view only when actively transcribing (non-empty currentTranscription)
- FR-3: Use subtle container styling matching ProcessingBanner (light background tint)
- FR-4: Support multi-line transcriptions that expand naturally
- FR-5: Track both current and previous transcription in app state
- FR-6: Show "Previous: [text...]" indicator when current is empty but previous exists
- FR-7: Animate view appearance/disappearance with fade transition
- FR-8: Keep previous transcription visible until next transcription starts

## Non-Goals

- No transcription history beyond current + previous
- No editing or copying transcription text
- No transcription audio playback
- No transcription persistence to disk (already handled by brabble)
- No transcription in the history window (separate feature)

## Design Considerations

- Position: Between StatusHeader and ProcessingBanner/SessionsList
- Style: Match existing ProcessingBanner with light blue/gray tint
- Cursor: Thin vertical bar, standard blink rate
- Typography: Match existing body text style in popover
- Animation: Subtle fade in/out (0.2s duration)

## Technical Considerations

- Transcription model already exists at `Claudio/Models/Transcription.swift`
- AppState already tracks `recentTranscriptions` array
- LogWatcher/FileMonitor likely already parses transcription events
- May need to distinguish "in-progress" vs "completed" transcription states
- Cursor animation can use SwiftUI's `withAnimation` and `Timer`

## Success Metrics

- Transcription appears within 100ms of brabble detecting speech
- Text updates smoothly as user speaks (no flickering)
- Popover height adjusts smoothly for multi-line transcriptions
- No performance impact on popover responsiveness

## Open Questions

- Does brabble emit partial transcriptions or only complete ones?
- Is there a clear "transcription started" vs "transcription ended" event?
- Should cursor stop blinking when transcription is "complete" but still displayed?
