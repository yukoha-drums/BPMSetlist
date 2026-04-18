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
    @Published var beatTick: Int = 0
    @Published var beatsPerBar: Int = 4
    @Published var beatUnit: Int = 4
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    
    private let sampleRate: Double = 44100
    private var currentSound: MetronomeSound = .click
    
    // Audio generation state (accessed from audio thread)
    private var sampleTime: Int64 = 0
    private var samplesPerBeat: Int64 = 0
    private var clickSamples: [Float] = []
    private var accentSamples: [Float] = []
    private var beatCounter: Int = 0
    private var beatsPerBarAtomic: Int = 4
    
    // Thread-safe communication
    private let lock = NSLock()
    private var _isGenerating: Bool = false
    
    private var isGenerating: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _isGenerating }
        set { lock.lock(); defer { lock.unlock() }; _isGenerating = newValue }
    }
    
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
                self.isGenerating = false
            case .ended:
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) && self.isPlaying {
                        try? AVAudioSession.sharedInstance().setActive(true)
                        self.restartEngine()
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    private func restartEngine() {
        guard isPlaying else { return }
        let bpm = currentBPM
        let beats = beatsPerBar
        let unit = beatUnit
        let sound = currentSound
        stopInternal()
        start(bpm: bpm, sound: sound, beatsPerBar: beats, beatUnit: unit)
    }
    
    // MARK: - Sound Generation
    private func generateClickSamples(frequency: Double, isAccent: Bool) -> [Float] {
        let clickDuration: Double = 0.025
        let frameCount = Int(sampleRate * clickDuration)
        var samples = [Float](repeating: 0, count: frameCount)
        
        let amplitude: Float = isAccent ? 0.85 : 0.55
        
        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            let envelope = Float(exp(-time * 200))
            
            var sample: Float = 0
            sample += sin(Float(2.0 * .pi * frequency * time)) * 1.0
            sample += sin(Float(2.0 * .pi * frequency * 2.0 * time)) * 0.5
            sample += sin(Float(2.0 * .pi * frequency * 3.0 * time)) * 0.25
            
            if time < 0.002 {
                sample += Float.random(in: -0.3...0.3)
            }
            
            samples[frame] = sample * amplitude * envelope
        }
        
        return samples
    }
    
    private func prepareSoundSamples(for sound: MetronomeSound) {
        let baseFrequency: Double
        
        switch sound {
        case .click: baseFrequency = 1000
        case .woodblock: baseFrequency = 800
        case .hihat: baseFrequency = 3000
        case .rimshot: baseFrequency = 1200
        case .cowbell: baseFrequency = 600
        }
        
        clickSamples = generateClickSamples(frequency: baseFrequency, isAccent: false)
        accentSamples = generateClickSamples(frequency: baseFrequency * 1.5, isAccent: true)
    }
    
    // MARK: - Engine Setup
    private func setupEngine(bpm: Int, beatsPerBar: Int, beatUnit: Int) {
        audioEngine?.stop()
        audioEngine = nil
        sourceNode = nil
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        // Calculate samples per beat based on time signature type
        let adjustedBPM = Self.calculateAdjustedBPM(bpm: bpm, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
        samplesPerBeat = Int64(sampleRate * 60.0 / adjustedBPM)
        beatsPerBarAtomic = beatsPerBar
        sampleTime = 0
        beatCounter = 0
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Create source node that generates audio in real-time
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self, self.isGenerating else {
                // Fill with silence when not generating
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buffer in ablPointer {
                    memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                }
                return noErr
            }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                
                // Calculate position within the current beat
                let positionInBeat = self.sampleTime % self.samplesPerBeat
                
                // Determine if this is a click position
                if positionInBeat == 0 {
                    // Start of a new beat
                    let isAccent = self.beatCounter % self.beatsPerBarAtomic == 0
                    
                    // Update beat counter for UI (will be picked up by main thread)
                    let newBeat = self.beatCounter % self.beatsPerBarAtomic
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.currentBeat = newBeat
                        // Monotonically increasing tick so SwiftUI onChange always fires,
                        // even when beatsPerBar == 1 or the value otherwise repeats.
                        self.beatTick &+= 1
                    }
                    
                    self.beatCounter += 1
                }
                
                // Get sample from click/accent buffer if within click duration
                if positionInBeat < Int64(self.clickSamples.count) {
                    let beatInBar = (self.beatCounter - 1) % self.beatsPerBarAtomic
                    let isAccent = beatInBar == 0
                    let samples = isAccent ? self.accentSamples : self.clickSamples
                    sample = samples[Int(positionInBeat)]
                } else {
                    // Very quiet noise between clicks to keep audio session alive
                    sample = Float.random(in: -0.0001...0.0001)
                }
                
                // Write to all buffers
                for buffer in ablPointer {
                    let buf = buffer.mData?.assumingMemoryBound(to: Float.self)
                    buf?[frame] = sample
                }
                
                self.sampleTime += 1
            }
            
            return noErr
        }
        
        guard let sourceNode = sourceNode else { return }
        
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - BPM Calculation
    /// Calculate the adjusted BPM based on time signature
    /// - Compound meters (6/8, 9/8, 12/8): BPM refers to dotted quarter notes
    /// - Simple meters (4/4, 3/4, etc.): BPM refers to quarter notes
    static func calculateAdjustedBPM(bpm: Int, beatsPerBar: Int, beatUnit: Int) -> Double {
        // Compound meter detection: 6/8, 9/8, 12/8, etc.
        // beatsPerBar is divisible by 3 and beatUnit is 8
        let isCompoundMeter = beatUnit == 8 && beatsPerBar % 3 == 0
        
        if isCompoundMeter {
            // Compound meter: BPM = dotted quarter notes per minute
            // Each dotted quarter = 3 eighth notes
            // So actual eighth note rate = BPM * 3
            return Double(bpm) * 3.0
        } else {
            // Simple meter: BPM = quarter notes per minute
            // Adjust for beatUnit: 4=quarter, 8=eighth(2x), 2=half(0.5x), 16=sixteenth(4x)
            return Double(bpm) * Double(beatUnit) / 4.0
        }
    }
    
    // MARK: - Playback Control
    func start(bpm: Int, sound: MetronomeSound = .click, beatsPerBar: Int = 4, beatUnit: Int = 4) {
        stopInternal()
        
        setupAudioSession()
        prepareSoundSamples(for: sound)
        
        currentBPM = bpm
        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
        currentBeat = 0
        currentSound = sound
        
        setupEngine(bpm: bpm, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
        
        isPlaying = true
        isGenerating = true
    }
    
    private func stopInternal() {
        isGenerating = false
        isPlaying = false
        
        audioEngine?.stop()
        sourceNode = nil
        audioEngine = nil
        
        sampleTime = 0
        beatCounter = 0
        currentBeat = 0
        beatTick = 0
    }
    
    func stop() {
        stopInternal()
    }
    
    func updateBPM(_ bpm: Int) {
        if isPlaying {
            let beats = beatsPerBar
            let unit = beatUnit
            let sound = currentSound
            stop()
            currentBPM = bpm
            start(bpm: bpm, sound: sound, beatsPerBar: beats, beatUnit: unit)
        } else {
            currentBPM = bpm
        }
    }
    
    func changeSound(_ sound: MetronomeSound) {
        currentSound = sound
        prepareSoundSamples(for: sound)
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
        guard let song = currentSong else { return 0 }
        let totalDuration = song.calculateDurationInSeconds()
        guard totalDuration > 0 else { return 0 }
        return min(1.0, Double(elapsedTime) / Double(totalDuration))
    }
    
    var remainingTime: Int {
        guard let song = currentSong else { return 0 }
        let totalDuration = song.calculateDurationInSeconds()
        guard totalDuration > 0 else { return 0 }
        return max(0, totalDuration - elapsedTime)
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
        metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
        startDurationTimer()
    }
    
    func playCurrentSong() {
        if let song = currentSong {
            stopDurationTimer()
            metronome.stop()
            elapsedTime = 0
            isPlayingSetlist = true
            metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
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
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
                startDurationTimer()
            }
        } else if isRepeatEnabled {
            currentSongIndex = 0
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
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
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
                startDurationTimer()
            }
        } else if isRepeatEnabled {
            currentSongIndex = songs.count - 1
            elapsedTime = 0
            if isPlayingSetlist {
                let song = songs[currentSongIndex]
                metronome.start(bpm: song.bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: song.beatsPerBar, beatUnit: song.beatUnit)
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
        guard let song = currentSong else { return }
        let totalDuration = song.calculateDurationInSeconds()
        guard totalDuration > 0 else { return }
        
        stopDurationTimer()
        
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self, self.isPlayingSetlist else { return }
                
                self.elapsedTime += 1
                
                if let currentSong = self.currentSong {
                    let duration = currentSong.calculateDurationInSeconds()
                    if duration > 0 && self.elapsedTime >= duration {
                        self.next()
                    }
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
