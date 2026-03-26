//
//  JarvisMacApp.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import SwiftUI

@main
struct JarvisMacApp: App {
    var body: some Scene {
        MenuBarExtra("Jarvis", systemImage: "waveform.circle.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
