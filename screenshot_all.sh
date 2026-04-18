#!/bin/bash

# 📸 BPMSetlist スクリーンショット生成 - ワンクリック実行
# このスクリプト1つで全て完了します

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║  📸 BPMSetlist スクリーンショット自動生成            ║"
echo "║  iPhone版とiPad版を自動で生成します                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 使用方法を表示
show_usage() {
    echo "使い方:"
    echo "  ./screenshot_all.sh          - 全デバイスで生成（自動）"
    echo "  ./screenshot_all.sh iphone   - iPhone のみ"
    echo "  ./screenshot_all.sh ipad     - iPad のみ"
    echo "  ./screenshot_all.sh manual   - 手動実行後の整理のみ"
    echo ""
}

# 手動実行の説明
manual_mode() {
    echo "📱 手動モード"
    echo "============================================"
    echo ""
    echo "以下の手順でXcodeからテストを実行してください:"
    echo ""
    echo "1. Xcodeでプロジェクトを開く:"
    echo "   open BPMSetlist.xcodeproj"
    echo ""
    echo "2. iPhoneシミュレーターを選択:"
    echo "   - 上部のデバイス選択: iPhone 15 Pro Max"
    echo ""
    echo "3. テストを実行:"
    echo "   - ⌘U または Product > Test"
    echo "   - Test Navigator (⌘6) > ScreenshotGenerator > Test"
    echo ""
    echo "4. iPadでも同様に実行:"
    echo "   - デバイス選択: iPad Pro (12.9-inch)"
    echo "   - ⌘U でテスト実行"
    echo ""
    echo "5. 完了したら、このスクリプトを実行:"
    echo "   ./organize_screenshots.sh"
    echo ""
    
    read -p "スクリーンショットの整理を実行しますか? (y/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./organize_screenshots.sh
    fi
    
    exit 0
}

# メイン処理
MODE=${1:-all}

case $MODE in
    manual)
        manual_mode
        ;;
    iphone|ipad|all)
        echo "🚀 自動モードで実行します"
        echo ""
        
        if [ -x "./generate_screenshots.sh" ]; then
            ./generate_screenshots.sh
        else
            echo "❌ generate_screenshots.sh が見つかりません"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_usage
        exit 0
        ;;
    *)
        echo "❌ 不明なオプション: $MODE"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ 完了！"
echo ""
echo "📁 生成されたスクリーンショット:"
if [ -d "screenshots" ]; then
    echo "   $PROJECT_DIR/screenshots/"
    ls -la screenshots/ 2>/dev/null || true
fi
if [ -d "screenshots_organized" ]; then
    echo "   $PROJECT_DIR/screenshots_organized/"
    ls -la screenshots_organized/ 2>/dev/null || true
fi
echo ""
echo "次のステップ:"
echo "1. スクリーンショットを確認"
echo "2. App Store Connectにアップロード"
echo "   https://appstoreconnect.apple.com/"
echo ""
echo "詳細: README_SCREENSHOTS.md または SCREENSHOT_GUIDE.md"
echo "════════════════════════════════════════════════════════"
