#!/bin/bash

# Quick build verification after adding files to Xcode

echo "=== PromptBar Build Verification ==="
echo ""

# Check if we're in the right directory
if [ ! -f "PromptBar.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this from the promptbar directory"
    exit 1
fi

echo "🔨 Attempting to build PromptBar..."
echo ""

# Clean first
echo "🧹 Cleaning build folder..."
xcodebuild -project PromptBar.xcodeproj -scheme PromptBar -configuration Debug clean > /dev/null 2>&1

# Build
echo "🏗️  Building project..."
if xcodebuild -project PromptBar.xcodeproj -scheme PromptBar -configuration Debug build 2>&1 | tee build.log | grep -E "(error:|warning:|BUILD)"; then
    echo ""
    if grep -q "BUILD SUCCEEDED" build.log; then
        echo "✅ BUILD SUCCEEDED!"
        echo ""
        echo "🎉 All files are properly configured!"
        echo ""
        echo "Next steps:"
        echo "1. Run the app from Xcode (Cmd+R)"
        echo "2. Test the new UI polish features"
        echo "3. Verify performance targets are met"
    else
        echo "❌ BUILD FAILED"
        echo ""
        echo "Check build.log for details"
        echo "Common issues:"
        echo "- Missing file from target"
        echo "- Import statements needed"
        echo "- File not found errors"
    fi
else
    echo "❌ Build command failed to run"
    echo "Make sure Xcode command line tools are installed"
fi

# Clean up
rm -f build.log

echo ""
echo "📍 Build output location:"
echo "~/Library/Developer/Xcode/DerivedData/PromptBar-*/Build/Products/Debug/PromptBar.app"
