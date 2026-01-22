# Feature Report: Settings & Transcribe-Only Mode

**Date**: 2026-01-22
**Priority**: High
**Type**: New Feature

## Overview

Add a comprehensive settings system to Claudio enabling users to configure LLM providers, API keys, models, clipboard behavior, and a new "transcribe-only" mode.

## Features Requested

### 1. LLM Provider Selection
Users should be able to choose between LLM providers:
- Claude (Anthropic) - default
- OpenAI (GPT-4, etc.)
- Local models (Ollama)

### 2. Bring Your Own API Key
- Text field to enter API key for selected provider
- Secure storage (Keychain)
- Validation on save

### 3. Model Selection
- Dropdown of available models for selected provider
- Claude: opus, sonnet, haiku
- OpenAI: gpt-4o, gpt-4o-mini, o1, o3-mini
- Ollama: list from local instance

### 4. Clipboard Toggle
- Option to automatically copy Claude's response to clipboard
- Default: off

### 5. Transcribe-Only Mode
New mode where wake word triggers:
1. Transcription capture (existing)
2. Text cleanup via small/fast model (grammar, punctuation)
3. Copy cleaned text to clipboard
4. NO Claude conversation - just transcription

Use case: Dictation for emails, notes, messages

## Technical Approach

### Settings Storage
- `@AppStorage` (UserDefaults) for UI preferences
- macOS Keychain for API keys
- `~/.config/claudio/hook-config.sh` for bash script access

### Hook Script Changes
`brabble-claude-hook.sh` needs to:
1. Source `~/.config/claudio/hook-config.sh` for settings
2. Check mode (conversation vs transcribe-only)
3. Use configured provider/model/API key
4. Optionally copy response to clipboard

### UI Changes
Expand SettingsView.swift with sections:
- **Provider**: Picker for LLM provider
- **API Key**: SecureField with Keychain storage
- **Model**: Picker filtered by provider
- **Behavior**: Toggles for clipboard, speech output
- **Mode**: Segment control (Conversation / Transcribe-Only)

## Files to Create/Modify

### Create
- `Claudio/Services/AppSettings.swift` - Settings model
- `Claudio/Services/KeychainService.swift` - API key storage
- `Claudio/Services/SettingsWriter.swift` - Generates hook-config.sh

### Modify
- `Claudio/Views/SettingsView.swift` - New settings UI
- `~/agent-tools/brabble-claude-hook.sh` - Multi-provider support
- `Claudio/ViewModels/ClaudioViewModel.swift` - Settings integration

## Acceptance Criteria

1. User can select provider from Settings
2. User can enter and save API key securely
3. User can select model appropriate to provider
4. User can toggle clipboard copy on/off
5. User can switch to transcribe-only mode
6. Transcribe-only mode copies cleaned text to clipboard
7. All settings persist across app restarts
8. Build succeeds with `./build.sh`
