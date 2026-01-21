//
//  ContentView.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.order) private var songs: [Song]
    
    @StateObject private var player = SetlistPlayer()
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var localization = LocalizationManager.shared
    
    @State private var showAddSong: Bool = false
    @State private var showSettings: Bool = false
    @State private var editingSong: Song? = nil
    @State private var showSizeSlider: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Controls
                    headerControls
                    
                    if songs.isEmpty {
                        emptyStateView
                    } else {
                        songListView
                    }
                    
                    // Bottom Player Bar
                    if !songs.isEmpty {
                        bottomPlayerBar
                    }
                }
            }
            .navigationTitle(localization.localized(.appTitle))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSong = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accentGold)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddSong) {
            AddEditSongView(onSave: addSong)
        }
        .sheet(item: $editingSong) { song in
            AddEditSongView(
                song: song,
                onSave: { title, bpm, duration, beatsPerBar, beatUnit in
                    updateSong(song, title: title, bpm: bpm, duration: duration, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
                },
                onDelete: {
                    deleteSong(song)
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: songs) { _, newSongs in
            player.loadSongs(newSongs)
        }
        .onAppear {
            player.loadSongs(songs)
        }
    }
    
    // MARK: - Header Controls
    private var headerControls: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("\(songs.count) \(localization.localized(.songs))")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textMuted)
                
                Spacer()
                
                // Size Toggle Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSizeSlider.toggle()
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "textformat.size")
                        if showSizeSlider {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10))
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(showSizeSlider ? AppTheme.Colors.accentGold : AppTheme.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(showSizeSlider ? AppTheme.Colors.accentGold.opacity(0.2) : Color.clear)
                    )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            
            // Size Slider
            if showSizeSlider {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "minus")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textMuted)
                    
                    Slider(
                        value: $settings.listItemSize,
                        in: AppSettings.minListItemSize...AppSettings.maxListItemSize,
                        step: 1
                    )
                    .tint(AppTheme.Colors.accentGold)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textMuted)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(AppTheme.Colors.textMuted)
            
            Text(localization.localized(.noSongsYet))
                .font(AppTheme.Typography.title)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(localization.localized(.addFirstSong))
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textMuted)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSong = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(localization.localized(.addSong))
                }
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.background)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(AppTheme.Colors.accentGold)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
    
    // MARK: - Song List
    private var songListView: some View {
        List {
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                SongRowView(
                    song: song,
                    index: index,
                    isPlaying: player.isPlayingSetlist && player.currentSongIndex == index,
                    isSelected: player.currentSongIndex == index,
                    height: settings.listItemSize,
                    onTap: {
                        player.play(at: index)
                    },
                    onEdit: {
                        editingSong = song
                    },
                    onDelete: {
                        deleteSong(song)
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove(perform: moveSongs)
            
            // Bottom padding for player bar
            Color.clear
                .frame(height: 100)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Bottom Player Bar
    private var bottomPlayerBar: some View {
        VStack(spacing: 0) {
            // Progress bar for current song duration
            if player.isPlayingSetlist, let currentSong = player.currentSong, currentSong.duration > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppTheme.Colors.border)
                        
                        Rectangle()
                            .fill(AppTheme.Colors.accentGold)
                            .frame(width: geometry.size.width * player.progress)
                    }
                }
                .frame(height: 3)
            }
            
            HStack(spacing: AppTheme.Spacing.lg) {
                // Current Song Info
                if let currentSong = player.currentSong {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentSong.title)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Text("\(currentSong.bpm) BPM")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            Text(currentSong.timeSignatureDisplay)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            if currentSong.duration > 0 && player.isPlayingSetlist {
                                Text(player.remainingTimeFormatted)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(AppTheme.Colors.accentGold)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(localization.localized(.selectSong))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Controls
                HStack(spacing: AppTheme.Spacing.md) {
                    // Previous
                    Button {
                        player.previous()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    .frame(width: 44, height: 44)
                    
                    // Play/Stop
                    Button {
                        if player.metronome.isPlaying {
                            player.stop()
                        } else if player.currentSong != nil {
                            player.playCurrentSong()
                        } else if !songs.isEmpty {
                            player.play(at: 0)
                        }
                    } label: {
                        Image(systemName: player.metronome.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(player.metronome.isPlaying ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                    }
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(player.metronome.isPlaying ? AppTheme.Colors.playing : AppTheme.Colors.cardBackgroundElevated)
                    )
                    
                    // Next
                    Button {
                        player.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    .frame(width: 44, height: 44)
                }
                
                // Repeat Toggle
                Button {
                    player.toggleRepeat()
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 18))
                        .foregroundColor(player.isRepeatEnabled ? AppTheme.Colors.accentGold : AppTheme.Colors.textMuted)
                }
                .frame(width: 44, height: 44)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground)
        }
    }
    
    // MARK: - Actions
    private func addSong(title: String, bpm: Int, duration: Int, beatsPerBar: Int, beatUnit: Int) {
        withAnimation {
            let newSong = Song(title: title, bpm: bpm, order: songs.count, duration: duration, beatsPerBar: beatsPerBar, beatUnit: beatUnit)
            modelContext.insert(newSong)
        }
    }
    
    private func updateSong(_ song: Song, title: String, bpm: Int, duration: Int, beatsPerBar: Int, beatUnit: Int) {
        withAnimation {
            song.title = title
            song.bpm = bpm
            song.duration = duration
            song.beatsPerBar = beatsPerBar
            song.beatUnit = beatUnit
        }
    }
    
    private func deleteSong(_ song: Song) {
        withAnimation {
            modelContext.delete(song)
            // Reorder remaining songs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for (index, s) in songs.enumerated() {
                    s.order = index
                }
            }
        }
    }
    
    private func moveSongs(from source: IndexSet, to destination: Int) {
        var reorderedSongs = songs
        reorderedSongs.move(fromOffsets: source, toOffset: destination)
        
        for (index, song) in reorderedSongs.enumerated() {
            song.order = index
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .modelContainer(for: Song.self, inMemory: true)
}
