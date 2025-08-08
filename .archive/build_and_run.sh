#!/bin/bash

# Build and run PromptBar app
# Run this from the project root: /Users/kstager/Desktop/promptbar

echo "🔨 Building PromptBar..."

# Clean any previous builds
rm -rf ~/Library/Developer/Xcode/DerivedData/PromptBar-*

# Build the project
xcodebuild -project PromptBar.xcodeproj \
           -scheme PromptBar \
           -configuration Debug \
           -derivedDataPath ./build \
           build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    APP_PATH="./build/Build/Products/Debug/PromptBar.app"
    
    if [ -d "$APP_PATH" ]; then
        echo "🚀 Launching PromptBar..."
        echo "📝 Watch Console.app for debug output"
        echo "🔍 Filter by: PromptBar or process:PromptBar"
        echo ""
        echo "Debug messages to look for:"
        echo "  🔥 COPY: ..."
        echo "  🔥 SAVE: ..."
        echo "  🔥 CLIPBOARD: ..."
        echo "  🔥 REPO: ..."
        echo ""
        
        # Kill any existing instances
        pkill -f PromptBar.app || true
        
        # Launch the app
        open "$APP_PATH"
        
        echo "✅ PromptBar launched!"
        echo ""
        echo "To test Markdown copy:"
        echo "1. Click the menu bar icon"
        echo "2. Click on a prompt"
        echo "3. Click Copy button"
        echo "4. Paste somewhere to verify Markdown format"
        echo ""
        echo "To test save:"
        echo "1. Copy some text to clipboard"
        echo "2. Click menu bar icon"
        echo "3. Click clipboard button"
        echo "4. Enter title and save"
        echo "5. Check Console.app for 🔥 SAVE messages"
    else
        echo "❌ App not found at $APP_PATH"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
