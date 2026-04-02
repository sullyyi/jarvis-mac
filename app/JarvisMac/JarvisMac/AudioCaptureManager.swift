//
//  AudioCaptureManager.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 4/2/26.
//

import Foundation
import AVFoundation
import Combine

final class AudioCaptureManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedAudioURL: URL?
    @Published var error: Error?
    
    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private let tempDirectory = FileManager.default.temporaryDirectory
    
    override init() {
        super.init()
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard !isRecording else { return }
        
        do {
            // Create audio file for recording
            let audioURL = tempDirectory.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            
            // Get the input node's output format
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            print("🎤 Audio format: \(format)")
            print("🎤 Sample rate: \(format.sampleRate)")
            print("🎤 Channels: \(format.channelCount)")
            
            // Create audio file for writing
            audioFile = try AVAudioFile(forWriting: audioURL, settings: format.settings)
            recordedAudioURL = audioURL
            
            print("📁 Recording to: \(audioURL.path)")
            
            // Install tap on input node to capture audio
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                do {
                    try self?.audioFile?.write(from: buffer)
                    print("📊 Wrote \(buffer.frameLength) frames")
                } catch {
                    self?.error = error
                    print("❌ Write error: \(error.localizedDescription)")
                }
            }
            
            // Start the audio engine if not already running
            if !audioEngine.isRunning {
                try audioEngine.start()
                print("✅ Audio engine started")
            }
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            self.error = error
            print("❌ Recording start error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Don't stop the audio engine — let it continue for future recordings
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    // MARK: - Cleanup
    
    func deleteRecording() {
        guard let url = recordedAudioURL else { return }
        
        try? FileManager.default.removeItem(at: url)
        recordedAudioURL = nil
    }
    
    deinit {
        audioEngine.inputNode.removeTap(onBus: 0)
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
}

// MARK: - Error Handling

enum AudioCaptureError: LocalizedError {
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Unable to determine audio format"
        }
    }
}
