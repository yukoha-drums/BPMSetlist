# 📸 BPMSetlist スクリーンショット自動生成ガイド

App Storeレビュー対応：iPhone版とiPad版のスクリーンショットを自動生成

## 🚨 問題点

App Storeのレビューで以下の理由で差し戻されました：
> **Guideline 2.3.3 - 13-inch iPad screenshots show an iPhone device frame**

→ iPadのスクリーンショットにiPhoneのフレームが表示されている

## ✅ 解決策

iPhone版とiPad版を**別々のシミュレーター**で自動生成します。

---

## 📋 準備

### 1. 必要なファイルが追加されました

```
BPMSetlist/
├── BPMSetlistUITests/
│   └── ScreenshotGenerator.swift      ✅ 自動スクリーンショット生成テスト
├── generate_screenshots.sh            ✅ 自動実行スクリプト
├── organize_screenshots.sh            ✅ 手動実行後の整理スクリプト
└── fastlane/                          ✅ Fastlane設定（オプション）
    ├── Fastfile
    └── Snapfile
```

---

## 🎯 方法1: 手動実行（推奨・簡単）

### ステップ1: Xcodeでテストを実行

1. **Xcodeでプロジェクトを開く**
   ```bash
   open /Users/yuichiro.kohata/00.work/codes/BPMSetlist/BPMSetlist.xcodeproj
   ```

2. **iPhoneシミュレーターを選択**
   - Xcode上部のデバイス選択で `iPhone 15 Pro Max` を選択

3. **スクリーンショットテストを実行**
   - `⌘6` でTest Navigatorを開く
   - `ScreenshotGenerator` を見つける
   - 右クリック → `Test` を選択
   
   または
   
   - `⌘U` でテストを実行

4. **テスト完了を待つ**（1-2分）

### ステップ2: iPadシミュレーターで同じ手順を繰り返す

1. **iPadシミュレーターを選択**
   - Xcode上部のデバイス選択で `iPad Pro (12.9-inch)` を選択

2. **再度テストを実行**
   - `⌘U` でテストを実行

### ステップ3: スクリーンショットを整理

```bash
cd /Users/yuichiro.kohata/00.work/codes/BPMSetlist
./organize_screenshots.sh
```

✅ これで `screenshots_organized/` に iPhone版とiPad版が分類されます！

---

## 🚀 方法2: 完全自動実行（複数デバイス対応）

### ステップ1: スクリプトを実行

```bash
cd /Users/yuichiro.kohata/00.work/codes/BPMSetlist
./generate_screenshots.sh
```

このスクリプトは以下のデバイスで自動的にスクリーンショットを生成します：

**iPhone:**
- iPhone 15 Pro Max (6.7インチ)
- iPhone 15 Pro (6.1インチ)
- iPhone 14 Pro Max

**iPad:**
- iPad Pro (12.9-inch)
- iPad Pro (11-inch)
- iPad Air 11-inch (M2)

### ステップ2: 完了を待つ

各デバイスで自動的に：
1. シミュレーター起動
2. アプリ起動
3. スクリーンショット撮影
4. 保存・整理

所要時間: 約10-15分

---

## 🎨 スクリーンショットの内容

自動生成される画面：

1. **01-MainScreen-Empty**: メイン画面（空の状態）
2. **02-MainScreen-WithSongs**: 曲が追加された状態
3. **03-AddSong**: 曲追加画面
4. **04-Playing**: 再生中の画面
5. **05-Settings**: 設定画面

---

## 📱 App Store Connectへのアップロード

### 必要なサイズ

#### iPhone
- **6.7インチ**: iPhone 15 Pro Max, 14 Pro Max (1290 x 2796)
- **6.5インチ**: iPhone 14 Plus (1284 x 2778)
- **5.5インチ**: iPhone 8 Plus (1242 x 2208)

#### iPad
- **12.9インチ**: iPad Pro 12.9 (2048 x 2732)
- **11インチ**: iPad Pro 11, iPad Air (1668 x 2388)

### アップロード手順

1. **App Store Connect** にログイン
   https://appstoreconnect.apple.com/

2. **アプリを選択** → **1.0 準備中** → **スクリーンショット**

3. **"View All Sizes in Media Manager"** をクリック

4. **iPhone用スクリーンショット**
   - `screenshots/iPhone/` または `screenshots_organized/iPhone/` からアップロード
   - 各サイズ（6.7インチ、6.5インチ等）に適切な画像を配置

5. **iPad用スクリーンショット**
   - `screenshots/iPad/` または `screenshots_organized/iPad/` からアップロード
   - 12.9インチと11インチに適切な画像を配置

6. **保存**

---

## 🔧 カスタマイズ

### スクリーンショットの内容を変更

`BPMSetlistUITests/ScreenshotGenerator.swift` を編集：

```swift
func testGenerateScreenshots() throws {
    app.launch()
    
    // 1. 最初の画面
    sleep(2)
    snapshot("01-MainScreen")
    
    // 2. あなたのカスタム操作
    // ...
    
    snapshot("02-YourScreen")
}
```

### デバイスを追加・変更

`generate_screenshots.sh` の以下の部分を編集：

```bash
declare -a IPHONE_DEVICES=(
    "iPhone 15 Pro Max"
    "あなたのデバイス名"
)
```

利用可能なデバイスを確認：
```bash
xcrun simctl list devices
```

---

## 🐛 トラブルシューティング

### エラー: "Scheme 'BPMSetlist' not found"

**解決策**: Xcodeでスキーム名を確認
1. Xcode > Product > Scheme > Manage Schemes
2. スキーム名をコピー
3. スクリプト内の `SCHEME="BPMSetlist"` を修正

### エラー: "Device not found"

**解決策**: シミュレーターをインストール
```bash
# 利用可能なランタイムを確認
xcrun simctl list runtimes

# iOSシミュレーターをインストール（Xcode > Settings > Platforms）
```

### スクリーンショットが見つからない

**解決策**: DerivedDataの場所を確認
```bash
# DerivedDataの場所を確認
defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation

# スクリーンショットを手動で探す
find ~/Library/Developer/Xcode/DerivedData -name "*.png" -mtime -1
```

---

## 📚 参考リンク

- [App Store Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)
- [XCTest UI Testing](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Fastlane Snapshot](https://docs.fastlane.tools/actions/snapshot/)

---

## ✅ チェックリスト

再提出前の確認事項：

- [ ] iPhone用スクリーンショットを生成（3-5枚）
- [ ] iPad用スクリーンショットを生成（3-5枚）
- [ ] すべてのスクリーンショットが正しいデバイスフレームで表示
- [ ] スクリーンショットがアプリの主要機能を示している
- [ ] ステータスバーが綺麗に表示されている
- [ ] App Store Connectにアップロード完了
- [ ] 再提出

---

## 🎉 完成！

このガイドに従えば、App Storeの要件を満たすスクリーンショットを自動生成できます。

**推奨手順:**
1. まず**方法1（手動実行）**で1-2枚試す
2. 問題なければ**方法2（自動実行）**で全デバイス生成
3. App Store Connectにアップロード
4. 再提出！

Good luck! 🚀
