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
    private var sessionID: UUID = UUID()
    
    private let sampleRate: Double = 44100
    private var currentSound: MetronomeSound = .click
    
    // MARK: - Initialization
    init() {
        setupAudioSession()
        setupNotifications()
    }
    
    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            switch type {
            case .began:
                break
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && self.isPlaying {
                        try? AVAudioSession.sharedInstance().setActive(true)
                        self.restartPlayback()
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if reason == .oldDeviceUnavailable && self.isPlaying {
                self.restartPlayback()
            }
        }
    }
    
    private func restartPlayback() {
        let bpm = currentBPM
        let beats = beatsPerBar
        let sound = currentSound
        stop()
        start(bpm: bpm, sound: sound, beatsPerBar: beats)
    }
    
    // MARK: - Sound Generation
    private func generateBeatBuffer(frequency: Double, isAccent: Bool) -> AVAudioPCMBuffer? {
        let clickDuration: Double = 0.03
        let frameCount = AVAudioFrameCount(sampleRate * clickDuration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        let amplitude: Float = isAccent ? 0.9 : 0.6
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = Float(exp(-time * 150)) // Fast decay
            
            var sample: Float = 0
            sample += sin(Float(2.0 * .pi * frequency * time)) * 1.0
            sample += sin(Float(2.0 * .pi * frequency * 2 * time)) * 0.5
            sample += sin(Float(2.0 * .pi * frequency * 3 * time)) * 0.25
            
            if time < 0.003 {
                sample += Float.random(in: -0.4...0.4)
            }
            
            channelData[frame] = sample * amplitude * envelope
        }
        
        return buffer
    }
    
    private func generateSilenceBuffer(duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        // Fill with near-silence (very quiet noise to keep audio session alive)
        if let channelData = buffer.floatChannelData?[0] {
            for frame in 0..<Int(frameCount) {
                channelData[frame] = Float.random(in: -0.0001...0.0001)
            }
        }
        
        return buffer
    }
    
    private func generateFullBeatBuffer(bpm: Int, beatsPerBar: Int, sound: MetronomeSound) -> AVAudioPCMBuffer? {
        let beatInterval = 60.0 / Double(bpm)
        let totalDuration = beatInterval * Double(beatsPerBar)
        let totalFrames = AVAudioFrameCount(sampleRate * totalDuration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            return nil
        }
        
        buffer.frameLength = totalFrames
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }
        
        // Fill with near-silence first
        for frame in 0..<Int(totalFrames) {
            channelData[frame] = Float.random(in: -0.0001...0.0001)
        }
        
        let baseFrequency: Double
        switch sound {
        case .click: baseFrequency = 1000
        case .woodblock: baseFrequency = 800
        case .hihat: baseFrequency = 3000
        case .rimshot: baseFrequency = 1200
        case .cowbell: baseFrequency = 600
        }
        
        // Add clicks at beat positions
        for beat in 0..<beatsPerBar {
            let isAccent = beat == 0
            let frequency = isAccent ? baseFrequency * 1.5 : baseFrequency
            let amplitude: Float = isAccent ? 0.9 : 0.6
            
            let beatStartFrame = Int(Double(beat) * beatInterval * sampleRate)
            let clickDuration = 0.03
            let clickFrames = Int(sampleRate * clickDuration)
            
            for frame in 0..<clickFrames {
                let targetFrame = beatStartFrame + frame
                guard targetFrame < Int(totalFrames) else { break }
                
                let time = Double(frame) / sampleRate
                let envelope = Float(exp(-time * 150))
                
                var sample: Float = 0
                sample += sin(Float(2.0 * .pi * frequency * time)) * 1.0
                sample += sin(Float(2.0 * .pi * frequency * 2 * time)) * 0.5
                sample += sin(Float(2.0 * .pi * frequency * 3 * time)) * 0.25
                
                if time < 0.003 {
                    sample += Float.random(in: -0.4...0.4)
                }
                
                channelData[targetFrame] = sample * amplitude * envelope
            }
        }
        
        return buffer
    }
    
    // MARK: - Engine Setup
    private func setupAudioEngine() {
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
        stop()
        
        sessionID = UUID()
        let currentSessionID = sessionID
        
        setupAudioSession()
        setupAudioEngine()
        
        currentBPM = bpm
        self.beatsPerBar = beatsPerBar
        currentBeat = 0
        currentSound = sound
        isPlaying = true
        
        guard let playerNode = playerNode else { return }
        
        playerNode.play()
        
        // Schedule multiple buffers ahead for seamless playback
        scheduleMultipleBuffers(count: 3, sessionID: currentSessionID)
    }
    
    private func scheduleMultipleBuffers(count: Int, sessionID: UUID) {
        guard self.sessionID == sessionID, isPlaying else { return }
        
        guard let playerNode = playerNode else { return }
        
        for i in 0..<count {
            guard let buffer = generateFullBeatBuffer(bpm: currentBPM, beatsPerBar: beatsPerBar, sound: currentSound) else {
                continue
            }
            
            if i == count - 1 {
                // Last buffer: schedule more when it starts playing
                playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self = self, self.sessionID == sessionID, self.isPlaying else { return }
                        // Schedule more buffers to keep the queue filled
                        self.scheduleMultipleBuffers(count: 2, sessionID: sessionID)
                    }
                }
            } else {
                // Other buffers: just schedule without callback
                playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            }
        }
        
        // Start beat counter if not already running
        startBeatCounter(sessionID: sessionID)
    }
    
    private func startBeatCounter(sessionID: UUID) {
        guard self.sessionID == sessionID, isPlaying else { return }
        
        let beatInterval = 60.0 / Double(currentBPM)
        let barDuration = beatInterval * Double(beatsPerBar)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            while self.sessionID == sessionID && self.isPlaying {
                for beat in 0..<self.beatsPerBar {
                    guard self.sessionID == sessionID, self.isPlaying else { return }
                    
                    self.currentBeat = beat
                    
                    try? await Task.sleep(nanoseconds: UInt64(beatInterval * 1_000_000_000))
                }
            }
        }
    }
    
    func stop() {
        sessionID = UUID()
        isPlaying = false
        playerNode?.stop()
        audioEngine?.stop()
        currentBeat = 0
    }
    
    func updateBPM(_ bpm: Int) {
        if isPlaying {
            let beats = beatsPerBar
            let sound = currentSound
            stop()
            currentBPM = bpm
            start(bpm: bpm, sound: sound, beatsPerBar: beats)
        } else {
            currentBPM = bpm
        }
    }
    
    func changeSound(_ sound: MetronomeSound) {
        currentSound = sound
        if isPlaying {
            let bpm = currentBPM
            let beats = beatsPerBar
            stop()
            start(bpm: bpm, sound: sound, beatsPerBar: beats)
        }
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
        
        stopDurationTimer()
        
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self, self.isPlayingSetlist else { return }
                
                self.elapsedTime += 1
                
                if let currentSong = self.currentSong,
                   currentSong.duration > 0,
                   self.elapsedTime >= currentSong.duration {
                    self.next()
                }
            }
        }
        
        if let timer = durationTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}
