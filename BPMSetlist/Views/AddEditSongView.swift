//
//  AddEditSongView.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI

struct AddEditSongView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localization = LocalizationManager.shared
    
    let song: Song?
    let onSave: (String, Int, Int, Int, DurationType, Int, Int) -> Void // title, bpm, duration, durationBars, durationType, beatsPerBar, beatUnit
    let onDelete: (() -> Void)?
    
    @State private var title: String = ""
    @State private var bpm: Int = 120
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 0
    @State private var durationBars: Int = 8
    @State private var durationType: DurationType = .manual
    @State private var beatsPerBar: Int = 4
    @State private var beatUnit: Int = 4
    @State private var showDeleteConfirmation: Bool = false
    
    @StateObject private var previewMetronome = MetronomeEngine()
    
    private var isEditing: Bool { song != nil }
    
    private var totalDuration: Int {
        durationMinutes * 60 + durationSeconds
    }
    
    // メイン拍子（大きく表示）
    private let mainTimeSignatures: [(Int, Int)] = [
        (4, 4), (3, 4), (6, 8), (8, 8)
    ]
    
    // サブ拍子（小さく表示）
    private let subTimeSignatures: [(Int, Int)] = [
        (2, 4), (5, 4), (6, 4), (7, 4),
        (2, 2), (3, 2), (4, 2),
        (3, 8), (5, 8), (7, 8), (9, 8), (12, 8),
        (2, 8), (4, 8)
    ]
    
    init(song: Song? = nil, onSave: @escaping (String, Int, Int, Int, DurationType, Int, Int) -> Void, onDelete: (() -> Void)? = nil) {
        self.song = song
        self.onSave = onSave
        self.onDelete = onDelete
        _title = State(initialValue: song?.title ?? "")
        _bpm = State(initialValue: song?.bpm ?? 120)
        _beatsPerBar = State(initialValue: song?.beatsPerBar ?? 4)
        _beatUnit = State(initialValue: song?.beatUnit ?? 4)
        _durationType = State(initialValue: song?.durationType ?? .manual)
        _durationBars = State(initialValue: song?.durationBars ?? 8)
        
        let duration = song?.duration ?? 0
        _durationMinutes = State(initialValue: duration / 60)
        _durationSeconds = State(initialValue: duration % 60)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Title Input
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text(localization.localized(.title))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            TextField(localization.localized(.songName), text: $title)
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.cardBackground)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // BPM Input with Preview
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Text(localization.localized(.bpm))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Colors.textMuted)
                                
                                Spacer()
                                
                                // Preview Button
                                Button {
                                    togglePreview()
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.xs) {
                                        Image(systemName: previewMetronome.isPlaying ? "stop.fill" : "play.fill")
                                        Text(previewMetronome.isPlaying ? localization.localized(.stop) : localization.localized(.preview))
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(previewMetronome.isPlaying ? AppTheme.Colors.background : AppTheme.Colors.accentGold)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.vertical, AppTheme.Spacing.sm)
                                    .background(
                                        Capsule()
                                            .fill(previewMetronome.isPlaying ? AppTheme.Colors.playing : AppTheme.Colors.accentGold.opacity(0.2))
                                    )
                                }
                            }
                            
                            VStack(spacing: AppTheme.Spacing.lg) {
                                // Large BPM Display with beat indicator
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    if previewMetronome.isPlaying {
                                        BeatIndicatorView(
                                            engine: previewMetronome,
                                            isActive: previewMetronome.isPlaying,
                                            style: .expanded
                                        )
                                    }
                                    
                                    Text("\(bpm)")
                                        .font(AppTheme.Typography.bpmDisplay)
                                        .foregroundColor(previewMetronome.isPlaying ? AppTheme.Colors.playing : AppTheme.Colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                }
                                .padding(.vertical, AppTheme.Spacing.md)
                                
                                // BPM Slider
                                HStack {
                                    Text("20")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textMuted)
                                    
                                    Slider(value: Binding(
                                        get: { Double(bpm) },
                                        set: { 
                                            bpm = Int($0)
                                            if previewMetronome.isPlaying {
                                                previewMetronome.updateBPM(bpm)
                                            }
                                        }
                                    ), in: 20...300, step: 1)
                                    .tint(AppTheme.Colors.accentGold)
                                    
                                    Text("300")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textMuted)
                                }
                                
                                // Quick BPM Buttons
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach([-10, -5, -1, 1, 5, 10], id: \.self) { delta in
                                        Button {
                                            bpm = max(20, min(300, bpm + delta))
                                            if previewMetronome.isPlaying {
                                                previewMetronome.updateBPM(bpm)
                                            }
                                        } label: {
                                            Text(delta > 0 ? "+\(delta)" : "\(delta)")
                                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                                .foregroundColor(AppTheme.Colors.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppTheme.Spacing.sm)
                                                .background(AppTheme.Colors.cardBackgroundElevated)
                                                .cornerRadius(AppTheme.CornerRadius.small)
                                        }
                                    }
                                }
                                
                                // Preset BPM Buttons
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Text(localization.localized(.presets))
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.Colors.textMuted)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 4), spacing: AppTheme.Spacing.sm) {
                                        ForEach([60, 80, 100, 120, 140, 160, 180, 200], id: \.self) { preset in
                                            Button {
                                                bpm = preset
                                                if previewMetronome.isPlaying {
                                                    previewMetronome.updateBPM(bpm)
                                                }
                                            } label: {
                                                Text("\(preset)")
                                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                                    .foregroundColor(bpm == preset ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, AppTheme.Spacing.md)
                                                    .background(bpm == preset ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                    .cornerRadius(AppTheme.CornerRadius.small)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                        
                        // Time Signature Selection
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text(localization.localized(.timeSignature))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            VStack(spacing: AppTheme.Spacing.md) {
                                // Current Time Signature Display
                                Text("\(beatsPerBar)/\(beatUnit)")
                                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.sm)
                                
                                // Main Time Signatures (Large)
                                Text(localization.localized(.common))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach(mainTimeSignatures, id: \.0) { sig in
                                        let isSelected = beatsPerBar == sig.0 && beatUnit == sig.1
                                        Button {
                                            beatsPerBar = sig.0
                                            beatUnit = sig.1
                                            if previewMetronome.isPlaying {
                                                restartPreview()
                                            }
                                        } label: {
                                            Text("\(sig.0)/\(sig.1)")
                                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                                .foregroundColor(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppTheme.Spacing.lg)
                                                .background(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                .cornerRadius(AppTheme.CornerRadius.medium)
                                        }
                                    }
                                }
                                
                                // Sub Time Signatures (Small)
                                Text(localization.localized(.other))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, AppTheme.Spacing.sm)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
                                    ForEach(subTimeSignatures, id: \.0) { sig in
                                        let isSelected = beatsPerBar == sig.0 && beatUnit == sig.1
                                        Button {
                                            beatsPerBar = sig.0
                                            beatUnit = sig.1
                                            if previewMetronome.isPlaying {
                                                restartPreview()
                                            }
                                        } label: {
                                            Text("\(sig.0)/\(sig.1)")
                                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                                .foregroundColor(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppTheme.Spacing.sm)
                                                .background(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                .cornerRadius(AppTheme.CornerRadius.small)
                                        }
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                        
                        // Duration Input
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text(localization.localized(.duration))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            VStack(spacing: AppTheme.Spacing.md) {
                                Text(localization.localized(.durationDescription))
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textMuted)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Duration Type Selector
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach([DurationType.manual, DurationType.time, DurationType.bars], id: \.self) { type in
                                        Button {
                                            durationType = type
                                        } label: {
                                            Text(durationTypeLabel(type))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(durationType == type ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AppTheme.Spacing.md)
                                                .background(durationType == type ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                .cornerRadius(AppTheme.CornerRadius.medium)
                                        }
                                    }
                                }
                                
                                // Time Input (shown when durationType == .time)
                                if durationType == .time {
                                    HStack(spacing: AppTheme.Spacing.lg) {
                                        // Minutes
                                        VStack(spacing: AppTheme.Spacing.xs) {
                                            Text(localization.localized(.minutes))
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.Colors.textMuted)
                                            
                                            HStack(spacing: AppTheme.Spacing.sm) {
                                                Button {
                                                    if durationMinutes > 0 {
                                                        durationMinutes -= 1
                                                    }
                                                } label: {
                                                    Image(systemName: "minus")
                                                        .frame(width: 36, height: 36)
                                                        .background(AppTheme.Colors.cardBackgroundElevated)
                                                        .cornerRadius(AppTheme.CornerRadius.small)
                                                }
                                                
                                                Text("\(durationMinutes)")
                                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                                    .frame(width: 50)
                                                
                                                Button {
                                                    if durationMinutes < 30 {
                                                        durationMinutes += 1
                                                    }
                                                } label: {
                                                    Image(systemName: "plus")
                                                        .frame(width: 36, height: 36)
                                                        .background(AppTheme.Colors.cardBackgroundElevated)
                                                        .cornerRadius(AppTheme.CornerRadius.small)
                                                }
                                            }
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        }
                                        
                                        Text(":")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(AppTheme.Colors.textMuted)
                                        
                                        // Seconds
                                        VStack(spacing: AppTheme.Spacing.xs) {
                                            Text(localization.localized(.seconds))
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.Colors.textMuted)
                                            
                                            HStack(spacing: AppTheme.Spacing.sm) {
                                                Button {
                                                    if durationSeconds > 0 {
                                                        durationSeconds -= 1
                                                    } else if durationMinutes > 0 {
                                                        durationMinutes -= 1
                                                        durationSeconds = 59
                                                    }
                                                } label: {
                                                    Image(systemName: "minus")
                                                        .frame(width: 36, height: 36)
                                                        .background(AppTheme.Colors.cardBackgroundElevated)
                                                        .cornerRadius(AppTheme.CornerRadius.small)
                                                }
                                                
                                                Text(String(format: "%02d", durationSeconds))
                                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                                    .frame(width: 50)
                                                
                                                Button {
                                                    if durationSeconds < 59 {
                                                        durationSeconds += 1
                                                    } else {
                                                        durationSeconds = 0
                                                        if durationMinutes < 30 {
                                                            durationMinutes += 1
                                                        }
                                                    }
                                                } label: {
                                                    Image(systemName: "plus")
                                                        .frame(width: 36, height: 36)
                                                        .background(AppTheme.Colors.cardBackgroundElevated)
                                                        .cornerRadius(AppTheme.CornerRadius.small)
                                                }
                                            }
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        }
                                    }
                                    
                                    // Quick time presets
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        ForEach([(60, "1:00"), (180, "3:00"), (240, "4:00"), (300, "5:00")], id: \.0) { seconds, label in
                                            Button {
                                                durationMinutes = seconds / 60
                                                durationSeconds = seconds % 60
                                            } label: {
                                                Text(label)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(totalDuration == seconds ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, AppTheme.Spacing.sm)
                                                    .background(totalDuration == seconds ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                    .cornerRadius(AppTheme.CornerRadius.small)
                                            }
                                        }
                                    }
                                }
                                
                                // Bars Input (shown when durationType == .bars)
                                if durationType == .bars {
                                    VStack(spacing: AppTheme.Spacing.md) {
                                        // Bars count with stepper
                                        HStack(spacing: AppTheme.Spacing.md) {
                                            Button {
                                                if durationBars > 1 {
                                                    durationBars -= 1
                                                }
                                            } label: {
                                                Image(systemName: "minus")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .frame(width: 50, height: 50)
                                                    .background(AppTheme.Colors.cardBackgroundElevated)
                                                    .cornerRadius(AppTheme.CornerRadius.medium)
                                            }
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                            
                                            VStack(spacing: 2) {
                                                Text("\(durationBars)")
                                                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                                                    .foregroundColor(AppTheme.Colors.accentGold)
                                                Text(localization.localized(.bars))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppTheme.Colors.textMuted)
                                            }
                                            .frame(minWidth: 120)
                                            
                                            Button {
                                                if durationBars < 999 {
                                                    durationBars += 1
                                                }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .frame(width: 50, height: 50)
                                                    .background(AppTheme.Colors.cardBackgroundElevated)
                                                    .cornerRadius(AppTheme.CornerRadius.medium)
                                            }
                                            .foregroundColor(AppTheme.Colors.textPrimary)
                                        }
                                        
                                        // Quick bars presets
                                        HStack(spacing: AppTheme.Spacing.sm) {
                                            ForEach([4, 8, 16, 32], id: \.self) { bars in
                                                Button {
                                                    durationBars = bars
                                                } label: {
                                                    Text("\(bars)")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(durationBars == bars ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                                        .frame(maxWidth: .infinity)
                                                        .padding(.vertical, AppTheme.Spacing.md)
                                                        .background(durationBars == bars ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackgroundElevated)
                                                        .cornerRadius(AppTheme.CornerRadius.small)
                                                }
                                            }
                                        }
                                        
                                        // Estimated time display
                                        let estimatedSeconds = calculateBarsToSeconds()
                                        if estimatedSeconds > 0 {
                                            Text("≈ \(formatSeconds(estimatedSeconds)) @ \(bpm) BPM")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.Colors.textMuted)
                                        }
                                    }
                                }
                                
                                // Manual mode display
                                if durationType == .manual {
                                    Text("∞")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(AppTheme.Colors.textMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppTheme.Spacing.lg)
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                        
                        // Delete Button (only for editing)
                        if isEditing {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text(localization.localized(.deleteSong))
                                }
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.Colors.stopped)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.cardBackground)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(AppTheme.Colors.stopped.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationTitle(isEditing ? localization.localized(.editSong) : localization.localized(.addSong))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized(.cancel)) {
                        previewMetronome.stop()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localized(.save)) {
                        previewMetronome.stop()
                        onSave(title.isEmpty ? localization.localized(.untitled) : title, bpm, totalDuration, durationBars, durationType, beatsPerBar, beatUnit)
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.accentGold)
                    .fontWeight(.semibold)
                }
            }
            .alert(localization.localized(.deleteSong), isPresented: $showDeleteConfirmation) {
                Button(localization.localized(.cancel), role: .cancel) {}
                Button(localization.localized(.delete), role: .destructive) {
                    previewMetronome.stop()
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("\(localization.localized(.deleteConfirmation)) \"\(song?.title ?? "")\"?")
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            previewMetronome.stop()
        }
    }
    
    private func togglePreview() {
        if previewMetronome.isPlaying {
            previewMetronome.stop()
        } else {
            previewMetronome.start(bpm: bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
        }
    }
    
    private func restartPreview() {
        previewMetronome.stop()
        previewMetronome.start(bpm: bpm, sound: AppSettings.shared.selectedSound, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
    }
    
    private func durationTypeLabel(_ type: DurationType) -> String {
        switch type {
        case .manual:
            return "∞ " + localization.localized(.manual)
        case .time:
            return localization.localized(.time)
        case .bars:
            return localization.localized(.bars)
        }
    }
    
    private func calculateBarsToSeconds() -> Int {
        // 複合拍子かどうかを判定（6/8, 9/8, 12/8など）
        let isCompoundMeter = beatUnit == 8 && beatsPerBar % 3 == 0
        
        let secondsPerBar: Double
        if isCompoundMeter {
            // 複合拍子: BPMは付点四分音符の数を指す
            // 基本拍の数 = beatsPerBar / 3
            let mainBeatsPerBar = Double(beatsPerBar) / 3.0
            secondsPerBar = mainBeatsPerBar * (60.0 / Double(bpm))
        } else {
            // 単純拍子: BPMは四分音符の数を指す
            let secondsPerBeat = 60.0 / Double(bpm) * (4.0 / Double(beatUnit))
            secondsPerBar = secondsPerBeat * Double(beatsPerBar)
        }
        
        return Int(secondsPerBar * Double(durationBars))
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Preview
#Preview("Add") {
    AddEditSongView(onSave: { _, _, _, _, _, _, _ in })
}

#Preview("Edit") {
    AddEditSongView(
        song: Song(title: "Test Song", bpm: 120, duration: 180, durationBars: 8, durationType: .time, beatsPerBar: 4, beatUnit: 4),
        onSave: { _, _, _, _, _, _, _ in },
        onDelete: {}
    )
}
