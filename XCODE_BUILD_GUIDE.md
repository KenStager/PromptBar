# PromptBar Xcode Build Configuration Guide

## Current Status ✅

Your PromptBar Xcode project has the following configuration:
- **Bundle ID**: com.promptbar.PromptBar
- **Deployment Target**: macOS 14.0
- **Swift Version**: 5.0
- **App Type**: Menu bar app (LSUIElement = true)
- **Sandboxing**: Disabled (as per requirements)
- **Network Access**: Enabled

## Files Currently in Build

The following source files are already included in your Xcode project:
1. PromptBarApp.swift
2. AppDelegate.swift
3. Prompt.swift
4. SQLiteDatabase.swift
5. Migrations.swift
6. PromptRepository.swift
7. DIContainer.swift
8. OllamaClient.swift
9. AnalysisQueue.swift

## Files That Need to Be Added 🆕

The following UI polish files need to be added to your Xcode project:

### 1. Theme.swift
- **Location**: `/PromptBar/Shared/Theme/Theme.swift`
- **Purpose**: Central design system with colors, typography, and styles
- **Target Group**: Create a "Theme" group under "Shared" folder

### 2. PromptViews.swift
- **Location**: `/PromptBar/Views/PromptViews.swift`
- **Purpose**: Reusable prompt card components
- **Target Group**: Add to "Views" group

### 3. PreferencesView.swift
- **Location**: `/PromptBar/Views/PreferencesView.swift`
- **Purpose**: Preferences window UI
- **Target Group**: Add to "Views" group

## Step-by-Step Instructions to Add Files

### Method 1: Using Xcode UI (Recommended)

1. **Open PromptBar.xcodeproj in Xcode**

2. **Create Theme Group**:
   - Right-click on "Shared" folder in project navigator
   - Select "New Group"
   - Name it "Theme"

3. **Add Theme.swift**:
   - Right-click on the new "Theme" group
   - Select "Add Files to 'PromptBar'..."
   - Navigate to `/PromptBar/Shared/Theme/Theme.swift`
   - Ensure "PromptBar" target is checked ✅
   - Click "Add"

4. **Add View Files**:
   - Right-click on "Views" group
   - Select "Add Files to 'PromptBar'..."
   - Select both:
     - `PromptViews.swift`
     - `PreferencesView.swift`
   - Ensure "PromptBar" target is checked ✅
   - Click "Add"

### Method 2: Drag and Drop

1. Open Finder to `/Users/kstager/Desktop/promptbar/PromptBar/`
2. Drag files directly into Xcode project navigator:
   - Drag `Theme.swift` to Shared → Theme group
   - Drag `PromptViews.swift` and `PreferencesView.swift` to Views group
3. In the dialog, ensure "PromptBar" target is checked

## Verify Build Configuration

After adding files, verify everything is set up correctly:

### 1. Check Target Membership
- Select each new file in project navigator
- In File Inspector (right panel), ensure "PromptBar" is checked under Target Membership

### 2. Build the Project
```bash
# From command line:
cd /Users/kstager/Desktop/promptbar
xcodebuild -project PromptBar.xcodeproj -scheme PromptBar -configuration Debug build

# Or in Xcode:
# Press Cmd+B
```

### 3. Fix Any Import Issues
If you get "No such module" errors, add these imports where needed:
```swift
import SwiftUI
import AppKit
import Combine
```

## Expected Project Structure

After adding all files, your project structure should look like:

```
PromptBar
├── PromptBarApp.swift
├── AppDelegate.swift
├── DIContainer.swift
├── Info.plist
├── PromptBar.entitlements
├── Models/
│   └── Prompt.swift
├── Database/
│   ├── SQLiteDatabase.swift
│   └── Migrations.swift
├── Repositories/
│   └── PromptRepository.swift
├── Services/
│   ├── OllamaClient.swift
│   └── AnalysisQueue.swift
├── Views/
│   ├── MainView.swift (updated)
│   ├── SavePromptView.swift (updated)
│   ├── PromptViews.swift (new)
│   └── PreferencesView.swift (new)
└── Shared/
    └── Theme/
        └── Theme.swift (new)
```

## Common Issues and Solutions

### Issue: "Use of unresolved identifier 'Theme'"
**Solution**: Make sure Theme.swift is added to the target and import it where needed

### Issue: Build fails with "No such module"
**Solution**: Clean build folder (Cmd+Shift+K) and rebuild

### Issue: UI not updating
**Solution**: Make sure you're using the updated MainView and SavePromptView files

## Testing the UI Polish

After successful build:
1. Run the app
2. Click the menu bar icon
3. Test new features:
   - Hover effects on prompt cards
   - Improved search bar with live indicator
   - Enhanced save dialog
   - New preferences window (if hooked up)

## Next Steps

1. **Add Preferences Menu Item** (if not already done):
   ```swift
   // In AppDelegate.swift setupMenuBar()
   let menu = NSMenu()
   menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
   ```

2. **Test Performance**: Ensure the app still meets the <50MB memory target

3. **Dark Mode Testing**: Switch system to dark mode and verify all colors work

## Build Configurations

Your project has proper configurations for both Debug and Release builds:
- **Debug**: Optimized for development with debug symbols
- **Release**: Optimized for distribution

No additional build settings changes are needed for the UI polish update.
