//
//  ServerManager.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/26/26.
//

import Foundation
import AppKit
import Combine

final class ServerManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "Server stopped"

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    private let serverDirectory = "/Users/sullyyildiz/Documents/GitHub/jarvis-mac/server"
    private let shellPath = "/bin/zsh"

    func startServer() {
        guard process == nil || process?.isRunning != true else {
            statusText = "Server already running"
            return
        }

        let task = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        task.executableURL = URL(fileURLWithPath: shellPath)
        task.arguments = [
            "-lc",
            "cd \"\(serverDirectory)\" && /opt/homebrew/bin/npm start"
        ]

        task.standardOutput = outPipe
        task.standardError = errPipe

        outputPipe = outPipe
        errorPipe = errPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                print("[SERVER OUT] \(text)", terminator: "")
                self?.statusText = "Server output received"
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                print("[SERVER ERR] \(text)", terminator: "")
                self?.statusText = "Server error"
            }
        }

        task.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.statusText = "Server stopped"
                self?.cleanup()
            }
        }

        do {
            try task.run()
            process = task
            isRunning = true
            statusText = "Starting server..."
        } catch {
            isRunning = false
            statusText = "Failed to start server"
            cleanup()
            print("Failed to start server: \(error.localizedDescription)")
        }
    }

    func stopServer() {
        guard let task = process, task.isRunning else {
            statusText = "Server not running"
            return
        }

        task.terminate()
        statusText = "Stopping server..."
    }

    private func cleanup() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        errorPipe = nil
        process = nil
    }
}
