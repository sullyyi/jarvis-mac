//
//  WhisperTranscriber.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 4/2/26.
//

import Foundation
import Combine

final class WhisperTranscriber: ObservableObject {
    @Published var transcription: String?
    @Published var isTranscribing = false
    @Published var error: Error?
    
    private let processQueue = DispatchQueue(label: "com.jarvis.whisper", qos: .userInitiated)
    private let tempDirectory = FileManager.default.temporaryDirectory
    private var activeRequestID = UUID()
    
    // MARK: - Transcription
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let requestID = UUID()

        activeRequestID = requestID
        isTranscribing = true
        error = nil
        transcription = nil
        
        processQueue.async { [weak self] in
            do {
                let transcription = try self?.runWhisper(audioFile: audioURL) ?? ""
                
                DispatchQueue.main.async {
                    guard self?.activeRequestID == requestID else {
                        return
                    }

                    self?.transcription = transcription
                    self?.isTranscribing = false
                    completion(.success(transcription))
                }
            } catch {
                DispatchQueue.main.async {
                    guard self?.activeRequestID == requestID else {
                        return
                    }

                    self?.error = error
                    self?.isTranscribing = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Private Whisper Execution
    
    private func runWhisper(audioFile: URL) throws -> String {
        let fileManager = FileManager.default
        
        let whisperPaths = [
            "/opt/homebrew/bin/whisper",
            "/usr/local/bin/whisper",
            "/usr/bin/whisper"
        ]
        
        let ffmpegPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        
        guard let whisperPath = whisperPaths.first(where: { fileManager.fileExists(atPath: $0) }) else {
            throw WhisperError.notInstalled
        }
        
        guard let ffmpegPath = ffmpegPaths.first(where: { fileManager.fileExists(atPath: $0) }) else {
            throw WhisperError.transcriptionFailed(
                "ffmpeg is not installed or not visible to the app. Run: brew install ffmpeg"
            )
        }
        
        let outputDir = tempDirectory.appendingPathComponent("whisper_\(UUID().uuidString)")
        try fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        
        process.arguments = [
            audioFile.path,
            "--model", "base",
            "--language", "en",
            "--output_format", "json",
            "--output_dir", outputDir.path,
            "--verbose", "False"
        ]
        
        var env = ProcessInfo.processInfo.environment
        
        let ffmpegDir = URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path
        let whisperDir = URL(fileURLWithPath: whisperPath).deletingLastPathComponent().path
        
        let extraPaths = [
            ffmpegDir,
            whisperDir,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        
        let existingPATH = env["PATH"] ?? ""
        env["PATH"] = (extraPaths + [existingPATH])
            .filter { !$0.isEmpty }
            .joined(separator: ":")
        
        process.environment = env
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            try? fileManager.removeItem(at: outputDir)
            throw WhisperError.transcriptionFailed("Failed to run Whisper process: \(error.localizedDescription)")
        }
        
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdoutText = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
        
        print("🔊 Whisper stdout: \(stdoutText)")
        print("🔊 Whisper stderr: \(stderrText)")
        
        let combinedOutput = "\(stdoutText)\n\(stderrText)"
        
        if combinedOutput.contains("No such file or directory: 'ffmpeg'") ||
            combinedOutput.contains("FileNotFoundError") {
            try? fileManager.removeItem(at: outputDir)
            throw WhisperError.transcriptionFailed(
                "Whisper could not find ffmpeg. Detected ffmpeg at \(ffmpegPath), but the subprocess still could not use it."
            )
        }
        
        if process.terminationStatus != 0 {
            let errorMessage = stderrText.isEmpty ? stdoutText : stderrText
            try? fileManager.removeItem(at: outputDir)
            throw WhisperError.transcriptionFailed(errorMessage)
        }
        
        let contents = try fileManager.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
        print("📁 Output directory contents: \(contents.map { $0.lastPathComponent })")
        
        guard let jsonFile = contents.first(where: { $0.pathExtension.lowercased() == "json" }) else {
            let files = try fileManager.contentsOfDirectory(atPath: outputDir.path)
            try? fileManager.removeItem(at: outputDir)
            throw WhisperError.parsingFailed("Whisper created no JSON file. Files: \(files)")
        }
        
        let jsonData = try Data(contentsOf: jsonFile)
        
        if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let text = json["text"] as? String {
            try? fileManager.removeItem(at: outputDir)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        try? fileManager.removeItem(at: outputDir)
        throw WhisperError.parsingFailed("Failed to parse Whisper JSON output")
    }
    // MARK: - Error Handling
    
    enum WhisperError: LocalizedError {
        case notInstalled
        case transcriptionFailed(String)
        case parsingFailed(String?)
        
        var errorDescription: String? {
            switch self {
            case .notInstalled:
                return "Whisper is not installed. Run: brew install openai-whisper"
            case .transcriptionFailed(let message):
                return "Transcription failed: \(message)"
            case .parsingFailed(let message):
                return message ?? "Failed to parse Whisper output"
            }
        }
    }
}
