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
    
    // MARK: - Transcription
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        isTranscribing = true
        
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
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        
        process.arguments = [
            audioFile.path,
            "--model", "base",
            "--language", "en",
            "--output_format", "json",
            "--output_dir", NSTemporaryDirectory()
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus != 0 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown Whisper error"
            throw WhisperError.transcriptionFailed(errorMessage)
        }
        
        // Parse JSON output from Whisper
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        
        throw WhisperError.parsingFailed
    }
}

// MARK: - Error Handling

enum WhisperError: LocalizedError {
    case notInstalled
    case transcriptionFailed(String)
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Whisper is not installed. Run: brew install openai-whisper"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .parsingFailed:
            return "Failed to parse Whisper output"
        }
    }
}
