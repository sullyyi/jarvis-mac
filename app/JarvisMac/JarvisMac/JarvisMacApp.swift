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


    init() {
        let monitor = HotkeyMonitor.shared
        _iconState = StateObject(wrappedValue: MenuBarIconState(hotkeyMonitor: monitor))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                hotkeyMonitor: hotkeyMonitor,
                serverManager: serverManager
            )
        } label: {
            Image(systemName: currentSymbol)
                .foregroundStyle(hotkeyMonitor.isRightOptionPressed ? .green : .primary)
                .onAppear {
                    iconState.start()
                }
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
