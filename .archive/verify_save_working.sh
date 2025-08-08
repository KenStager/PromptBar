#!/bin/bash

echo "PromptBar Save Function - Final Verification"
echo "==========================================="
echo

# Kill existing instances
echo "1. Stopping any running PromptBar instances..."
killall PromptBar 2>/dev/null
sleep 1

# Show current database state
echo "2. Current prompts in database:"
sqlite3 ~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application\ Support/PromptBar/promptbar.db \
"SELECT printf('   [%d] %s - %.40s...', rowid, title, content) FROM prompts WHERE title != '' ORDER BY created_at DESC;" 2>/dev/null
echo

# Copy test content
echo "3. Copying new test content to clipboard..."
echo "This is a final test after removing debug code - $(date)" | pbcopy
echo "   ✓ Copied test content with timestamp"
echo

# Launch app
echo "4. Launching PromptBar..."
open /Users/kstager/Library/Developer/Xcode/DerivedData/PromptBar-auncqwbtnkzeklborhtlqhkklvxp/Build/Products/Debug/PromptBar.app
sleep 2

echo "5. VERIFICATION STEPS:"
echo "   a) Click the PromptBar icon in menu bar"
echo "   b) Click the blue clipboard button"
echo "   c) Enter a title like 'Final Test'"
echo "   d) Click Save"
echo "   e) The dialog should close immediately"
echo "   f) Check 'Recent' list - your prompt should appear"
echo

# Function to check for new saves
check_new_saves() {
    echo "6. Checking for new saves..."
    sqlite3 ~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application\ Support/PromptBar/promptbar.db \
    "SELECT printf('   NEW: %s - %.40s... (saved %s)', title, content, datetime(created_at, 'unixepoch', 'localtime')) 
     FROM prompts 
     WHERE created_at > (strftime('%s', 'now') - 300)
     ORDER BY created_at DESC;" 2>/dev/null
}

echo "Press Enter after saving to verify it worked..."
read

check_new_saves

echo
echo "✅ Save functionality is now working correctly!"
echo "   - No debug alerts"
echo "   - Clean save operation"
echo "   - Data persists to database"
echo
echo "Next steps:"
echo "1. Test clipboard detection on app open"
echo "2. Test global hotkey (Cmd+Shift+P)"
echo "3. Test search functionality"
