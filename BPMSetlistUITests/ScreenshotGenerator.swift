//
//  ScreenshotGenerator.swift
//  BPMSetlistUITests
//
//  Auto-generated for App Store Screenshots
//  iPhone版とiPad版のスクリーンショットを自動生成
//

import XCTest

final class ScreenshotGenerator: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Main Screenshot Test
    
    func testScreenshot_01_EmptyState() throws {
        // 画面1: メイン画面（空の状態）- Empty State
        sleep(2) // アニメーション完了待ち
        takeScreenshot(name: "01_MainScreen_Empty")
    }
    
    func testScreenshot_02_AddSongScreen() throws {
        // 画面2: 曲追加画面
        sleep(1)
        
        // ツールバーの「+」ボタンをタップ
        let addButton = app.navigationBars.buttons.element(boundBy: 1) // trailing button
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else {
            // Empty State の「Add Song」ボタンを探す
            let addSongButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add' OR label CONTAINS[c] '追加' OR label CONTAINS[c] '曲を追加'")).firstMatch
            if addSongButton.waitForExistence(timeout: 3) {
                addSongButton.tap()
            }
        }
        
        sleep(1)
        takeScreenshot(name: "02_AddSong_Screen")
        
        // 閉じる
        dismissSheet()
    }
    
    func testScreenshot_03_WithSongs() throws {
        // 画面3: 曲を追加した状態
        addSong(title: "Shape of You", bpm: 96)
        addSong(title: "Blinding Lights", bpm: 171)
        addSong(title: "Don't Stop Me Now", bpm: 156)
        addSong(title: "Uptown Funk", bpm: 115)
        addSong(title: "Billie Jean", bpm: 117)
        
        sleep(1)
        takeScreenshot(name: "03_MainScreen_WithSongs")
    }
    
    func testScreenshot_04_Playing() throws {
        // 画面4: 再生中の画面
        addSong(title: "Shape of You", bpm: 96)
        addSong(title: "Blinding Lights", bpm: 171)
        addSong(title: "Don't Stop Me Now", bpm: 156)
        addSong(title: "Uptown Funk", bpm: 115)
        
        sleep(1)
        
        // 再生ボタンをタップ（play.fill）
        let playButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play' OR label CONTAINS[c] '再生'")).firstMatch
        if playButton.waitForExistence(timeout: 3) {
            playButton.tap()
            sleep(2) // 再生開始を待つ
        }
        
        takeScreenshot(name: "04_Playing")
        
        // 停止
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'stop' OR label CONTAINS[c] '停止'")).firstMatch
        if stopButton.waitForExistence(timeout: 2) {
            stopButton.tap()
        }
    }
    
    func testScreenshot_05_Settings() throws {
        // 画面5: 設定画面
        sleep(1)
        
        // ツールバーのギアボタン（gearshape）をタップ
        let settingsButton = app.navigationBars.buttons.element(boundBy: 0) // leading button
        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
        }
        
        sleep(1)
        takeScreenshot(name: "05_Settings")
    }
    
    // MARK: - Helper Methods
    
    /// 曲を追加する
    private func addSong(title: String, bpm: Int) {
        // 「+」ボタンをタップ
        let navBarAddButton = app.navigationBars.buttons.element(boundBy: 1)
        let emptyStateAddButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add' OR label CONTAINS[c] '追加' OR label CONTAINS[c] '曲を追加'")).firstMatch
        
        if navBarAddButton.waitForExistence(timeout: 2) && navBarAddButton.isHittable {
            navBarAddButton.tap()
        } else if emptyStateAddButton.waitForExistence(timeout: 2) {
            emptyStateAddButton.tap()
        }
        
        sleep(1)
        
        // タイトル入力 - 最初のTextFieldを探す
        let textFields = app.textFields.allElementsBoundByIndex
        if let titleField = textFields.first {
            titleField.tap()
            titleField.typeText(title)
        }
        
        // BPMスライダーを調整（概算）
        let sliders = app.sliders.allElementsBoundByIndex
        if let bpmSlider = sliders.first {
            // BPM 20-300の範囲でスライダー位置を計算
            let normalizedValue = Double(bpm - 20) / Double(300 - 20)
            bpmSlider.adjust(toNormalizedSliderPosition: CGFloat(normalizedValue))
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // 保存ボタンをタップ
        let saveButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Save' OR label CONTAINS[c] '保存'")).firstMatch
        if saveButton.waitForExistence(timeout: 2) {
            saveButton.tap()
        }
        
        sleep(1)
    }
    
    /// シートを閉じる
    private func dismissSheet() {
        let cancelButton = app.navigationBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel' OR label CONTAINS[c] 'キャンセル'")).firstMatch
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
        } else {
            // スワイプダウンで閉じる
            app.swipeDown(velocity: .fast)
        }
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    /// スクリーンショットを撮影してテスト結果に添付
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
