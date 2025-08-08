#!/bin/bash

# Complete list of files that should be in the Xcode build

echo "=== PromptBar Complete Build File Check ==="
echo ""
echo "Checking which Swift files need to be added to Xcode project..."
echo ""

# Files we know are already in the build
in_build=(
    "PromptBarApp.swift"
    "AppDelegate.swift"
    "Prompt.swift"
    "SQLiteDatabase.swift"
    "Migrations.swift"
    "PromptRepository.swift"
    "DIContainer.swift"
    "OllamaClient.swift"
    "AnalysisQueue.swift"
)

# Files that should be in the build
should_be_in_build=(
    "MainView.swift"
    "SavePromptView.swift"
    "PromptViews.swift"
    "PreferencesView.swift"
    "Theme.swift"
)

echo "📋 Files already in Xcode build phase:"
for file in "${in_build[@]}"; do
    echo "   ✅ $file"
done

echo ""
echo "📝 Files that need to be added to Xcode:"
for file in "${should_be_in_build[@]}"; do
    # Find the file
    found=$(find PromptBar -name "$file" -type f 2>/dev/null | head -1)
    if [ -n "$found" ]; then
        echo "   🆕 $file (found at: $found)"
    else
        echo "   ❌ $file (FILE NOT FOUND!)"
    fi
done

echo ""
echo "=== Summary ==="
echo "Total files in build: ${#in_build[@]}"
echo "Files to add: ${#should_be_in_build[@]}"
echo "Total files needed: $((${#in_build[@]} + ${#should_be_in_build[@]}))"

echo ""
echo "=== Instructions ==="
echo "1. Open PromptBar.xcodeproj in Xcode"
echo "2. Add ALL the files marked with 🆕 above"
echo "3. Make sure each file has the PromptBar target checked"
echo "4. Build with Cmd+B to verify"
