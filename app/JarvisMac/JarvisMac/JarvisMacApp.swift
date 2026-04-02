//
//  JarvisMacApp.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import SwiftUI
import Combine

@main
struct JarvisMacApp: App {
    @StateObject private var hotkeyMonitor = HotkeyMonitor.shared
    @StateObject private var iconState: MenuBarIconState
    @StateObject private var serverManager = ServerManager()
    @StateObject private var audioCapture = AudioCaptureManager()
    @StateObject private var whisper = WhisperTranscriber()
    @StateObject private var recordingController: RecordingController


    init() {
        let monitor = HotkeyMonitor.shared
        let iconState = MenuBarIconState(hotkeyMonitor: monitor)
        _iconState = StateObject(wrappedValue: iconState)
        
        let audioCapture = AudioCaptureManager()
        let whisper = WhisperTranscriber()
        let recordingController = RecordingController(audioCapture: audioCapture, whisper: whisper, hotkeyMonitor: monitor)
        
        _audioCapture = StateObject(wrappedValue: audioCapture)
        _whisper = StateObject(wrappedValue: whisper)
        _recordingController = StateObject(wrappedValue: recordingController)
        
        // Defer hotkey monitoring to avoid blocking app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            monitor.startMonitoring()
            iconState.startIconAnimation()
            print("🎯 Hotkey monitoring started")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                hotkeyMonitor: hotkeyMonitor,
                serverManager: serverManager,
                audioCapture: audioCapture,
                whisper: whisper,
                recordingController: recordingController
            )
        } label: {
            Image(systemName: currentSymbol)
                .foregroundStyle(hotkeyMonitor.isRightOptionPressed ? .green : .primary)
        }
        .menuBarExtraStyle(.window)
    }
    
    
    

    private var currentSymbol: String {
        if !hotkeyMonitor.isRightOptionPressed {
            return "bolt.circle"
        }

        return iconState.iconFrame.isMultiple(of: 2)
            ? "mic.circle.fill"
            : "waveform.circle.fill"
    }
}
