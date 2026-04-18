//
//  BeatIndicatorView.swift
//  BPMSetlist
//
//  Visual beat indicator so the metronome is usable without earphones.
//  Shows a row of dots (one per beat in the current bar). The active beat
//  pulses; beat 1 uses the accent color to distinguish the downbeat.
//

import SwiftUI

struct BeatIndicatorView: View {
    enum Style {
        case compact   // Thin row for the bottom player bar
        case expanded  // Larger dots for the song edit preview
    }

    @ObservedObject var engine: MetronomeEngine
    let isActive: Bool
    var style: Style = .compact

    @State private var flashAmount: Double = 0

    private var baseDotSize: CGFloat {
        switch style {
        case .compact:  return 8
        case .expanded: return 12
        }
    }

    private var activeScale: CGFloat {
        switch style {
        case .compact:  return 1.6
        case .expanded: return 1.8
        }
    }

    private var spacing: CGFloat {
        switch style {
        case .compact:  return AppTheme.Spacing.xs
        case .expanded: return AppTheme.Spacing.sm
        }
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<max(engine.beatsPerBar, 1), id: \.self) { beat in
                dot(for: beat)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: engine.beatTick) { _, _ in
            guard isActive else { return }
            flashAmount = 1
            withAnimation(.easeOut(duration: 0.18)) {
                flashAmount = 0
            }
        }
        .onChange(of: isActive) { _, newValue in
            if !newValue {
                flashAmount = 0
            }
        }
    }

    @ViewBuilder
    private func dot(for beat: Int) -> some View {
        let isCurrent = isActive && beat == engine.currentBeat
        let isDownbeat = beat == 0

        let activeColor: Color = isDownbeat
            ? AppTheme.Colors.accentGold
            : AppTheme.Colors.textPrimary
        let idleColor: Color = AppTheme.Colors.border

        let color: Color = isCurrent ? activeColor : idleColor
        let scale: CGFloat = isCurrent ? activeScale : 1.0
        // Downbeat flashes a bit stronger than other beats.
        let glow: Double = isCurrent ? (isDownbeat ? 1.0 : 0.6) * flashAmount : 0

        Circle()
            .fill(color)
            .frame(width: baseDotSize, height: baseDotSize)
            .scaleEffect(scale)
            .overlay(
                Circle()
                    .fill(activeColor.opacity(glow * 0.55))
                    .frame(width: baseDotSize * 2.2, height: baseDotSize * 2.2)
                    .blur(radius: 4)
                    .allowsHitTesting(false)
            )
            .animation(.easeInOut(duration: 0.12), value: engine.currentBeat)
            .animation(.easeInOut(duration: 0.12), value: isActive)
    }
}

#Preview {
    let engine = MetronomeEngine()
    return VStack(spacing: 32) {
        BeatIndicatorView(engine: engine, isActive: true, style: .compact)
        BeatIndicatorView(engine: engine, isActive: true, style: .expanded)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
