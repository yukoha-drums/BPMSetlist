//
//  LocalizationManager.swift
//  BPMSetlist
//
//  Created by Yuichiro Kohata on 2026/01/21.
//

import Foundation
import SwiftUI

// MARK: - Supported Languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case japanese = "ja"
    case french = "fr"
    case italian = "it"
    case spanish = "es"
    case german = "de"
    case chinese = "zh"
    case korean = "ko"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .chinese: return "中文"
        case .korean: return "한국어"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .chinese: return "🇨🇳"
        case .korean: return "🇰🇷"
        }
    }
}

// MARK: - Localization Keys
enum L10nKey: String {
    // Navigation
    case appTitle = "app_title"
    case settings = "settings"
    case done = "done"
    case cancel = "cancel"
    case save = "save"
    case delete = "delete"
    case edit = "edit"
    
    // Main Screen
    case songs = "songs"
    case noSongsYet = "no_songs_yet"
    case addFirstSong = "add_first_song"
    case addSong = "add_song"
    case editSong = "edit_song"
    case selectSong = "select_song"
    case playing = "playing"
    
    // Song Edit
    case title = "title"
    case songName = "song_name"
    case bpm = "bpm"
    case preview = "preview"
    case stop = "stop"
    case presets = "presets"
    case timeSignature = "time_signature"
    case common = "common"
    case other = "other"
    case duration = "duration"
    case durationDescription = "duration_description"
    case minutes = "minutes"
    case seconds = "seconds"
    case manual = "manual"
    case time = "time"
    case bars = "bars"
    case deleteSong = "delete_song"
    case deleteConfirmation = "delete_confirmation"
    case untitled = "untitled"
    
    // Settings
    case metronomeSound = "metronome_sound"
    case countInBars = "count_in_bars"
    case off = "off"
    case language = "language"
    case about = "about"
    case version = "version"
    case developer = "developer"
    
    // Sound Names
    case click = "click"
    case woodblock = "woodblock"
    case hihat = "hihat"
    case rimshot = "rimshot"
    case cowbell = "cowbell"
    
    // Support
    case support = "support"
    case rateApp = "rate_app"
    case sendFeedback = "send_feedback"
}

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .english
    }
    
    func localized(_ key: L10nKey) -> String {
        return translations[currentLanguage]?[key] ?? translations[.english]?[key] ?? key.rawValue
    }
    
    // MARK: - Translations Dictionary
    private let translations: [AppLanguage: [L10nKey: String]] = [
        // English
        .english: [
            .appTitle: "BPM Setlist",
            .settings: "Settings",
            .done: "Done",
            .cancel: "Cancel",
            .save: "Save",
            .delete: "Delete",
            .edit: "Edit",
            .songs: "songs",
            .noSongsYet: "No Songs Yet",
            .addFirstSong: "Add your first song to create a setlist",
            .addSong: "Add Song",
            .editSong: "Edit Song",
            .selectSong: "Select a song",
            .playing: "Playing",
            .title: "TITLE",
            .songName: "Song name",
            .bpm: "BPM",
            .preview: "Preview",
            .stop: "Stop",
            .presets: "PRESETS",
            .timeSignature: "TIME SIGNATURE",
            .common: "COMMON",
            .other: "OTHER",
            .duration: "DURATION",
            .durationDescription: "Set duration to auto-advance to next song",
            .minutes: "Minutes",
            .seconds: "Seconds",
            .manual: "Manual",
            .time: "Time",
            .bars: "Bars",
            .deleteSong: "Delete Song",
            .deleteConfirmation: "Are you sure you want to delete",
            .untitled: "Untitled",
            .metronomeSound: "METRONOME SOUND",
            .countInBars: "COUNT-IN BARS",
            .off: "Off",
            .language: "LANGUAGE",
            .about: "ABOUT",
            .version: "Version",
            .developer: "Developer",
            .click: "Click",
            .woodblock: "Woodblock",
            .hihat: "Hi-Hat",
            .rimshot: "Rimshot",
            .cowbell: "Cowbell",
            .support: "SUPPORT",
            .rateApp: "Rate This App",
            .sendFeedback: "Send Feedback",
        ],
        
        // Japanese
        .japanese: [
            .appTitle: "BPM セットリスト",
            .settings: "設定",
            .done: "完了",
            .cancel: "キャンセル",
            .save: "保存",
            .delete: "削除",
            .edit: "編集",
            .songs: "曲",
            .noSongsYet: "曲がありません",
            .addFirstSong: "最初の曲を追加してセットリストを作成",
            .addSong: "曲を追加",
            .editSong: "曲を編集",
            .selectSong: "曲を選択",
            .playing: "再生中",
            .title: "タイトル",
            .songName: "曲名",
            .bpm: "BPM",
            .preview: "プレビュー",
            .stop: "停止",
            .presets: "プリセット",
            .timeSignature: "拍子",
            .common: "よく使う",
            .other: "その他",
            .duration: "再生時間",
            .durationDescription: "設定した時間で次の曲へ自動移動",
            .minutes: "分",
            .seconds: "秒",
            .manual: "手動",
            .time: "時間",
            .bars: "小節",
            .deleteSong: "曲を削除",
            .deleteConfirmation: "本当に削除しますか？",
            .untitled: "無題",
            .metronomeSound: "メトロノーム音",
            .countInBars: "カウントイン",
            .off: "オフ",
            .language: "言語",
            .about: "このアプリについて",
            .version: "バージョン",
            .developer: "開発者",
            .click: "クリック",
            .woodblock: "ウッドブロック",
            .hihat: "ハイハット",
            .rimshot: "リムショット",
            .cowbell: "カウベル",
            .support: "サポート",
            .rateApp: "アプリを評価する",
            .sendFeedback: "フィードバックを送る",
        ],
        
        // French
        .french: [
            .appTitle: "BPM Setlist",
            .settings: "Paramètres",
            .done: "Terminé",
            .cancel: "Annuler",
            .save: "Enregistrer",
            .delete: "Supprimer",
            .edit: "Modifier",
            .songs: "morceaux",
            .noSongsYet: "Aucun morceau",
            .addFirstSong: "Ajoutez votre premier morceau pour créer une setlist",
            .addSong: "Ajouter",
            .editSong: "Modifier",
            .selectSong: "Sélectionner un morceau",
            .playing: "Lecture",
            .title: "TITRE",
            .songName: "Nom du morceau",
            .bpm: "BPM",
            .preview: "Aperçu",
            .stop: "Arrêt",
            .presets: "PRÉRÉGLAGES",
            .timeSignature: "SIGNATURE",
            .common: "COURANT",
            .other: "AUTRE",
            .duration: "DURÉE",
            .durationDescription: "Définir la durée pour passer automatiquement au morceau suivant",
            .minutes: "Minutes",
            .seconds: "Secondes",
            .manual: "Manuel",
            .time: "Temps",
            .bars: "Mesures",
            .deleteSong: "Supprimer",
            .deleteConfirmation: "Voulez-vous vraiment supprimer",
            .untitled: "Sans titre",
            .metronomeSound: "SON DU MÉTRONOME",
            .countInBars: "MESURES DE DÉCOMPTE",
            .off: "Désactivé",
            .language: "LANGUE",
            .about: "À PROPOS",
            .version: "Version",
            .developer: "Développeur",
            .click: "Clic",
            .woodblock: "Wood-block",
            .hihat: "Charleston",
            .rimshot: "Rimshot",
            .cowbell: "Cloche",
            .support: "ASSISTANCE",
            .rateApp: "Évaluer l'application",
            .sendFeedback: "Envoyer un commentaire",
        ],
        
        // Italian
        .italian: [
            .appTitle: "BPM Setlist",
            .settings: "Impostazioni",
            .done: "Fatto",
            .cancel: "Annulla",
            .save: "Salva",
            .delete: "Elimina",
            .edit: "Modifica",
            .songs: "brani",
            .noSongsYet: "Nessun brano",
            .addFirstSong: "Aggiungi il tuo primo brano per creare una setlist",
            .addSong: "Aggiungi",
            .editSong: "Modifica",
            .selectSong: "Seleziona un brano",
            .playing: "In riproduzione",
            .title: "TITOLO",
            .songName: "Nome del brano",
            .bpm: "BPM",
            .preview: "Anteprima",
            .stop: "Stop",
            .presets: "PRESET",
            .timeSignature: "TEMPO",
            .common: "COMUNI",
            .other: "ALTRI",
            .duration: "DURATA",
            .durationDescription: "Imposta la durata per passare automaticamente al brano successivo",
            .minutes: "Minuti",
            .seconds: "Secondi",
            .manual: "Manuale",
            .time: "Tempo",
            .bars: "Battute",
            .deleteSong: "Elimina brano",
            .deleteConfirmation: "Sei sicuro di voler eliminare",
            .untitled: "Senza titolo",
            .metronomeSound: "SUONO METRONOMO",
            .countInBars: "BATTUTE DI CONTEGGIO",
            .off: "Spento",
            .language: "LINGUA",
            .about: "INFO",
            .version: "Versione",
            .developer: "Sviluppatore",
            .click: "Click",
            .woodblock: "Woodblock",
            .hihat: "Hi-Hat",
            .rimshot: "Rimshot",
            .cowbell: "Campanaccio",
            .support: "SUPPORTO",
            .rateApp: "Valuta l'app",
            .sendFeedback: "Invia feedback",
        ],
        
        // Spanish
        .spanish: [
            .appTitle: "BPM Setlist",
            .settings: "Ajustes",
            .done: "Listo",
            .cancel: "Cancelar",
            .save: "Guardar",
            .delete: "Eliminar",
            .edit: "Editar",
            .songs: "canciones",
            .noSongsYet: "Sin canciones",
            .addFirstSong: "Añade tu primera canción para crear una lista",
            .addSong: "Añadir",
            .editSong: "Editar",
            .selectSong: "Selecciona una canción",
            .playing: "Reproduciendo",
            .title: "TÍTULO",
            .songName: "Nombre de la canción",
            .bpm: "BPM",
            .preview: "Vista previa",
            .stop: "Parar",
            .presets: "PREAJUSTES",
            .timeSignature: "COMPÁS",
            .common: "COMUNES",
            .other: "OTROS",
            .duration: "DURACIÓN",
            .durationDescription: "Establecer duración para avanzar automáticamente",
            .minutes: "Minutos",
            .seconds: "Segundos",
            .manual: "Manual",
            .time: "Tiempo",
            .bars: "Compases",
            .deleteSong: "Eliminar canción",
            .deleteConfirmation: "¿Seguro que quieres eliminar",
            .untitled: "Sin título",
            .metronomeSound: "SONIDO DEL METRÓNOMO",
            .countInBars: "COMPASES DE CUENTA",
            .off: "Apagado",
            .language: "IDIOMA",
            .about: "ACERCA DE",
            .version: "Versión",
            .developer: "Desarrollador",
            .click: "Clic",
            .woodblock: "Caja china",
            .hihat: "Hi-Hat",
            .rimshot: "Rimshot",
            .cowbell: "Cencerro",
            .support: "SOPORTE",
            .rateApp: "Valorar la app",
            .sendFeedback: "Enviar comentarios",
        ],
        
        // German
        .german: [
            .appTitle: "BPM Setlist",
            .settings: "Einstellungen",
            .done: "Fertig",
            .cancel: "Abbrechen",
            .save: "Speichern",
            .delete: "Löschen",
            .edit: "Bearbeiten",
            .songs: "Songs",
            .noSongsYet: "Keine Songs",
            .addFirstSong: "Füge deinen ersten Song hinzu",
            .addSong: "Hinzufügen",
            .editSong: "Bearbeiten",
            .selectSong: "Song auswählen",
            .playing: "Wiedergabe",
            .title: "TITEL",
            .songName: "Songname",
            .bpm: "BPM",
            .preview: "Vorschau",
            .stop: "Stopp",
            .presets: "VOREINSTELLUNGEN",
            .timeSignature: "TAKTART",
            .common: "HÄUFIG",
            .other: "ANDERE",
            .duration: "DAUER",
            .durationDescription: "Dauer für automatischen Wechsel zum nächsten Song",
            .minutes: "Minuten",
            .seconds: "Sekunden",
            .manual: "Manuell",
            .time: "Zeit",
            .bars: "Takte",
            .deleteSong: "Song löschen",
            .deleteConfirmation: "Möchtest du wirklich löschen",
            .untitled: "Unbenannt",
            .metronomeSound: "METRONOM-KLANG",
            .countInBars: "EINZÄHLTAKTE",
            .off: "Aus",
            .language: "SPRACHE",
            .about: "ÜBER",
            .version: "Version",
            .developer: "Entwickler",
            .click: "Klick",
            .woodblock: "Holzblock",
            .hihat: "Hi-Hat",
            .rimshot: "Rimshot",
            .cowbell: "Kuhglocke",
            .support: "SUPPORT",
            .rateApp: "App bewerten",
            .sendFeedback: "Feedback senden",
        ],
        
        // Chinese
        .chinese: [
            .appTitle: "BPM 曲目表",
            .settings: "设置",
            .done: "完成",
            .cancel: "取消",
            .save: "保存",
            .delete: "删除",
            .edit: "编辑",
            .songs: "首歌曲",
            .noSongsYet: "暂无歌曲",
            .addFirstSong: "添加第一首歌曲来创建曲目表",
            .addSong: "添加歌曲",
            .editSong: "编辑歌曲",
            .selectSong: "选择歌曲",
            .playing: "播放中",
            .title: "标题",
            .songName: "歌曲名称",
            .bpm: "BPM",
            .preview: "预览",
            .stop: "停止",
            .presets: "预设",
            .timeSignature: "拍号",
            .common: "常用",
            .other: "其他",
            .duration: "时长",
            .durationDescription: "设置时长以自动切换到下一首歌曲",
            .minutes: "分钟",
            .seconds: "秒",
            .manual: "手动",
            .time: "时间",
            .bars: "小节",
            .deleteSong: "删除歌曲",
            .deleteConfirmation: "确定要删除吗",
            .untitled: "未命名",
            .metronomeSound: "节拍器音效",
            .countInBars: "预备拍",
            .off: "关闭",
            .language: "语言",
            .about: "关于",
            .version: "版本",
            .developer: "开发者",
            .click: "点击音",
            .woodblock: "木鱼",
            .hihat: "踩镲",
            .rimshot: "边击",
            .cowbell: "牛铃",
            .support: "支持",
            .rateApp: "给应用评分",
            .sendFeedback: "发送反馈",
        ],
        
        // Korean
        .korean: [
            .appTitle: "BPM 셋리스트",
            .settings: "설정",
            .done: "완료",
            .cancel: "취소",
            .save: "저장",
            .delete: "삭제",
            .edit: "편집",
            .songs: "곡",
            .noSongsYet: "곡이 없습니다",
            .addFirstSong: "첫 번째 곡을 추가하여 셋리스트를 만드세요",
            .addSong: "곡 추가",
            .editSong: "곡 편집",
            .selectSong: "곡 선택",
            .playing: "재생 중",
            .title: "제목",
            .songName: "곡 이름",
            .bpm: "BPM",
            .preview: "미리듣기",
            .stop: "정지",
            .presets: "프리셋",
            .timeSignature: "박자",
            .common: "자주 사용",
            .other: "기타",
            .duration: "재생 시간",
            .durationDescription: "설정된 시간 후 다음 곡으로 자동 전환",
            .minutes: "분",
            .seconds: "초",
            .manual: "수동",
            .time: "시간",
            .bars: "마디",
            .deleteSong: "곡 삭제",
            .deleteConfirmation: "정말 삭제하시겠습니까",
            .untitled: "제목 없음",
            .metronomeSound: "메트로놈 소리",
            .countInBars: "카운트인 마디",
            .off: "끄기",
            .language: "언어",
            .about: "정보",
            .version: "버전",
            .developer: "개발자",
            .click: "클릭",
            .woodblock: "우드블록",
            .hihat: "하이햇",
            .rimshot: "림샷",
            .cowbell: "카우벨",
            .support: "지원",
            .rateApp: "앱 평가하기",
            .sendFeedback: "피드백 보내기",
        ],
    ]
}

// MARK: - Convenience Extension
extension String {
    static func localized(_ key: L10nKey) -> String {
        return LocalizationManager.shared.localized(key)
    }
}

