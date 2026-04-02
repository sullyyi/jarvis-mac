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
        // Request microphone permission if not already granted
        AVAudioApplication.requestRecordPermission { granted in
            if granted {
                print("✅ Microphone permission granted")
            } else {
                print("❌ Microphone permission denied! Grant permission in System Settings > Privacy & Security > Microphone")
            }
        }
        
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        print("🎤 Audio Engine initialized")
        print("   Sample rate: \(format.sampleRate)")
        print("   Channels: \(format.channelCount)")
        print("   Format: \(format)")
    }
    
    // MARK: - Start Recording
    
    func startRecording() {
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }

        do {
            let inputNode = audioEngine.inputNode

            // Defensive cleanup from any prior run
            inputNode.removeTap(onBus: 0)
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            audioEngine.reset()
            audioFile = nil
            error = nil
            bufferFrameCount = 0
            recordedAudioURL = nil

            let audioURL = tempDirectory.appendingPathComponent("recording_\(UUID().uuidString).wav")
            let format = inputNode.outputFormat(forBus: 0)

            print("🎤 Starting recording...")
            print("📁 Recording to: \(audioURL.path)")
            print("🎤 Format: \(format.sampleRate)Hz, \(format.channelCount) channels")

            audioFile = try AVAudioFile(forWriting: audioURL, settings: format.settings)
            recordedAudioURL = audioURL

            inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
                guard let self else { return }

                do {
                    try self.audioFile?.write(from: buffer)
                    self.bufferFrameCount += Int(buffer.frameLength)
                    print("📊 Recorded \(buffer.frameLength) frames (total: \(self.bufferFrameCount))")
                } catch {
                    self.error = error
                    print("❌ Write error: \(error.localizedDescription)")
                }
            }

            try audioEngine.start()
            print("✅ Audio engine started")

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
    
    // MARK: - Stop Recording

    func stopRecording() -> URL? {
        guard isRecording else {
            print("⚠️ Not currently recording")
            return nil
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        // Stop the engine so this take is fully finalized
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        // Reset internal render state before the next take
        audioEngine.reset()

        // IMPORTANT: release the file handle so the WAV is closed/flushed
        audioFile = nil

        print("⏹️ Recording stopped")
        print("📊 Total frames recorded: \(bufferFrameCount)")

        if let url = recordedAudioURL {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
            print("📁 Audio file saved at: \(url.path)")
            print("📊 File size: \(size) bytes")
        }

        DispatchQueue.main.async {
            self.isRecording = false
        }

        return recordedAudioURL
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
