//
//  MetronomeEngine.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import Foundation
import AVFoundation
import Combine

// MARK: - Metronome Engine
@MainActor
class MetronomeEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var isPlaying: Bool = false
    @Published var currentBPM: Int = 120
    @Published var currentBeat: Int = 0
    @Published var beatsPerBar: Int = 4
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var clickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?
    private var nextBeatTime: TimeInterval = 0
    private var metronomeTask: Task<Void, Never>?
    private var sessionID: UUID = UUID()
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Generation
    private func generateClickBuffer(frequency: Double, duration: Double, isAccent: Bool) -> AVAudioPCMBuffer? {
        let sampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        let amplitude: Float = isAccent ? 0.8 : 0.5
        let attackTime: Double = 0.001
        let decayTime: Double = duration - attackTime
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            var envelope: Float = 1.0
            
            if time < attackTime {
                envelope = Float(time / attackTime)
            } else {
                let decayProgress = (time - attackTime) / decayTime
                envelope = Float(pow(1.0 - decayProgress, 3))
            }
            
            // Generate click sound with harmonics
            var sample: Float = 0
            let fundamentalFreq = frequency
            sample += sin(Float(2.0 * .pi * fundamentalFreq * time)) * 1.0
            sample += sin(Float(2.0 * .pi * fundamentalFreq * 2 * time)) * 0.5
            sample += sin(Float(2.0 * .pi * fundamentalFreq * 3 * time)) * 0.25
            
            // Add noise component for attack
            if time < 0.005 {
                sample += Float.random(in: -0.3...0.3)
            }
            
            channelData[frame] = sample * amplitude * envelope
        }
        
        return buffer
    }
    
    private func generateSoundBuffers(for sound: MetronomeSound) {
        let baseFrequency: Double
        let duration: Double = 0.05
        
        switch sound {
        case .click:
            baseFrequency = 1000
        case .woodblock:
            baseFrequency = 800
        case .hihat:
            baseFrequency = 3000
        case .rimshot:
            baseFrequency = 1200
        case .cowbell:
            baseFrequency = 600
        }
        
        clickBuffer = generateClickBuffer(frequency: baseFrequency, duration: duration, isAccent: false)
        accentBuffer = generateClickBuffer(frequency: baseFrequency * 1.5, duration: duration, isAccent: true)
    }
    
    // MARK: - Engine Setup
    private func setupAudioEngine() {
        // Stop existing engine if any
        playerNode?.stop()
        audioEngine?.stop()
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let playerNode = playerNode else { return }
        
        audioEngine.attach(playerNode)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Playback Control
    func start(bpm: Int, sound: MetronomeSound = .click, beatsPerBar: Int = 4) {
        // Stop any existing playback first
        stopInternal()
        
        // Create new session ID to invalidate old loops
        sessionID = UUID()
        let currentSessionID = sessionID
        
        setupAudioSession()
        setupAudioEngine()
        generateSoundBuffers(for: sound)
        
        currentBPM = bpm
        self.beatsPerBar = beatsPerBar
        currentBeat = 0
        isPlaying = true
        
        playerNode?.play()
        
        let interval = 60.0 / Double(bpm)
        nextBeatTime = CACurrentMediaTime()
        
        startMetronomeLoop(interval: interval, sessionID: currentSessionID)
    }
    
    private func startMetronomeLoop(interval: TimeInterval, sessionID: UUID) {
        metronomeTask?.cancel()
        metronomeTask = Task { @MainActor [weak self] in
            while let self = self, self.isPlaying, self.sessionID == sessionID {
                self.checkAndPlayBeat(interval: interval)
                try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            }
        }
    }
    
    private func checkAndPlayBeat(interval: TimeInterval) {
        let currentTime = CACurrentMediaTime()
        
        if currentTime >= nextBeatTime {
            playBeat()
            nextBeatTime += interval
            
            // Prevent drift accumulation
            if nextBeatTime < currentTime {
                nextBeatTime = currentTime + interval
            }
        }
    }
    
    private func playBeat() {
        guard let playerNode = playerNode else { return }
        
        let isFirstBeat = currentBeat % beatsPerBar == 0
        let buffer = isFirstBeat ? accentBuffer : clickBuffer
        
        if let buffer = buffer {
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        }
        
        currentBeat += 1
    }
    
    private func stopInternal() {
        metronomeTask?.cancel()
        metronomeTask = nil
        isPlaying = false
        playerNode?.stop()
        audioEngine?.stop()
        currentBeat = 0
    }
    
    func stop() {
        sessionID = UUID() // Invalidate any running loops
        stopInternal()
    }
    
    func updateBPM(_ bpm: Int) {
        if isPlaying {
            let currentBeatsPerBar = beatsPerBar
            stop()
            currentBPM = bpm
            start(bpm: bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: currentBeatsPerBar)
        } else {
            currentBPM = bpm
        }
    }
    
    func changeSound(_ sound: MetronomeSound) {
        generateSoundBuffers(for: sound)
    }
    
    deinit {
        metronomeTask?.cancel()
        audioEngine?.stop()
    }
}

// MARK: - Setlist Player
@MainActor
class SetlistPlayer: ObservableObject {
    @Published var currentSongIndex: Int = 0
    @Published var isPlayingSetlist: Bool = false
    @Published var isRepeatEnabled: Bool = false
    @Published var elapsedTime: Int = 0
    
    private var songs: [Song] = []
    private var durationTask: Task<Void, Never>?
    let metronome = MetronomeEngine()
    
    var currentSong: Song? {
        guard currentSongIndex >= 0 && currentSongIndex < songs.count else { return nil }
        return songs[currentSongIndex]
    }
    
    var progress: Double {
        guard let song = currentSong, song.duration > 0 else { return 0 }
        return min(1.0, Double(elapsedTime) / Double(song.duration))
    }
    
    var remainingTime: Int {
        guard let song = currentSong, song.duration > 0 else { return 0 }
        return max(0, song.duration - elapsedTime)
    }
    
    var remainingTimeFormatted: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func loadSongs(_ songs: [Song]) {
        self.songs = songs.sorted { $0.order < $1.order }
    }
    
    func play(at index: Int) {
        guard index >= 0 && index < songs.count else { return }
        
        stopDurationTimer()
        metronome.stop()
        
        currentSongIndex = index
        elapsedTime = 0
        isPlayingSetlist = true
        
        let song = songs[index]
        metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
        startDurationTimer()
    }
    
    func playCurrentSong() {
        if let song = currentSong {
            stopDurationTimer()
            metronome.stop()
            elapsedTime = 0
            isPlayingSetlist = true
            metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
            startDurationTimer()
        }
    }
    
    func stop() {
        stopDurationTimer()
        metronome.stop()
        isPlayingSetlist = false
        elapsedTime = 0
    }
    
    func next() {
        stopDurationTimer()
        metronome.stop()
        
        if currentSongIndex < songs.count - 1 {
            currentSongIndex += 1
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
                startDurationTimer()
            }
        } else if isRepeatEnabled {
            currentSongIndex = 0
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
                startDurationTimer()
            }
        } else {
            // End of setlist, stop playing
            isPlayingSetlist = false
            elapsedTime = 0
        }
    }
    
    func previous() {
        stopDurationTimer()
        metronome.stop()
        
        if currentSongIndex > 0 {
            currentSongIndex -= 1
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
                startDurationTimer()
            }
        } else if isRepeatEnabled {
            currentSongIndex = songs.count - 1
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar)
                startDurationTimer()
            }
        }
    }
    
    func toggleRepeat() {
        isRepeatEnabled.toggle()
        AppSettings.shared.isRepeatEnabled = isRepeatEnabled
    }
    
    // MARK: - Duration Timer
    private func startDurationTimer() {
        guard let song = currentSong, song.duration > 0 else { return }
        
        durationTask = Task { [weak self] in
            while self?.isPlayingSetlist == true {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                guard let self = self, self.isPlayingSetlist else { break }
                
                self.elapsedTime += 1
                
                // Check if duration exceeded
                if let currentSong = self.currentSong,
                   currentSong.duration > 0,
                   self.elapsedTime >= currentSong.duration {
                    self.next()
                    break
                }
            }
        }
    }
    
    private func stopDurationTimer() {
        durationTask?.cancel()
        durationTask = nil
    }
}
