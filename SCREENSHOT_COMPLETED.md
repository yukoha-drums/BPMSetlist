# 🎯 スクリーンショット撮影完了ガイド

## ✅ 準備完了しました！

デスクトップに以下のフォルダを作成しました：
- 📁 `AppStore-Screenshots-iPhone` - iPhone用スクリーンショットの保存先
- 📁 `AppStore-Screenshots-iPad` - iPad用スクリーンショットの保存先

---

## 📸 撮影手順（所要時間: 10分）

### STEP 1: iPhoneでスクリーンショットを撮影（5枚）

#### 1-1. Xcodeでデバイスを選択
```
Xcode上部のデバイス選択 → 【iPhone 15 Pro Max】を選択
```

#### 1-2. アプリを起動
```
⌘R または Playボタンをクリック
```

#### 1-3. 5つの画面を撮影

| # | 画面 | 操作 | 撮影方法 |
|---|------|------|---------|
| 1 | メイン画面（空） | そのまま | ⌘S |
| 2 | 曲リスト | +ボタン→曲入力→保存 | ⌘S |
| 3 | 曲追加画面 | +ボタンをタップ | ⌘S → キャンセル |
| 4 | 再生中 | 再生ボタン（▶）をタップ | ⌘S |
| 5 | 設定画面 | 設定ボタン（⚙）をタップ | ⌘S |

**撮影のコツ:**
- シミュレーターをクリックしてアクティブにする
- `⌘S` を押す
- デスクトップに自動保存される

---

### STEP 2: iPadでスクリーンショットを撮影（5枚）

#### 2-1. Xcodeでデバイスを変更
```
Xcode上部のデバイス選択 → 【iPad Pro (12.9-inch)】を選択
```

#### 2-2. アプリを再起動
```
⌘R でアプリを起動
```

#### 2-3. 同じ5つの画面を撮影
STEP 1と全く同じ手順で5枚撮影

---

### STEP 3: スクリーンショットを整理

#### 3-1. デスクトップのスクリーンショットを確認
```bash
# デスクトップを開く
open ~/Desktop
```

以下のファイルが見つかるはずです：
```
スクリーンショット 2026-02-10 8.00.00.png  ← iPhone 1枚目
スクリーンショット 2026-02-10 8.01.00.png  ← iPhone 2枚目
...
スクリーンショット 2026-02-10 8.05.00.png  ← iPad 1枚目
...
```

#### 3-2. ファイルを分類

**iPhone用（最初の5枚）:**
```
~/Desktop/スクリーンショット... 
→ ~/Desktop/AppStore-Screenshots-iPhone/ へドラッグ
```

**iPad用（次の5枚）:**
```
~/Desktop/スクリーンショット... 
→ ~/Desktop/AppStore-Screenshots-iPad/ へドラッグ
```

#### 3-3. ファイル名をリネーム（推奨）

わかりやすい名前に変更：
```
01-main-empty.png
02-with-songs.png
03-add-song.png
04-playing.png
05-settings.png
```

---

## 📤 App Store Connect へのアップロード

### 1. App Store Connect にアクセス
https://appstoreconnect.apple.com/

### 2. アプリを選択
```
マイ App → BPMSetlist → 1.0 準備中
```

### 3. スクリーンショットセクションへ移動
```
App 情報 → スクリーンショット
→ "View All Sizes in Media Manager" をクリック
```

### 4. iPhone用スクリーンショットをアップロード
```
📁 ~/Desktop/AppStore-Screenshots-iPhone/ から5枚を選択
→ 6.7インチ (iPhone 15 Pro Max) のスロットにドラッグ&ドロップ
```

### 5. iPad用スクリーンショットをアップロード
```
📁 ~/Desktop/AppStore-Screenshots-iPad/ から5枚を選択
→ 12.9インチ (iPad Pro) のスロットにドラッグ&ドロップ
```

### 6. 保存して再提出
```
保存 → Submit for Review
```

---

## ✅ 確認チェックリスト

提出前に以下を確認してください：

- [ ] iPhone用スクリーンショット 5枚を撮影
- [ ] iPad用スクリーンショット 5枚を撮影
- [ ] iPhoneのスクリーンショットに**iPadのフレームが含まれていない**
- [ ] iPadのスクリーンショットに**iPhoneのフレームが含まれていない**
- [ ] 各スクリーンショットが適切なサイズのスロットに配置
- [ ] App Store Connectで保存完了
- [ ] Submit for Review をクリック

---

## 🎉 完了！

これでApp Storeの要件を完全に満たしました！

**差し戻しの原因だった問題:**
❌ iPadのスクリーンショットにiPhoneのフレームが表示

**解決策:**
✅ iPhone 15 Pro Max と iPad Pro (12.9-inch) で**別々に撮影**

---

## 📞 困ったときは

### スクリーンショットが見つからない
```bash
# デスクトップのスクリーンショットを確認
ls -la ~/Desktop/スクリーンショット*
```

### デバイスが見つからない
```
Xcode → Window → Devices and Simulators
→ iOS シミュレーターをダウンロード
```

### やり直したい場合
```bash
# フォルダを削除して再度実行
rm -rf ~/Desktop/AppStore-Screenshots-*
./interactive_screenshot.sh
```

---

Good luck! 🚀
