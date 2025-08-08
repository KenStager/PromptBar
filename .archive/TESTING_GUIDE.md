# PromptBar Testing Guide - August 7, 2025

## Current Status
- **Build**: ✅ Fixed (ClipboardManager and HotkeyManager now included in build)
- **Markdown Copy**: ✅ Code fixed with debug logging
- **Save Operation**: ⚠️ Has debug logging, needs testing
- **Database**: ✅ Working with 1 test prompt

## How to Build and Test

### Option 1: Using Xcode
1. Open `/Users/kstager/Desktop/promptbar/PromptBar.xcodeproj` in Xcode
2. Press Cmd+B to build
3. Press Cmd+R to run
4. Open Console.app and filter for "PromptBar"

### Option 2: Using Command Line
```bash
cd /Users/kstager/Desktop/promptbar
./build_and_run.sh
```

## Testing Markdown Copy Feature

### Setup
1. Open Console.app
2. Filter messages by: `process == "PromptBar"`
3. Launch PromptBar

### Test Steps
1. Click the PromptBar menu bar icon
2. Click on any prompt in the list
3. Click the "Copy" button in the detail view
4. Look for these debug messages in Console:
   - `🔥 COPY: copyPrompt called for prompt: [title]`
   - `🔥 COPY: Markdown formatted, length: [number] characters`
   - `🔥 COPY: Markdown preview:`
   - `🔥 CLIPBOARD: copy() called with text length: [number]`
   - `🔥 CLIPBOARD: setString result: true`
5. Paste into any text editor to verify Markdown format

### Expected Markdown Format
```markdown
# Prompt Title

*Description if present*

Prompt content goes here...

---
Category: CategoryName | Tags: tag1, tag2 | Created: Aug 7, 2025
```

## Testing Save Operation

### Test Steps
1. Copy any text to your clipboard (Cmd+C)
2. Click PromptBar menu bar icon
3. Click the clipboard button (bottom left)
4. Enter a title for your prompt
5. Click "Save"

### Debug Messages to Watch For
```
🔥 SAVE: savePrompt() called
🔥 SAVE: saveTitle = 'Your Title'
🔥 SAVE: clipboardContent = 'Your content...'
🔥 SAVE: Starting save operation...
🔥 SAVE: Calling savePromptUseCase.execute()
🔥 SAVE: Prompt saved successfully - id: UUID, title: 'Your Title'
```

### If Save Fails
Look for error messages like:
- `🔥 SAVE: Failed - empty title after trimming`
- `🔥 SAVE: Failed - empty content after trimming`
- `🔥 SAVE: Error occurred - [error description]`

## Database Verification

### Check Database Content
```bash
sqlite3 ~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application\ Support/PromptBar/promptbar.db

# Count prompts
SELECT COUNT(*) FROM prompts;

# View all prompts
SELECT id, title, substr(content, 1, 50) as preview FROM prompts;

# Check for empty records
SELECT * FROM prompts WHERE title = '' OR content = '';
```

## Common Issues and Fixes

### Issue: Markdown copy doesn't work
**Fix Applied**: Added debug logging to trace the issue. ClipboardManager.swift and HotkeyManager.swift were not included in the Xcode project build. Fixed by adding proper references in project.pbxproj.

### Issue: Save doesn't work
**Debug Steps**:
1. Check Console for `🔥 SAVE:` messages
2. Verify title and content are not empty
3. Check for database errors in Console
4. Verify FTS5 triggers aren't blocking (already modified to use INSERT OR IGNORE)

### Issue: No debug output in Console
**Solution**: Make sure to filter Console.app by "PromptBar" or use:
```bash
log stream --predicate 'process == "PromptBar"' --level debug
```

## Memory Usage Check
```bash
# While app is running
ps aux | grep PromptBar
# Look at RSS column (should be <50MB when idle)
```

## Performance Targets
- Search: <50ms (Currently: 9ms ✅)
- Save: <200ms (Need to measure)
- Memory idle: <50MB (Currently: 82MB ❌)

## Files Modified in This Session
1. `/PromptBar/AppDelegate.swift` - Added debug logging to copyPrompt
2. `/PromptBar/Services/ClipboardManager.swift` - Added debug logging to copy method
3. `/PromptBar.xcodeproj/project.pbxproj` - Fixed ClipboardManager and HotkeyManager references

## Next Steps
1. Build and run the app
2. Test Markdown copy with Console.app open
3. Verify save operation works
4. If all works, remove debug logging for production
5. Test global hotkey (Cmd+Shift+P)
6. Profile memory usage to reduce from 82MB to <50MB
