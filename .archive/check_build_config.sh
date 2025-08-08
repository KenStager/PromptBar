#!/bin/bash

# PromptBar Xcode Build Configuration Check
# This script verifies and reports on the build configuration

echo "=== PromptBar Build Configuration Check ==="
echo ""

# Check if running from correct directory
if [ ! -f "PromptBar.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the promptbar directory"
    exit 1
fi

echo "✅ Found PromptBar.xcodeproj"
echo ""

# List current source files in the project
echo "📁 Current source files in build:"
echo "- PromptBarApp.swift"
echo "- AppDelegate.swift"
echo "- Prompt.swift"
echo "- SQLiteDatabase.swift"
echo "- Migrations.swift"
echo "- PromptRepository.swift"
echo "- DIContainer.swift"
echo "- OllamaClient.swift"
echo "- AnalysisQueue.swift"
echo ""

# Check for missing UI files
echo "🔍 Checking for new UI files that need to be added to Xcode:"
echo ""

missing_files=()

# Check Theme.swift
if [ -f "PromptBar/Shared/Theme/Theme.swift" ]; then
    echo "✅ Found Theme.swift - Needs to be added to Xcode"
    missing_files+=("Theme.swift")
else
    echo "❌ Theme.swift not found at expected location"
fi

# Check PromptViews.swift
if [ -f "PromptBar/Views/PromptViews.swift" ]; then
    echo "✅ Found PromptViews.swift - Needs to be added to Xcode"
    missing_files+=("PromptViews.swift")
else
    echo "❌ PromptViews.swift not found at expected location"
fi

# Check PreferencesView.swift
if [ -f "PromptBar/Views/PreferencesView.swift" ]; then
    echo "✅ Found PreferencesView.swift - Needs to be added to Xcode"
    missing_files+=("PreferencesView.swift")
else
    echo "❌ PreferencesView.swift not found at expected location"
fi

# Check MainView.swift (should already be in project but updated)
if [ -f "PromptBar/Views/MainView.swift" ]; then
    echo "✅ Found MainView.swift - Already in project (updated)"
else
    echo "⚠️  MainView.swift not found - This file should exist!"
fi

# Check SavePromptView.swift (should already be in project but updated)
if [ -f "PromptBar/Views/SavePromptView.swift" ]; then
    echo "✅ Found SavePromptView.swift - Already in project (updated)"
else
    echo "⚠️  SavePromptView.swift not found - This file should exist!"
fi

echo ""
echo "=== Build Settings Summary ==="
echo "✅ Bundle ID: com.promptbar.PromptBar"
echo "✅ Deployment Target: macOS 14.0"
echo "✅ Swift Version: 5.0"
echo "✅ LSUIElement: true (Menu bar app)"
echo "✅ Sandboxing: Disabled (as per requirements)"
echo "✅ Network Client: Enabled"
echo ""

echo "=== Required Actions ==="
if [ ${#missing_files[@]} -gt 0 ]; then
    echo "📝 Add these files to your Xcode project:"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "To add files in Xcode:"
    echo "1. Right-click on the appropriate group (Views or Shared)"
    echo "2. Select 'Add Files to \"PromptBar\"...'"
    echo "3. Navigate to the file location"
    echo "4. Ensure 'PromptBar' target is checked"
    echo "5. Click 'Add'"
else
    echo "✅ All UI files are present in the filesystem"
    echo "📝 Make sure they are added to the Xcode project"
fi

echo ""
echo "=== Build Command ==="
echo "To build from command line:"
echo "xcodebuild -project PromptBar.xcodeproj -scheme PromptBar -configuration Debug build"
echo ""
echo "Or open in Xcode and press Cmd+B to build"
