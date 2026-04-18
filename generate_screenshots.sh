#!/bin/bash

# BPMSetlist - 自動スクリーンショット生成スクリプト
# iPhone版とiPad版のスクリーンショットを自動生成します

set -e

echo "📸 BPMSetlist スクリーンショット自動生成"
echo "========================================"
echo ""

# プロジェクトディレクトリ
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCHEME="BPMSetlist"
OUTPUT_DIR="$PROJECT_DIR/screenshots"

# 出力ディレクトリを作成
mkdir -p "$OUTPUT_DIR"

# デバイス定義
declare -a IPHONE_DEVICES=(
    "iPhone 15 Pro Max"
    "iPhone 15 Pro"
    "iPhone 14 Pro Max"
)

declare -a IPAD_DEVICES=(
    "iPad Pro (12.9-inch) (6th generation)"
    "iPad Pro (11-inch) (4th generation)"
    "iPad Air 11-inch (M2)"
)

# 関数: スクリーンショットを生成
generate_screenshots() {
    local device_name=$1
    local device_type=$2
    
    echo ""
    echo "📱 デバイス: $device_name"
    echo "   タイプ: $device_type"
    
    # デバイスIDを取得
    local device_id=$(xcrun simctl list devices | grep "$device_name" | grep -v "unavailable" | head -1 | grep -o '[0-9A-F]\{8\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{4\}-[0-9A-F]\{12\}')
    
    if [ -z "$device_id" ]; then
        echo "   ⚠️  デバイスが見つかりません。スキップします。"
        return
    fi
    
    echo "   🔧 シミュレーターを起動中..."
    xcrun simctl boot "$device_id" 2>/dev/null || true
    
    # シミュレーター起動待機
    sleep 3
    
    echo "   🧪 UI Testを実行中..."
    
    # UI Testを実行してスクリーンショットを撮影
    xcodebuild test \
        -scheme "$SCHEME" \
        -destination "id=$device_id" \
        -testPlan "BPMSetlist" \
        -only-testing:BPMSetlistUITests/ScreenshotGenerator/testGenerateScreenshots \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | grep -E "Test Case|passed|failed" || true
    
    # スクリーンショットを探して移動
    local screenshots_path=$(find ~/Library/Developer/Xcode/DerivedData -name "Attachments" -type d 2>/dev/null | head -1)
    
    if [ -n "$screenshots_path" ]; then
        echo "   📸 スクリーンショットを保存中..."
        
        # デバイスタイプごとにディレクトリを作成
        local device_output_dir="$OUTPUT_DIR/$device_type/$device_name"
        mkdir -p "$device_output_dir"
        
        # スクリーンショットをコピー
        find "$screenshots_path" -name "*.png" -exec cp {} "$device_output_dir/" \;
        
        # ファイル名をリネーム
        local counter=1
        for file in "$device_output_dir"/*.png; do
            if [ -f "$file" ]; then
                mv "$file" "$device_output_dir/screenshot_$(printf "%02d" $counter).png"
                ((counter++))
            fi
        done
        
        echo "   ✅ 完了: $(($counter - 1))枚のスクリーンショットを保存"
    else
        echo "   ⚠️  スクリーンショットが見つかりませんでした"
    fi
    
    # シミュレーターをシャットダウン
    xcrun simctl shutdown "$device_id" 2>/dev/null || true
}

# メイン処理
main() {
    echo "🍎 iPhone用スクリーンショットを生成中..."
    echo "----------------------------------------"
    
    for device in "${IPHONE_DEVICES[@]}"; do
        generate_screenshots "$device" "iPhone"
    done
    
    echo ""
    echo "📱 iPad用スクリーンショットを生成中..."
    echo "----------------------------------------"
    
    for device in "${IPAD_DEVICES[@]}"; do
        generate_screenshots "$device" "iPad"
    done
    
    echo ""
    echo "========================================="
    echo "✅ すべてのスクリーンショット生成が完了しました！"
    echo ""
    echo "📁 保存先: $OUTPUT_DIR"
    echo ""
    echo "次のステップ:"
    echo "1. $OUTPUT_DIR を確認"
    echo "2. App Store Connectにアップロード"
    echo "   - iPhone用: screenshots/iPhone/"
    echo "   - iPad用: screenshots/iPad/"
    echo ""
}

# スクリプト実行
main
