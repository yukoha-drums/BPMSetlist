//
//  Song.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import Foundation
import SwiftData

// 再生時間のタイプ
enum DurationType: String, Codable, CaseIterable {
    case time = "time"      // 時間（秒）で指定
    case bars = "bars"      // 小節数で指定
    case manual = "manual"  // 手動（∞）
}

@Model
final class Song {
    var title: String
    var bpm: Int
    var order: Int
    var duration: Int // 再生時間（秒）、durationTypeがtimeの場合に使用
    var durationBars: Int // 再生小節数、durationTypeがbarsの場合に使用
    var durationTypeRaw: String // DurationTypeのrawValue
    var beatsPerBar: Int // 拍子の分子（1小節あたりの拍数）
    var beatUnit: Int // 拍子の分母（4 = 四分音符、8 = 八分音符）
    var createdAt: Date
    
    var durationType: DurationType {
        get { DurationType(rawValue: durationTypeRaw) ?? .manual }
        set { durationTypeRaw = newValue.rawValue }
    }
    
    init(title: String, bpm: Int, order: Int = 0, duration: Int = 0, durationBars: Int = 0, durationType: DurationType = .manual, beatsPerBar: Int = 4, beatUnit: Int = 4) {
        self.title = title
        self.bpm = max(20, min(300, bpm)) // BPM範囲: 20-300
        self.order = order
        self.duration = max(0, duration)
        self.durationBars = max(0, durationBars)
        self.durationTypeRaw = durationType.rawValue
        self.beatsPerBar = max(1, min(16, beatsPerBar))
        self.beatUnit = [2, 4, 8, 16].contains(beatUnit) ? beatUnit : 4
        self.createdAt = Date()
    }
    
    var formattedDuration: String {
        switch durationType {
        case .manual:
            return "∞"
        case .time:
            if duration == 0 { return "∞" }
            let minutes = duration / 60
            let seconds = duration % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .bars:
            if durationBars == 0 { return "∞" }
            return "\(durationBars) bars"
        }
    }
    
    var timeSignatureDisplay: String {
        return "\(beatsPerBar)/\(beatUnit)"
    }
    
    // 小節数から秒数を計算
    func calculateDurationInSeconds() -> Int {
        switch durationType {
        case .manual:
            return 0
        case .time:
            return duration
        case .bars:
            if durationBars == 0 { return 0 }
            
            // 複合拍子かどうかを判定（6/8, 9/8, 12/8など）
            let isCompoundMeter = beatUnit == 8 && beatsPerBar % 3 == 0
            
            let secondsPerBar: Double
            if isCompoundMeter {
                // 複合拍子: BPMは付点四分音符の数を指す
                // 基本拍の数 = beatsPerBar / 3（例：6/8なら2拍、9/8なら3拍）
                // 1小節の秒数 = (基本拍の数) * (60 / bpm)
                let mainBeatsPerBar = Double(beatsPerBar) / 3.0
                secondsPerBar = mainBeatsPerBar * (60.0 / Double(bpm))
            } else {
                // 単純拍子: BPMは四分音符の数を指す
                // 1拍の秒数 = (60 / BPM) * (4 / beatUnit)
                let secondsPerBeat = 60.0 / Double(bpm) * (4.0 / Double(beatUnit))
                secondsPerBar = secondsPerBeat * Double(beatsPerBar)
            }
            
            return Int(secondsPerBar * Double(durationBars))
        }
    }
}

// MARK: - Sample Data
extension Song {
    static var sampleSongs: [Song] {
        [
            Song(title: "Opening", bpm: 120, order: 0, duration: 0, durationBars: 8, durationType: .bars),
            Song(title: "Verse", bpm: 90, order: 1, duration: 180, durationBars: 0, durationType: .time),
            Song(title: "Chorus", bpm: 140, order: 2, duration: 0, durationBars: 16, durationType: .bars),
            Song(title: "Bridge", bpm: 100, order: 3, duration: 0, durationBars: 0, durationType: .manual),
            Song(title: "Finale", bpm: 160, order: 4, duration: 240, durationBars: 0, durationType: .time)
        ]
    }
}

