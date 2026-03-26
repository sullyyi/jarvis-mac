//
//  MenuBarIconState.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/25/26.
//

import Foundation
import Combine

final class MenuBarIconState: ObservableObject {
    @Published private(set) var iconFrame: Int = 0

    private var timer: Timer?
    private let hotkeyMonitor: HotkeyMonitor

    init(hotkeyMonitor: HotkeyMonitor) {
        self.hotkeyMonitor = hotkeyMonitor
    }

    func start() {
        guard timer == nil else { return }

        hotkeyMonitor.startMonitoring()

        timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            guard let self else { return }

            DispatchQueue.main.async {
                if self.hotkeyMonitor.isRightOptionPressed {
                    self.iconFrame += 1
                } else {
                    self.iconFrame = 0
                }
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        hotkeyMonitor.stopMonitoring()
    }

    deinit {
        timer?.invalidate()
    }
}
