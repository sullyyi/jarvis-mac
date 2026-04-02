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


    init() {
        let monitor = HotkeyMonitor.shared
        let iconState = MenuBarIconState(hotkeyMonitor: monitor)
        _iconState = StateObject(wrappedValue: iconState)
        
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
                whisper: whisper
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
