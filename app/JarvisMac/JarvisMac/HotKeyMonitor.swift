//
//  HotKeyMonitor.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import Foundation
import AppKit
import Combine

final class HotkeyMonitor: ObservableObject {
    static let shared = HotkeyMonitor()

    @Published private(set) var isRightOptionPressed: Bool = false

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    func startMonitoring() {
        guard globalMonitor == nil, localMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    func stopMonitoring() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        DispatchQueue.main.async {
            self.isRightOptionPressed = false
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        guard event.keyCode == 61 else { return }

        let pressed = event.modifierFlags.contains(.option)

        DispatchQueue.main.async {
            self.isRightOptionPressed = pressed
        }
    }

    deinit {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }

        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
}
