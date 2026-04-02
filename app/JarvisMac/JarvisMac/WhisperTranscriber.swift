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
    
    // MARK: - Transcription
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        isTranscribing = true
        error = nil
        
        processQueue.async { [weak self] in
            do {
                let transcription = try self?.runWhisper(audioFile: audioURL) ?? ""
                
                DispatchQueue.main.async {
                    self?.transcription = transcription
                    self?.isTranscribing = false
                    completion(.success(transcription))
                }
            } catch {
                DispatchQueue.main.async {
                    self?.error = error
                    self?.isTranscribing = false
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Private Whisper Execution
    
    private func runWhisper(audioFile: URL) throws -> String {
        // Try to locate whisper in common paths
        let whisperPaths = [
            "/opt/homebrew/bin/whisper",      // Apple Silicon Homebrew
            "/usr/local/bin/whisper",          // Intel Homebrew / manual install
            "/usr/bin/whisper"                 // System path
        ]
        
        guard let whisperPath = whisperPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            throw WhisperError.notInstalled
        }
        
        // Create a unique output directory for this transcription
        let outputDir = tempDirectory.appendingPathComponent("whisper_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
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
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            try? FileManager.default.removeItem(at: outputDir)
            throw WhisperError.transcriptionFailed("Failed to run Whisper process: \(error.localizedDescription)")
        }
        
        // Capture both stdout and stderr
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdoutText = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
        
        print("🔊 Whisper stdout: \(stdoutText)")
        print("🔊 Whisper stderr: \(stderrText)")
        
        if process.terminationStatus != 0 {
            let errorMessage = stderrText.isEmpty ? stdoutText : stderrText
            try? FileManager.default.removeItem(at: outputDir)
            throw WhisperError.transcriptionFailed(errorMessage)
        }
        
        // Find the JSON file that Whisper created (it renames based on input filename)
        let contents = try FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
        
        print("📁 Output directory contents: \(contents.map { $0.lastPathComponent })")
        
        let jsonFile = contents.first { $0.pathExtension == "json" }
        
        guard let jsonPath = jsonFile else {
            let files = try FileManager.default.contentsOfDirectory(atPath: outputDir.path)
            print("❌ No JSON files found in \(outputDir.path). Files: \(files)")
            try? FileManager.default.removeItem(at: outputDir)
            throw WhisperError.parsingFailed("Whisper created no JSON file. Files: \(files)")
        }
        
        print("✅ Found JSON file: \(jsonPath.lastPathComponent)")
        
        let jsonData = try Data(contentsOf: jsonPath)
        
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let text = json["text"] as? String {
            // Cleanup
            try? FileManager.default.removeItem(at: outputDir)
            return text
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: outputDir)
        throw WhisperError.parsingFailed("Failed to parse Whisper JSON output")
    }
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
