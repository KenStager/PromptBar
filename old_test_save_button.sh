#!/bin/bash

# Test script for PromptBar save button fix

echo "PromptBar Save Button Test Script"
echo "================================="
echo

# Kill any existing PromptBar instances
echo "1. Killing any existing PromptBar instances..."
killall PromptBar 2>/dev/null
sleep 1

# Copy some test content to clipboard
echo "2. Copying test content to clipboard..."
echo "This is a test prompt for PromptBar save functionality" | pbcopy
echo "   ✓ Copied: 'This is a test prompt for PromptBar save functionality'"
echo

# Launch the app
echo "3. Launching PromptBar..."
open /Users/kstager/Library/Developer/Xcode/DerivedData/PromptBar-auncqwbtnkzeklborhtlqhkklvxp/Build/Products/Debug/PromptBar.app
sleep 2

echo "4. Manual test steps:"
echo "   a) Click the PromptBar icon in the menu bar"
echo "   b) Click the blue clipboard button (should show save dialog)"
echo "   c) Enter 'Test Save' as the title"
echo "   d) Click the Save button"
echo
echo "5. Expected results:"
echo "   - You should hear a BEEP when clicking Save"
echo "   - You should see an alert saying 'Save button was clicked!'"
echo "   - Another alert should say 'savePrompt() Function Called!'"
echo "   - The dialog should close"
echo
echo "6. Open Console.app and filter by 'PromptBar' to see debug output"
echo

# Function to check database
check_database() {
    echo "7. Checking database for saved prompts..."
    sqlite3 ~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application\ Support/PromptBar/promptbar.db \
    "SELECT printf('   ID: %s | Title: %s | Content: %.30s...', id, title, content) FROM prompts WHERE title != '' ORDER BY created DESC LIMIT 5;" 2>/dev/null
    
    count=$(sqlite3 ~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application\ Support/PromptBar/promptbar.db \
    "SELECT COUNT(*) FROM prompts WHERE title != '';" 2>/dev/null)
    echo "   Total prompts with titles: $count"
}

# Wait for user to test
echo
echo "Press Enter after you've tried clicking the Save button..."
read

# Check results
check_database

echo
echo "Test complete!"
echo
echo "If the button didn't work:"
echo "1. Check Console.app for any 'PromptBar' messages"
echo "2. Try clicking directly on the button text"
echo "3. Try pressing Enter key instead of clicking"
