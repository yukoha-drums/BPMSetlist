//
//  AppSettings.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import Foundation
import SwiftUI

// MARK: - Metronome Sound Types
enum MetronomeSound: String, CaseIterable, Identifiable {
    case click = "Click"
    case woodblock = "Woodblock"
    case hihat = "Hi-Hat"
    case rimshot = "Rimshot"
    case cowbell = "Cowbell"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .click: return "metronome"
        case .woodblock: return "square.fill"
        case .hihat: return "circle.dotted"
        case .rimshot: return "circle.circle"
        case .cowbell: return "bell.fill"
        }
    }
}

// MARK: - App Settings Manager
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("selectedSound") var selectedSoundRaw: String = MetronomeSound.click.rawValue
    @AppStorage("listItemSize") var listItemSize: Double = 80
    @AppStorage("isRepeatEnabled") var isRepeatEnabled: Bool = false
    @AppStorage("countInBars") var countInBars: Int = 1
    @AppStorage("isVisualBeatEnabled") var isVisualBeatEnabled: Bool = true
    
    var selectedSound: MetronomeSound {
        get { MetronomeSound(rawValue: selectedSoundRaw) ?? .click }
        set { selectedSoundRaw = newValue.rawValue }
    }
    
    private init() {}
}

// MARK: - List Size Range
extension AppSettings {
    static let minListItemSize: Double = 60
    static let maxListItemSize: Double = 150
}

