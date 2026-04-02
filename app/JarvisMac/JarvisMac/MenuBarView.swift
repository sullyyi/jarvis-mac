//
//  MenuBarView.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

//
//  MenuBarView.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    
    @StateObject private var viewModel = ServerViewModel()
    @ObservedObject var hotkeyMonitor: HotkeyMonitor
    @ObservedObject var serverManager: ServerManager
    @ObservedObject var audioCapture: AudioCaptureManager
    @ObservedObject var whisper: WhisperTranscriber
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(hotkeyMonitor.isRightOptionPressed ? Color.green : Color.gray.opacity(0.3))
                .frame(height: 6)
                .opacity(hotkeyMonitor.isRightOptionPressed ? (pulse ? 1.0 : 0.4) : 1.0)
                .animation(
                    hotkeyMonitor.isRightOptionPressed
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 30))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jarvis")
                            .font(.headline)
                        Text("Menu Bar Assistant")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        "Server",
                        systemImage: viewModel.isHealthy ? "checkmark.circle.fill" : "xmark.circle.fill"
                    )
                    .foregroundStyle(viewModel.isHealthy ? .green : .red)
                    .font(.subheadline)

                    Text(viewModel.statusMessage)
                        .font(.callout)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Local Server Control")
                        .font(.subheadline)
                        .bold()

                    Label(
                        serverManager.isRunning ? "Local server running" : "Local server stopped",
                        systemImage: serverManager.isRunning ? "play.circle.fill" : "stop.circle.fill"
                    )
                    .foregroundStyle(serverManager.isRunning ? .green : .secondary)
                    .font(.callout)

                    Text(serverManager.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Push-to-Talk Status")
                        .font(.subheadline)
                        .bold()

                    Label(
                        hotkeyMonitor.isRightOptionPressed ? "Listening..." : "Hold Right Option to Talk",
                        systemImage: hotkeyMonitor.isRightOptionPressed ? "mic.fill" : "keyboard"
                    )
                    .foregroundStyle(hotkeyMonitor.isRightOptionPressed ? .green : .secondary)
                    .font(.callout)
                    
                    if audioCapture.isRecording {
                        Label("Recording audio...", systemImage: "waveform.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    
                    if whisper.isTranscribing {
                        Label("Transcribing...", systemImage: "bubble.right.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    
                    if let transcription = whisper.transcription {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last transcription:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(transcription)
                                .font(.caption)
                                .lineLimit(3)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }

                Divider()

                HStack {
                    Button(serverManager.isRunning ? "Stop Local Server" : "Start Local Server") {
                        if serverManager.isRunning {
                            serverManager.stopServer()
                        } else {
                            serverManager.startServer()
                        }
                    }

                    Spacer()

                    Button("Test Server") {
                        Task {
                            await viewModel.checkHealth()
                        }
                    }

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(16)
            .frame(width: 340)
        }
        .task {
            await viewModel.checkHealth()
        }
        .onAppear {
            pulse.toggle()
        }
        .onChange(of: hotkeyMonitor.isRightOptionPressed) { oldValue, newValue in
            if newValue {
                audioCapture.startRecording()
            } else {
                audioCapture.stopRecording()
                
                // Transcribe the recorded audio
                if let audioURL = audioCapture.recordedAudioURL {
                    whisper.transcribe(audioURL: audioURL) { result in
                        switch result {
                        case .success(let text):
                            print("Transcription: \(text)")
                        case .failure(let error):
                            print("Transcription error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MenuBarView(
        hotkeyMonitor: HotkeyMonitor.shared,
        serverManager: ServerManager(),
        audioCapture: AudioCaptureManager(),
        whisper: WhisperTranscriber()
    )
}
