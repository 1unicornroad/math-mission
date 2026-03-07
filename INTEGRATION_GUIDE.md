# Integration Guide - Math Mission

## ✅ What's Been Done

### Code Changes Complete
1. ✅ Custom practice button moved below times tables
2. ✅ Horizontal carousel ship selection
3. ✅ Locked ships darkened (very dark gray)
4. ✅ Custom fonts integrated in code
5. ✅ Game over returns to main menu
6. ✅ Vibration on meteor hit
7. ✅ All 7 font files downloaded to `Math Mission/Fonts/`
8. ✅ Info.plist created with font registrations
9. ✅ FontHelper.swift created with extensions

### Font Files Downloaded
Located in: `/Users/johnostler/Projects/math-mission/Math Mission/Math Mission/Fonts/`

- ✅ Orbitron-Regular.ttf (295 KB)
- ✅ Orbitron-Medium.ttf (294 KB)
- ✅ Orbitron-Bold.ttf (294 KB)
- ✅ Exo2-Regular.ttf (294 KB)
- ✅ Exo2-Medium.ttf (294 KB)
- ✅ Exo2-SemiBold.ttf (294 KB)
- ✅ Exo2-Bold.ttf (294 KB)

## 🔧 Manual Steps Required in Xcode

### Step 1: Add New Swift Files
1. Open `Math Mission.xcodeproj` in Xcode
2. Right-click on "Math Mission" folder in project navigator
3. Select "Add Files to 'Math Mission'..."
4. Navigate to and select these files:
   - `CustomTimesTableViewController.swift`
   - `ShipSelectionViewController.swift`
   - `FontHelper.swift`
5. **IMPORTANT**: Check these options:
   - ☑️ "Copy items if needed"
   - ☑️ "Create groups"
   - ☑️ Add to targets: "Math Mission"
6. Click "Add"

### Step 2: Add Font Files
1. In Xcode, right-click "Math Mission" folder
2. Select "Add Files to 'Math Mission'..."
3. Navigate to and select the `Fonts` folder
4. **IMPORTANT**: Check these options:
   - ☑️ "Copy items if needed"
   - ☑️ "Create folder references" (not "Create groups")
   - ☑️ Add to targets: "Math Mission"
5. Click "Add"

### Step 3: Verify Info.plist
1. In Xcode, select the project (Math Mission.xcodeproj)
2. Select "Math Mission" target
3. Go to "Info" tab
4. Expand "Custom iOS Target Properties"
5. Verify "Fonts provided by application" (UIAppFonts) exists
6. Should contain 7 entries:
   ```
   - Fonts/Orbitron-Regular.ttf
   - Fonts/Orbitron-Medium.ttf
   - Fonts/Orbitron-Bold.ttf
   - Fonts/Exo2-Regular.ttf
   - Fonts/Exo2-Medium.ttf
   - Fonts/Exo2-SemiBold.ttf
   - Fonts/Exo2-Bold.ttf
   ```

If not present, add manually:
1. Click "+" button
2. Type "Fonts provided by application"
3. Add each font path as an array item

### Step 4: Clean and Build
1. In Xcode menu: Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Check for any errors

### Step 5: Test Fonts
Run the app and verify:
- Title shows "MATH MISSION" in Orbitron Bold
- Questions appear in Exo 2 Bold
- All buttons use appropriate fonts
- If fonts don't appear, they'll fall back to system fonts

## 🎨 Visual Checklist

When running the app, you should see:

### Main Menu
- [x] Title in futuristic font (Orbitron)
- [x] Custom Practice button below 12× table
- [x] All text using space-themed typography

### Ship Selection
- [x] Horizontal scrolling carousel
- [x] Large 3D ship previews
- [x] Locked ships appear very dark
- [x] Unlocked ships in full color
- [x] Swipe to browse ships

### Gameplay
- [x] Selected ship model loads correctly
- [x] Questions in readable Exo 2 font
- [x] Device vibrates on meteor hit
- [x] Custom problems work (if selected)

### Game Over
- [x] Returns to main menu (not ship selection)
- [x] Stats displayed correctly
- [x] Spinning meteor decoration

## 🐛 Troubleshooting

### Fonts not appearing:
1. Verify files are in "Copy Bundle Resources" build phase:
   - Select target → Build Phases → Copy Bundle Resources
   - Should see all 7 .ttf files
2. Clean build folder and rebuild
3. Check Info.plist paths match exactly
4. Font names in code must match font names in files

### Build errors:
1. Missing files: Add Swift files as described in Step 1
2. Font files not found: Verify Fonts folder is added with "Create folder references"
3. Duplicate symbols: Check files aren't added twice to target

### Runtime issues:
1. App crashes on ship selection: Ensure new view controllers are added to target
2. Fonts show as system fonts: Check Info.plist registration
3. Custom practice doesn't work: Verify CustomTimesTableViewController is in target

## 📝 File Structure

```
Math Mission/
├── Math Mission/
│   ├── AppDelegate.swift
│   ├── MenuViewController.swift (✏️ modified)
│   ├── GameViewController.swift (✏️ modified)
│   ├── CustomTimesTableViewController.swift (✨ new)
│   ├── ShipSelectionViewController.swift (✨ new)
│   ├── FontHelper.swift (✨ new)
│   ├── Info.plist (✨ new)
│   ├── Fonts/ (✨ new)
│   │   ├── Orbitron-Regular.ttf
│   │   ├── Orbitron-Medium.ttf
│   │   ├── Orbitron-Bold.ttf
│   │   ├── Exo2-Regular.ttf
│   │   ├── Exo2-Medium.ttf
│   │   ├── Exo2-SemiBold.ttf
│   │   └── Exo2-Bold.ttf
│   └── art.scnassets/
└── Math Mission.xcodeproj/
```

## 🚀 Ready to Build!

After completing the manual steps above, your app will have:
- ✨ Beautiful custom fonts throughout
- 🚀 Smooth horizontal ship carousel
- 🎯 Custom practice mode
- 📊 Enhanced game over stats
- 📱 Professional space-themed UI
- 🔐 Progressive ship unlocking system

Build and enjoy your enhanced Math Mission! 🎮
