#!/bin/bash

# Script to add fonts to Math Mission Xcode project

PROJECT_DIR="/Users/johnostler/Projects/math-mission/Math Mission"
FONTS_DIR="$PROJECT_DIR/Math Mission/Fonts"

echo "Adding fonts to Xcode project..."

# Create Info.plist if it doesn't exist (for fonts)
INFO_PLIST="$PROJECT_DIR/Math Mission/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "Creating Info.plist..."
    cat > "$INFO_PLIST" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>UIAppFonts</key>
    <array>
        <string>Fonts/Orbitron-Regular.ttf</string>
        <string>Fonts/Orbitron-Medium.ttf</string>
        <string>Fonts/Orbitron-Bold.ttf</string>
        <string>Fonts/Exo2-Regular.ttf</string>
        <string>Fonts/Exo2-Medium.ttf</string>
        <string>Fonts/Exo2-SemiBold.ttf</string>
        <string>Fonts/Exo2-Bold.ttf</string>
    </array>
</dict>
</plist>
EOF
else
    echo "Info.plist exists, adding font entries..."
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts array" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:0 string 'Fonts/Orbitron-Regular.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:1 string 'Fonts/Orbitron-Medium.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:2 string 'Fonts/Orbitron-Bold.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:3 string 'Fonts/Exo2-Regular.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:4 string 'Fonts/Exo2-Medium.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:5 string 'Fonts/Exo2-SemiBold.ttf'" "$INFO_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :UIAppFonts:6 string 'Fonts/Exo2-Bold.ttf'" "$INFO_PLIST" 2>/dev/null || true
fi

echo "✅ Fonts configured in Info.plist"
echo ""
echo "IMPORTANT: You must manually add the font files to Xcode:"
echo "1. Open Math Mission.xcodeproj in Xcode"
echo "2. Right-click 'Math Mission' group → Add Files to 'Math Mission'"
echo "3. Select the 'Fonts' folder"
echo "4. Check 'Copy items if needed'"
echo "5. Check 'Create groups'"
echo "6. Select 'Math Mission' target"
echo "7. Click 'Add'"
echo ""
echo "Font files are located at:"
echo "$FONTS_DIR"
