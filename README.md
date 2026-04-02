# JarvisMac

JarvisMac is a secure, portfolio-grade native macOS AI assistant built as a lightweight menu bar application. It combines a SwiftUI desktop client with a local Node.js token server to support privacy-conscious real-time AI interactions without exposing API secrets in the client.

The project is designed around a practical “Jarvis on Mac” vision: fast push-to-talk access, spoken responses, screenshot-on-demand support, and future app-aware assistance for coding, troubleshooting, and productivity workflows.

## Current Progress

The project currently includes:

- A native macOS menu bar app built with SwiftUI
- A secure local token server for generating ephemeral OpenAI Realtime session credentials
- A health-check connection between the macOS client and backend
- A repo structure designed for safe public portfolio use with secrets excluded from source control

## Planned Features

- Right-Control push-to-talk activation
- Spoken AI replies
- Screenshot-based contextual help
- Optional app-aware workflows and tool integrations

## Current Development Status

**Latest Milestone (v2.0):** Audio capture and transcription pipeline complete.

### Implemented Features

**Phase 1: Interaction Layer** ✅
- macOS menu bar application with SwiftUI
- Global push-to-talk hotkey using Right Option key
- Visual feedback (pulsing menu bar icon, color-coded status)
- Dropdown menu interface with testing utilities
- Stable SwiftUI application structure

**Phase 2: Audio Pipeline** ✅
- **Microphone Capture (AVFoundation)**
  - Real-time audio recording while hotkey is held
  - M4A format with proper AVAudioFormat settings
  - Automatic temp file management
- **Speech-to-Text (Whisper)**
  - Local Whisper CLI integration (no API key required)
  - JSON output parsing
  - Error handling and transcription status display
  - Results shown in menu bar UI

### Current Interaction Flow
```
Right Option key held
  → Audio engine starts recording
  → Menu bar icon pulses (listening state)
  → User speaks

Right Option key released
  → Audio capture stops
  → Whisper transcription begins
  → Transcription displayed in menu bar
  → Awaiting command processing (next phase)
```

### Next Development Steps

1. **Command Processing** — Send transcribed text to language model agent (Claude/GPT)
2. **Voice Response Playback** — ElevenLabs integration for spoken replies
3. **System Command Execution** — Safe automation of system tasks
4. **App-Aware Workflows** — Context-aware assistance for coding, troubleshooting, etc.

