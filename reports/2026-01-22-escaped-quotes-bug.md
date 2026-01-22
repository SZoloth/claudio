# Bug Report: Escaped Quotes in Brabble Log Parsing

**Date**: 2026-01-22
**Severity**: High (breaks core transcription display)
**Status**: Fixed

## Symptom
Transcription view displayed a lone backslash `\` instead of the transcribed text.

## Root Cause
The brabble log format uses escaped quotes inside message content:
```
msg="heard: \"Yeah.\""
```

The original regex `msg="([^"]+)"` stopped at the first `"` character, which was the escaped quote `\"`. This captured only `heard: \` from the full message.

## Fix
Updated regex to handle escape sequences:
```swift
// Old: #"msg="([^"]+)""#
// New: #"msg="((?:[^"\\]|\\.)*)""#
```

The new pattern matches:
- `[^"\\]` - any character except quote or backslash
- `|\\.` - OR any escaped character (backslash + anything)

Also added unescaping: `.replacingOccurrences(of: "\\\"", with: "\"")`

## Files Changed
- `Claudio/Services/BrabbleLogParser.swift`

## Lessons Learned
- Always test parsers with real log data containing special characters
- Log formats that embed JSON-style strings need escape-aware parsing
- Regex patterns like `[^"]+` are brittle for quoted content with escapes
