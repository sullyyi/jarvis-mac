//
//  RecordingController.swift
//  JarvisMac
//
//  Created by Sully Yildiz on 4/2/26.
//

import Foundation
import Combine

final class RecordingController: ObservableObject {
    @Published var lastTranscription: String?
    
    private let audioCapture: AudioCaptureManager
    private let whisper: WhisperTranscriber
    private let hotkeyMonitor: HotkeyMonitor
    private var cancellables = Set<AnyCancellable>()
    
    init(audioCapture: AudioCaptureManager, whisper: WhisperTranscriber, hotkeyMonitor: HotkeyMonitor) {
        self.audioCapture = audioCapture
        self.whisper = whisper
        self.hotkeyMonitor = hotkeyMonitor
        
        setupHotkeyBinding()
    }
    
    private func setupHotkeyBinding() {
        hotkeyMonitor.$isRightOptionPressed
            .sink { [weak self] isPressed in
                if isPressed {
                    self?.startRecording()
                } else {
                    self?.stopAndTranscribe()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startRecording() {
        print("🎤 Starting recording from hotkey...")
        audioCapture.startRecording()
    }
    
    private func stopAndTranscribe() {
        print("⏹️ Stopping recording and transcribing...")
        audioCapture.stopRecording()
        
        guard let audioURL = audioCapture.recordedAudioURL else {
            print("⚠️ No audio file to transcribe")
            return
        }
        
        print("📁 Audio file: \(audioURL.path)")
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: audioURL.path),
           let fileSize = attributes[.size] as? Int {
            print("📊 File size: \(fileSize) bytes")
        }
        
        print("🔄 Starting transcription...")
        whisper.transcribe(audioURL: audioURL) { [weak self] result in
            switch result {
            case .success(let text):
                print("✅ Transcription: \(text)")
                self?.lastTranscription = text
            case .failure(let error):
                print("❌ Transcription error: \(error.localizedDescription)")
            }
        }
    }
}
