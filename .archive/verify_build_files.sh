#!/bin/bash

echo "🔍 PromptBar Build Files Verification"
echo "======================================"
echo ""

PROJECT_FILE="/Users/kstager/Desktop/promptbar/PromptBar.xcodeproj/project.pbxproj"

# Essential Swift files that MUST be in the build
REQUIRED_FILES=(
    "PromptBarApp.swift"
    "AppDelegate.swift"
    "DIContainer.swift"
    "MainView.swift"
    "SavePromptView.swift"
    "PromptDetailView.swift"
    "PromptViews.swift"
    "PreferencesView.swift"
    "Theme.swift"
    "Prompt.swift"
    "SQLiteDatabase.swift"
    "Migrations.swift"
    "PromptRepository.swift"
    "SavePromptUseCase.swift"
    "ClipboardManager.swift"
    "HotkeyManager.swift"
    "OllamaClient.swift"
    "AnalysisQueue.swift"
)

echo "Checking for required files in build configuration..."
echo ""

ALL_GOOD=true

for file in "${REQUIRED_FILES[@]}"; do
    if grep -q "$file in Sources" "$PROJECT_FILE"; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING FROM BUILD!"
        ALL_GOOD=false
    fi
done

echo ""
echo "----------------------------------------"

if [ "$ALL_GOOD" = true ]; then
    echo "✅ All required files are in the build configuration!"
else
    echo "⚠️  Some files are missing from the build!"
    echo "    Open Xcode and add the missing files to the target."
fi

echo ""
echo "Files in Sources build phase:"
echo "-----------------------------"
grep "\.swift in Sources" "$PROJECT_FILE" | sed 's/.*\/\* \(.*\) in Sources.*/  - \1/' | sort -u
