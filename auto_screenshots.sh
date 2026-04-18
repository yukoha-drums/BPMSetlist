#!/bin/bash

# ============================================================
#  BPMSetlist - 完全自動スクリーンショット生成
#  ワンコマンドで iPhone版 + iPad版を撮影・抽出・整理
#  使い方: ./auto_screenshots.sh
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$PROJECT_DIR/BPMSetlist.xcodeproj"
SCHEME="BPMSetlist"
OUTPUT_DIR="$HOME/Desktop/AppStore-Screenshots"
DD="$PROJECT_DIR/.build/DerivedData"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  📸 BPMSetlist - 完全自動スクリーンショット生成          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# 準備
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/iPhone" "$OUTPUT_DIR/iPad" "$DD"

run_test() {
    local dest="$1"
    local label="$2"
    local result="$DD/$3.xcresult"
    local log="$DD/$3_build.log"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 $label"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    rm -rf "$result"

    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$dest" \
        -only-testing:BPMSetlistUITests/ScreenshotGenerator \
        -derivedDataPath "$DD" \
        -resultBundlePath "$result" \
        CODE_SIGNING_ALLOWED=NO \
        > "$log" 2>&1 || true

    if grep -q "TEST SUCCEEDED" "$log" 2>/dev/null; then
        echo "   ✅ テスト成功"
    else
        echo "   ⚠️ テスト完了（ログ: $log）"
    fi
}

extract() {
    local result="$DD/$1.xcresult"
    local out="$OUTPUT_DIR/$1"

    echo "   📂 スクリーンショットを抽出中..."

    xcrun xcresulttool export attachments \
        --path "$result" \
        --output-path "$out" 2>/dev/null

    # manifest.json から suggested name でリネーム
    python3 -c "
import json, os, shutil
manifest = json.load(open('$out/manifest.json'))
for test in manifest:
    for att in test.get('attachments', []):
        src = '$out/' + att['exportedFileName']
        suggested = att['suggestedHumanReadableName']
        parts = suggested.split('_')
        name_parts = []
        for p in parts:
            if len(p) == 1 and p.isdigit() and name_parts:
                break
            name_parts.append(p)
        clean_name = '_'.join(name_parts) + '.png'
        dst = '$out/' + clean_name
        if os.path.exists(src):
            shutil.move(src, dst)
" 2>/dev/null
    rm -f "$out/manifest.json"

    local count
    count=$(find "$out" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
    echo "   ✅ ${count}枚のスクリーンショットを保存"
}

# ── iPhone ──
run_test "platform=iOS Simulator,name=iPhone 15 Pro Max,OS=17.5" \
         "[1/2] iPhone 15 Pro Max" "iPhone"
extract "iPhone"

echo ""

# ── iPad ──
run_test "platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=17.5" \
         "[2/2] iPad Pro 13-inch (M4)" "iPad"
extract "iPad"

# ── 結果 ──
IPHONE_COUNT=$(find "$OUTPUT_DIR/iPhone" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
IPAD_COUNT=$(find "$OUTPUT_DIR/iPad" -name "*.png" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "🎉 完了！"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📁 $OUTPUT_DIR"
echo "   📱 iPhone: ${IPHONE_COUNT}枚"
echo "   📱 iPad:   ${IPAD_COUNT}枚"
echo ""
echo "📤 App Store Connectにアップロード:"
echo "   https://appstoreconnect.apple.com/"
echo ""

open "$OUTPUT_DIR"
echo "Done! 🚀"
