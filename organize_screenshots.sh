#!/bin/bash

# BPMSetlist - シンプルスクリーンショット生成スクリプト
# 手動でXcodeからUI Testを実行した後、スクリーンショットを整理します

set -e

echo "📸 スクリーンショット整理スクリプト"
echo "===================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$PROJECT_DIR/screenshots_organized"

# 出力ディレクトリを作成
mkdir -p "$OUTPUT_DIR/iPhone"
mkdir -p "$OUTPUT_DIR/iPad"

# Xcode DerivedDataからスクリーンショットを検索
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
SCREENSHOTS_FOUND=0

echo "🔍 スクリーンショットを検索中..."

# 最新のTestResultsを検索
find "$DERIVED_DATA" -path "*/Logs/Test/Attachments/*.png" -mtime -1 2>/dev/null | while read screenshot; do
    # ファイル名からデバイス情報を推測
    filename=$(basename "$screenshot")
    parent_dir=$(dirname "$screenshot")
    
    # スクリーンショットの解像度を取得
    width=$(sips -g pixelWidth "$screenshot" | tail -1 | awk '{print $2}')
    height=$(sips -g pixelHeight "$screenshot" | tail -1 | awk '{print $2}')
    
    echo "   📱 $filename (${width}x${height})"
    
    # デバイスタイプを判定（縦横比で判定）
    if [ $width -gt $height ]; then
        # 横向き = iPad
        device_type="iPad"
    else
        # 縦向き
        ratio=$(echo "scale=2; $height / $width" | bc)
        
        # 縦横比で判定
        # iPhone: 約2.16 (19.5:9) または 2.17
        # iPad: 約1.33 (4:3) または 1.43
        if (( $(echo "$ratio < 1.8" | bc -l) )); then
            device_type="iPad"
        else
            device_type="iPhone"
        fi
    fi
    
    # コピー
    cp "$screenshot" "$OUTPUT_DIR/$device_type/"
    ((SCREENSHOTS_FOUND++))
done

if [ $SCREENSHOTS_FOUND -eq 0 ]; then
    echo ""
    echo "❌ スクリーンショットが見つかりませんでした。"
    echo ""
    echo "以下の手順でスクリーンショットを生成してください:"
    echo ""
    echo "1. Xcodeでプロジェクトを開く"
    echo "2. Product > Test (⌘U) を実行"
    echo "   または"
    echo "   Test Navigator (⌘6) > ScreenshotGenerator を右クリック > Test"
    echo ""
    echo "3. テスト完了後、このスクリプトを再実行"
    echo ""
    exit 1
fi

# ファイル名を整理
counter=1
for file in "$OUTPUT_DIR/iPhone"/*.png; do
    if [ -f "$file" ]; then
        new_name="$OUTPUT_DIR/iPhone/$(printf "%02d" $counter)-screenshot.png"
        mv "$file" "$new_name"
        ((counter++))
    fi
done

counter=1
for file in "$OUTPUT_DIR/iPad"/*.png; do
    if [ -f "$file" ]; then
        new_name="$OUTPUT_DIR/iPad/$(printf "%02d" $counter)-screenshot.png"
        mv "$file" "$new_name"
        ((counter++))
    fi
done

echo ""
echo "✅ $SCREENSHOTS_FOUND枚のスクリーンショットを整理しました！"
echo ""
echo "📁 保存先:"
echo "   iPhone: $OUTPUT_DIR/iPhone/"
echo "   iPad: $OUTPUT_DIR/iPad/"
echo ""
echo "次のステップ:"
echo "1. 保存先のスクリーンショットを確認"
echo "2. App Store Connectにアップロード"
echo ""
