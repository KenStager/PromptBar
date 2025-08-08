#!/bin/bash

# Script to clean up duplicate files and organize project structure

echo "=== PromptBar File Organization Cleanup ==="
echo ""

# Check if we're in the right directory
if [ ! -f "PromptBar.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this from the promptbar directory"
    exit 1
fi

echo "📁 Current file structure issues:"
echo ""

# Check for duplicates
echo "🔍 Checking for duplicate files..."
echo ""

# Files that should be in Views directory
view_files=("MainView.swift" "SavePromptView.swift" "PromptViews.swift" "PreferencesView.swift")

echo "Files in root PromptBar directory that should be in Views:"
for file in "${view_files[@]}"; do
    if [ -f "PromptBar/$file" ]; then
        echo "   ⚠️  $file is in root directory"
    fi
done

echo ""
echo "Theme.swift locations:"
if [ -f "PromptBar/Theme.swift" ]; then
    echo "   ⚠️  Theme.swift in root directory (should be removed)"
fi
if [ -f "PromptBar/Shared/Theme/Theme.swift" ]; then
    echo "   ✅ Theme.swift in Shared/Theme (correct location)"
fi

echo ""
echo "=== Recommendations ==="
echo ""
echo "In Xcode, you should:"
echo ""
echo "1. Remove duplicate files from project (right-click → Delete → Remove Reference):"
echo "   - /PromptBar/Theme.swift (keep the one in Shared/Theme)"
echo ""
echo "2. Files are currently in root directory but added to project."
echo "   This is OK for now - they will work from there."
echo ""
echo "3. Make sure all files have PromptBar target checked"
echo ""
echo "4. Clean and rebuild:"
echo "   - Product → Clean Build Folder (Cmd+Shift+K)"
echo "   - Product → Build (Cmd+B)"
echo ""
echo "The flame icons (🔥) indicate files that might not be properly"
echo "added to the target. Select each file and check the target"
echo "membership in the File Inspector (right panel)."
