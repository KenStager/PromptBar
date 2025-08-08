#!/bin/bash

# Script to add UI Polish files to Xcode project
# Run this from the project root directory

# Add files to project using xcodeproj gem or manually via Xcode
echo "Please add the following files to your Xcode project:"
echo ""
echo "1. Theme.swift - Add to PromptBar/Shared/Theme/"
echo "2. PromptViews.swift - Add to PromptBar/Views/"
echo "3. SavePromptView.swift - Update existing in PromptBar/Views/"
echo "4. PreferencesView.swift - Add to PromptBar/Views/"
echo "5. MainView.swift - Update existing in PromptBar/Views/"
echo ""
echo "Make sure to:"
echo "- Add them to the PromptBar target"
echo "- Place them in the correct groups in Xcode"
echo "- Build and run to test the new UI"
