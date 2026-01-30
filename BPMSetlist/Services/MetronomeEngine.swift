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
    private var sessionID: UUID = UUID()
    private var scheduledBeatsCount: Int = 0
    private let beatsToScheduleAhead: Int = 4 // Schedule 4 beats ahead
    private var lastScheduledSampleTime: AVAudioFramePosition = 0
    private var isScheduling: Bool = false
    
    private let sampleRate: Double = 44100
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Remove .mixWithOthers for reliable background playback
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Handle interruptions
            NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        Task { @MainActor in
            switch type {
            case .began:
                // Interruption began (e.g., phone call)
                break
            case .ended:
                // Interruption ended, try to resume
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && self.isPlaying {
                        // Resume playback
                        try? AVAudioSession.sharedInstance().setActive(true)
                        self.playerNode?.play()
                        self.scheduleBeats()
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Sound Generation
    private func generateClickBuffer(frequency: Double, duration: Double, isAccent: Bool) -> AVAudioPCMBuffer? {
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
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
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
        
        // Create new session ID to invalidate old scheduling
        sessionID = UUID()
        
        setupAudioSession()
        setupAudioEngine()
        generateSoundBuffers(for: sound)
        
        currentBPM = bpm
        self.beatsPerBar = beatsPerBar
        currentBeat = 0
        scheduledBeatsCount = 0
        isPlaying = true
        isScheduling = false
        
        guard let playerNode = playerNode else { return }
        
        playerNode.play()
        
        // Get the current sample time
        if let lastRenderTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) {
            lastScheduledSampleTime = playerTime.sampleTime
        } else {
            lastScheduledSampleTime = 0
        }
        
        // Schedule initial beats
        scheduleBeats()
    }
    
    private func scheduleBeats() {
        guard isPlaying, !isScheduling else { return }
        isScheduling = true
        
        let currentSessionID = sessionID
        
        guard let playerNode = playerNode,
              let clickBuffer = clickBuffer,
              let accentBuffer = accentBuffer else {
            isScheduling = false
            return
        }
        
        let samplesPerBeat = AVAudioFramePosition(sampleRate * 60.0 / Double(currentBPM))
        
        // Schedule multiple beats ahead
        for i in 0..<beatsToScheduleAhead {
            guard sessionID == currentSessionID, isPlaying else { break }
            
            let beatNumber = scheduledBeatsCount + i
            let isFirstBeat = beatNumber % beatsPerBar == 0
            let buffer = isFirstBeat ? accentBuffer : clickBuffer
            
            let sampleTime = lastScheduledSampleTime + AVAudioFramePosition(i) * samplesPerBeat
            let time = AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
            
            // Schedule buffer with completion handler for the last beat
            if i == beatsToScheduleAhead - 1 {
                playerNode.scheduleBuffer(buffer, at: time, options: []) { [weak self] in
                    Task { @MainActor in
                        guard let self = self, self.sessionID == currentSessionID, self.isPlaying else { return }
                        self.scheduledBeatsCount += self.beatsToScheduleAhead
                        self.lastScheduledSampleTime += AVAudioFramePosition(self.beatsToScheduleAhead) * samplesPerBeat
                        self.isScheduling = false
                        self.scheduleBeats()
                    }
                }
            } else {
                playerNode.scheduleBuffer(buffer, at: time, options: []) { [weak self] in
                    Task { @MainActor in
                        guard let self = self, self.sessionID == currentSessionID else { return }
                        self.currentBeat = (self.currentBeat + 1) % self.beatsPerBar
                    }
                }
            }
        }
        
        // Update current beat display
        currentBeat = scheduledBeatsCount % beatsPerBar
    }
    
    private func stopInternal() {
        isPlaying = false
        isScheduling = false
        playerNode?.stop()
        audioEngine?.stop()
        currentBeat = 0
        scheduledBeatsCount = 0
        lastScheduledSampleTime = 0
    }
    
    func stop() {
        sessionID = UUID() // Invalidate any scheduled callbacks
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
        NotificationCenter.default.removeObserver(self)
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
    private var durationTimer: Timer?
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
    
    // MARK: - Duration Timer (Using Timer for background compatibility)
    private func startDurationTimer() {
        guard let song = currentSong, song.duration > 0 else { return }
        
        stopDurationTimer()
        
        // Use Timer which works in background with audio session active
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.isPlayingSetlist else { return }
                
                self.elapsedTime += 1
                
                // Check if duration exceeded
                if let currentSong = self.currentSong,
                   currentSong.duration > 0,
                   self.elapsedTime >= currentSong.duration {
                    self.next()
                }
            }
        }
        
        // Add timer to common run loop mode for background execution
        if let timer = durationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}
