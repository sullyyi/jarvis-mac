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

The project now includes the foundational structure for the Jarvis Mac menu bar assistant.

Implemented features:

- macOS menu bar application
- Global push-to-talk hotkey using the Option key
- Visual feedback via pulsing menu bar icon while the key is held
- Dropdown menu interface with testing utilities
- Stable SwiftUI application structure with clean builds

This milestone establishes the interaction layer required for voice assistant functionality.

### Current Interaction Flow
Option key held
→ Menu bar icon pulses (listening state)
Option key released
→ Voice pipeline will trigger (future)


### Next Development Steps

Planned features:

1. Microphone capture using AVFoundation  
2. Local speech transcription using Whisper  
3. Command processing via language model agent  
4. Voice response playback using ElevenLabs  
5. System command execution and automation  

