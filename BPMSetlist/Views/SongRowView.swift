//
//  SongRowView.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI

struct SongRowView: View {
    @ObservedObject var localization = LocalizationManager.shared
    
    let song: Song
    let index: Int
    let isPlaying: Bool
    let isSelected: Bool
    let height: CGFloat
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var bpmFontSize: CGFloat {
        if height > 120 {
            return 48
        } else if height > 90 {
            return 36
        } else {
            return 28
        }
    }
    
    private var titleFontSize: CGFloat {
        if height > 120 {
            return 22
        } else if height > 90 {
            return 18
        } else {
            return 16
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Drag Handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppTheme.Colors.textMuted)
                .frame(width: 44, height: height)
            
            // Main Content (Tappable for play)
            Button(action: onTap) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    // Order Number
                    Text("\(index + 1)")
                        .font(.system(size: titleFontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.Colors.textMuted)
                        .frame(width: 28)
                    
                    // Song Info
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(song.title)
                            .font(.system(size: titleFontSize, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: AppTheme.Spacing.sm) {
                            if isPlaying {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(AppTheme.Colors.playing)
                                        .frame(width: 8, height: 8)
                                        .shadow(color: AppTheme.Colors.playing.opacity(0.5), radius: 4)
                                    
                                    Text(localization.localized(.playing))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.playing)
                                }
                            }
                            
                            // Time Signature
                            Text(song.timeSignatureDisplay)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(AppTheme.Colors.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.Colors.cardBackgroundElevated)
                                .cornerRadius(4)
                            
                            // Duration
                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(song.formattedDuration)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                            }
                            .foregroundColor(AppTheme.Colors.textMuted)
                        }
                    }
                    
                    Spacer()
                    
                    // BPM Display
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(song.bpm)")
                            .font(.system(size: bpmFontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(isPlaying ? AppTheme.Colors.playing : AppTheme.Colors.textPrimary)
                        
                        Text("BPM")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textMuted)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .frame(height: height)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Edit Button (Right side)
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            .frame(width: 50, height: height)
        }
        .cardStyle(isSelected: isSelected)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    List {
        SongRowView(
            song: Song(title: "Opening Night", bpm: 120, order: 0, duration: 180, durationBars: 0, durationType: .time, beatsPerBar: 4, beatUnit: 4),
            index: 0,
            isPlaying: true,
            isSelected: true,
            height: 100,
            onTap: {},
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        
        SongRowView(
            song: Song(title: "Verse Section", bpm: 90, order: 1, duration: 0, durationBars: 8, durationType: .bars, beatsPerBar: 6, beatUnit: 8),
            index: 1,
            isPlaying: false,
            isSelected: false,
            height: 100,
            onTap: {},
            onEdit: {},
            onDelete: {}
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    .listStyle(.plain)
    .background(AppTheme.Colors.background)
}
