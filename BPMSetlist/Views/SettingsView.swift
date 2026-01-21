//
//  SettingsView.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var localization = LocalizationManager.shared
    @StateObject private var previewMetronome = MetronomeEngine()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Metronome Sound Selection
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text(localization.localized(.metronomeSound))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            VStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(MetronomeSound.allCases) { sound in
                                    Button {
                                        settings.selectedSound = sound
                                        previewSound(sound)
                                    } label: {
                                        HStack {
                                            Image(systemName: sound.iconName)
                                                .font(.system(size: 20))
                                                .foregroundColor(settings.selectedSound == sound ? AppTheme.Colors.accentGold : AppTheme.Colors.textSecondary)
                                                .frame(width: 30)
                                            
                                            Text(localizedSoundName(sound))
                                                .font(AppTheme.Typography.headline)
                                                .foregroundColor(settings.selectedSound == sound ? AppTheme.Colors.accentGold : AppTheme.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            if settings.selectedSound == sound {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppTheme.Colors.accentGold)
                                            }
                                        }
                                        .padding(AppTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .fill(settings.selectedSound == sound ? AppTheme.Colors.cardBackgroundElevated : AppTheme.Colors.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .stroke(settings.selectedSound == sound ? AppTheme.Colors.accentGold : AppTheme.Colors.border, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Count-in Bars
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text(localization.localized(.countInBars))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach([0, 1, 2, 4], id: \.self) { bars in
                                    Button {
                                        settings.countInBars = bars
                                    } label: {
                                        Text(bars == 0 ? localization.localized(.off) : "\(bars)")
                                            .font(AppTheme.Typography.headline)
                                            .foregroundColor(settings.countInBars == bars ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AppTheme.Spacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                    .fill(settings.countInBars == bars ? AppTheme.Colors.accentGold : AppTheme.Colors.cardBackground)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                    .stroke(settings.countInBars == bars ? AppTheme.Colors.accentGold : AppTheme.Colors.border, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Language Selection
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text(localization.localized(.language))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            VStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(AppLanguage.allCases) { language in
                                    Button {
                                        localization.currentLanguage = language
                                    } label: {
                                        HStack {
                                            Text(language.flag)
                                                .font(.system(size: 24))
                                                .frame(width: 36)
                                            
                                            Text(language.displayName)
                                                .font(AppTheme.Typography.headline)
                                                .foregroundColor(localization.currentLanguage == language ? AppTheme.Colors.accentGold : AppTheme.Colors.textPrimary)
                                            
                                            Spacer()
                                            
                                            if localization.currentLanguage == language {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppTheme.Colors.accentGold)
                                            }
                                        }
                                        .padding(AppTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .fill(localization.currentLanguage == language ? AppTheme.Colors.cardBackgroundElevated : AppTheme.Colors.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                                .stroke(localization.currentLanguage == language ? AppTheme.Colors.accentGold : AppTheme.Colors.border, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // App Info
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text(localization.localized(.about))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textMuted)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Text(localization.localized(.version))
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                .padding(AppTheme.Spacing.md)
                                
                                Divider()
                                    .background(AppTheme.Colors.border)
                                
                                HStack {
                                    Text(localization.localized(.developer))
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Spacer()
                                    Text("YuKoha Drums")
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }
                                .padding(AppTheme.Spacing.md)
                            }
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                        
                        Spacer(minLength: AppTheme.Spacing.xxl)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationTitle(localization.localized(.settings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localized(.done)) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            previewMetronome.stop()
        }
    }
    
    private func previewSound(_ sound: MetronomeSound) {
        previewMetronome.stop()
        previewMetronome.changeSound(sound)
        previewMetronome.start(bpm: 120, sound: sound, beatsPerBar: 4)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            previewMetronome.stop()
        }
    }
    
    private func localizedSoundName(_ sound: MetronomeSound) -> String {
        switch sound {
        case .click: return localization.localized(.click)
        case .woodblock: return localization.localized(.woodblock)
        case .hihat: return localization.localized(.hihat)
        case .rimshot: return localization.localized(.rimshot)
        case .cowbell: return localization.localized(.cowbell)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
