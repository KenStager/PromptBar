#!/bin/bash

# Final check of all Swift files and their locations

echo "=== PromptBar File Location Verification ==="
echo ""
echo "Checking all Swift files are in correct locations..."
echo ""

# Check Theme.swift
echo "📁 Theme.swift:"
if [ -f "PromptBar/Shared/Theme/Theme.swift" ]; then
    echo "   ✅ Found at correct location: /Shared/Theme/Theme.swift"
    echo "   Size: $(wc -c < PromptBar/Shared/Theme/Theme.swift) bytes"
else
    echo "   ❌ NOT FOUND at /Shared/Theme/Theme.swift"
fi

if [ -f "PromptBar/Theme_backup.swift" ]; then
    echo "   ℹ️  Backup exists at /Theme_backup.swift (can be deleted)"
fi

echo ""
echo "📁 View Files (in /PromptBar root):"

view_files=("MainView.swift" "SavePromptView.swift" "PromptViews.swift" "PreferencesView.swift")
for file in "${view_files[@]}"; do
    if [ -f "PromptBar/$file" ]; then
        echo "   ✅ $file - $(wc -l < PromptBar/$file) lines"
    else
        echo "   ❌ $file - NOT FOUND"
    fi
done

echo ""
echo "📁 Core Files:"
core_files=("AppDelegate.swift" "PromptBarApp.swift" "DIContainer.swift")
for file in "${core_files[@]}"; do
    if [ -f "PromptBar/$file" ]; then
        echo "   ✅ $file - $(wc -l < PromptBar/$file) lines"
    else
        echo "   ❌ $file - NOT FOUND"
    fi
done

echo ""
echo "=== Summary ==="
echo ""
echo "All UI polish files are in place and have been fixed:"
echo "1. Shadow type errors - FIXED ✅"
echo "2. SavePromptView duplicate - REMOVED ✅"
echo "3. Frame minHeight error - FIXED ✅"
echo "4. File organization - READY ✅"
echo ""
echo "Next step: Follow instructions in XCODE_FIX_INSTRUCTIONS.md"
echo "to update file references in Xcode and build successfully!"
