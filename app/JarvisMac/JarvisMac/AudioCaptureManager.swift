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
    private var bufferFrameCount: Int = 0
    
    override init() {
        super.init()
        setupAudioEngine()
    }
    
    // MARK: - Setup
    
    private func setupAudioEngine() {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        print("🎤 Audio Engine initialized")
        print("   Sample rate: \(format.sampleRate)")
        print("   Channels: \(format.channelCount)")
    }
    
    // MARK: - Recording Control
    
    func startRecording() {
        guard !isRecording else { 
            print("⚠️ Already recording")
            return 
        }
        
        do {
            // Create audio file for recording
            let audioURL = tempDirectory.appendingPathComponent("recording_\(UUID().uuidString).wav")
            
            // Get the input node's output format
            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            
            print("📁 Recording to: \(audioURL.path)")
            print("🎤 Format: \(format.sampleRate)Hz, \(format.channelCount) channels")
            
            // Create audio file for writing (using WAV for better compatibility)
            audioFile = try AVAudioFile(forWriting: audioURL, settings: format.settings)
            recordedAudioURL = audioURL
            bufferFrameCount = 0
            
            // Install tap on input node to capture audio
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                do {
                    try self?.audioFile?.write(from: buffer)
                    self?.bufferFrameCount += Int(buffer.frameLength)
                    print("📊 Recorded \(buffer.frameLength) frames (total: \(self?.bufferFrameCount ?? 0))")
                } catch {
                    self?.error = error
                    print("❌ Write error: \(error.localizedDescription)")
                }
            }
            
            // Start the audio engine if not already running
            if !audioEngine.isRunning {
                try audioEngine.start()
                print("✅ Audio engine started")
            } else {
                print("✅ Audio engine already running")
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
        guard isRecording else { 
            print("⚠️ Not currently recording")
            return 
        }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        
        print("⏹️ Recording stopped")
        print("📊 Total frames recorded: \(bufferFrameCount)")
        
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
