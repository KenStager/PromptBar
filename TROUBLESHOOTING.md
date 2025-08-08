# PromptBar Troubleshooting Guide

## Known Issues and Solutions

### Critical Fix: Empty Database Saves (RESOLVED)

**Issue**: Prompts were saving to database with empty title/content fields despite all pipeline layers reporting success.

**Root Cause**: SQLite parameter binding was using `nil` as the destructor parameter, causing Swift string data to be deallocated before SQLite could access it during INSERT operations.

**Solution**: Updated `SQLiteDatabase.swift` parameter binding:
```swift
// BEFORE (Incorrect)
sqlite3_bind_text(statement, idx, value, -1, nil)

// AFTER (Fixed)
sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
```

**Status**: ✅ **RESOLVED** - Prompts now save correctly with full title and content data.

**Files Modified**:
- `PromptBar/Database/SQLiteDatabase.swift` (parameter binding fix)

---

## Menu Bar Icon Not Appearing

If the menu bar icon isn't showing after building in Xcode, try these steps:

### 1. Check Console Output
Look for debug messages in Xcode's console when running the app:
- "PromptBar: Application launching..."
- "PromptBar: Setting up menu bar..."
- "PromptBar: Icon set successfully" or "PromptBar: Using text fallback for icon"

### 2. Verify Info.plist Settings
Make sure the Info.plist is properly configured:
- In Xcode, select your target → Build Settings
- Search for "Info.plist File"
- Set it to: `PromptBar/Info.plist`

### 3. Clean and Rebuild
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Product → Build (Cmd+B)
3. Product → Run (Cmd+R)

### 4. Check System Permissions
- System Preferences → Security & Privacy → Privacy
- Ensure Xcode has necessary permissions

### 5. Alternative Icon Setup
If the SF Symbol isn't working, try this manual approach:

```swift
// In AppDelegate.swift setupMenuBar() method, replace the icon code with:
button.title = "P"  // Simple text fallback
```

### 6. Check for Crashes
If the app is crashing silently:
1. Open Console.app
2. Filter for "PromptBar"
3. Look for crash logs

### 7. Verify Build Target
Ensure the deployment target is set correctly:
- Target → General → Deployment Info
- macOS 13.0 or later

### 8. Run Outside Xcode
Sometimes menu bar apps work better when run outside Xcode:
1. Build the app (Cmd+B)
2. Find the .app in Products folder
3. Copy to Applications folder
4. Run directly

### 9. Check Activity Monitor
Make sure PromptBar is actually running:
- Open Activity Monitor
- Search for "PromptBar"
- If it's there but no icon shows, there's a UI issue

### 10. Temporary Fix for Testing
Add this to AppDelegate to force the dock icon temporarily:
```swift
// Comment out this line temporarily:
// NSApp.setActivationPolicy(.accessory)
```

This will show a dock icon, helping verify the app is running.