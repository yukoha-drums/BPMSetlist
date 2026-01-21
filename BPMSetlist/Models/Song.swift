//
//  Song.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import Foundation
import SwiftData

@Model
final class Song {
    var title: String
    var bpm: Int
    var order: Int
    var duration: Int // 再生時間（秒）、0の場合は手動で次へ
    var beatsPerBar: Int // 拍子の分子（1小節あたりの拍数）
    var beatUnit: Int // 拍子の分母（4 = 四分音符、8 = 八分音符）
    var createdAt: Date
    
    init(title: String, bpm: Int, order: Int = 0, duration: Int = 0, beatsPerBar: Int = 4, beatUnit: Int = 4) {
        self.title = title
        self.bpm = max(20, min(300, bpm)) // BPM範囲: 20-300
        self.order = order
        self.duration = max(0, duration)
        self.beatsPerBar = max(1, min(16, beatsPerBar))
        self.beatUnit = [2, 4, 8, 16].contains(beatUnit) ? beatUnit : 4
        self.createdAt = Date()
    }
    
    var formattedDuration: String {
        if duration == 0 {
            return "∞"
        }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var timeSignatureDisplay: String {
        return "\(beatsPerBar)/\(beatUnit)"
    }
}

// MARK: - Sample Data
extension Song {
    static var sampleSongs: [Song] {
        [
            Song(title: "Opening", bpm: 120, order: 0),
            Song(title: "Verse", bpm: 90, order: 1),
            Song(title: "Chorus", bpm: 140, order: 2),
            Song(title: "Bridge", bpm: 100, order: 3),
            Song(title: "Finale", bpm: 160, order: 4)
        ]
    }
}

