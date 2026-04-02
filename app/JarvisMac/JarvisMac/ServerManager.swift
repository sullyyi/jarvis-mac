//
//  ServerManager.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 3/26/26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class ServerManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "Server stopped"

    private let serverDirectory = "/Users/sullyyildiz/Documents/GitHub/jarvis-mac/server"
    private let healthURL = URL(string: "http://127.0.0.1:8787/health")!
    private let logFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("jarvis-server.log")

    func startServer() {
        if isRunning {
            statusText = "Server already running"
            return
        }

        statusText = "Starting server..."
        isRunning = false

        let serverDirectory = self.serverDirectory
        let healthURL = self.healthURL
        let logFileURL = self.logFileURL
        let nodeExecutableURL = resolvedNodeExecutableURL()
        let environment = sanitizedEnvironment()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Self.startServerInBackground(
                serverDirectory: serverDirectory,
                healthURL: healthURL,
                logFileURL: logFileURL,
                nodeExecutableURL: nodeExecutableURL,
                environment: environment
            )

            DispatchQueue.main.async {
                guard let self else { return }

                self.isRunning = result.isRunning
                self.statusText = result.statusText
            }
        }
    }

    func stopServer() {
        statusText = "Stopping server..."
        isRunning = false

        let healthURL = self.healthURL

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didIssueStop = Self.stopServerInBackground()
            let isStillRunning = Self.checkServerHealth(at: healthURL)

            DispatchQueue.main.async {
                guard let self else { return }

                if !isStillRunning {
                    self.isRunning = false
                    self.statusText = "Server stopped"
                } else if didIssueStop {
                    self.isRunning = true
                    self.statusText = "Server is still responding on port 8787"
                } else {
                    self.isRunning = true
                    self.statusText = "Server is running outside app control"
                }
            }
        }
    }

    nonisolated private static func startServerInBackground(
        serverDirectory: String,
        healthURL: URL,
        logFileURL: URL,
        nodeExecutableURL: URL,
        environment: [String: String]
    ) -> LaunchResult {
        if checkServerHealth(at: healthURL) {
            return LaunchResult(isRunning: true, statusText: "Server already running")
        }

        let launchTask = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        launchTask.executableURL = URL(fileURLWithPath: "/bin/zsh")
        launchTask.arguments = ["-lc", launchCommand(
            serverDirectory: serverDirectory,
            logFileURL: logFileURL,
            nodeExecutableURL: nodeExecutableURL
        )]
        launchTask.standardOutput = outputPipe
        launchTask.standardError = errorPipe
        launchTask.environment = environment

        do {
            try launchTask.run()
            launchTask.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let outputText = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let errorText = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard launchTask.terminationStatus == 0 else {
                return LaunchResult(
                    isRunning: false,
                    statusText: errorText.isEmpty ? "Failed to start server" : errorText
                )
            }

            for _ in 0..<12 {
                if checkServerHealth(at: healthURL) {
                    return LaunchResult(
                        isRunning: true,
                        statusText: "Server running"
                    )
                }

                usleep(250_000)
            }

            if checkServerHealth(at: healthURL) {
                return LaunchResult(
                    isRunning: true,
                    statusText: "Server running"
                )
            } else {
                let fallbackStatus =
                    recentLogMessage(at: logFileURL) ??
                    nonEmpty(outputText) ??
                    nonEmpty(errorText) ??
                    "Server exited during startup"

                return LaunchResult(
                    isRunning: false,
                    statusText: fallbackStatus
                )
            }
        } catch {
            return LaunchResult(
                isRunning: false,
                statusText: "Failed to start server: \(error.localizedDescription)"
            )
        }
    }

    nonisolated private static func stopServerInBackground() -> Bool {
        let stopTask = Process()

        stopTask.executableURL = URL(fileURLWithPath: "/bin/zsh")
        stopTask.arguments = [
            "-lc",
            "/usr/sbin/lsof -ti tcp:8787 | xargs kill -TERM >/dev/null 2>&1; sleep 1; /usr/sbin/lsof -ti tcp:8787 | xargs kill -KILL >/dev/null 2>&1; exit 0"
        ]

        do {
            try stopTask.run()
            stopTask.waitUntilExit()
            return true
        } catch {
            return false
        }
    }

    nonisolated private static func launchCommand(
        serverDirectory: String,
        logFileURL: URL,
        nodeExecutableURL: URL
    ) -> String {
        let nodePath = shellQuoted(nodeExecutableURL.path)
        let directoryPath = shellQuoted(serverDirectory)
        let logPath = shellQuoted(logFileURL.path)

        return """
        cd \(directoryPath) && : > \(logPath) && env -u DYLD_INSERT_LIBRARIES -u __XPC_DYLD_INSERT_LIBRARIES \(nodePath) index.js >> \(logPath) 2>&1 & echo $!
        """
    }

    nonisolated private static func recentLogMessage(at logFileURL: URL) -> String? {
        guard let contents = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return nil
        }

        return contents
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    private func checkServerHealth() -> Bool {
        Self.checkServerHealth(at: healthURL)
    }

    nonisolated private static func checkServerHealth(at healthURL: URL) -> Bool {
        guard let data = try? Data(contentsOf: healthURL) else {
            return false
        }

        return !data.isEmpty
    }

    private func resolvedNodeExecutableURL() -> URL {
        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node"
        ]

        if let path = candidates.first(where: FileManager.default.isExecutableFile(atPath:)) {
            return URL(fileURLWithPath: path)
        }

        return URL(fileURLWithPath: "/usr/bin/env")
    }

    private func sanitizedEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment.removeValue(forKey: "DYLD_INSERT_LIBRARIES")
        environment.removeValue(forKey: "__XPC_DYLD_INSERT_LIBRARIES")
        return environment
    }

    nonisolated private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

private struct LaunchResult {
    let isRunning: Bool
    let statusText: String
}
