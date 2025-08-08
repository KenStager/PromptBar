# PromptBar

A lightning-fast macOS menu bar app for AI prompt management with local Ollama intelligence.

## 🚨 **Current Status: Critical Issues Need Resolution**

- ✅ **Build Status**: Compiles successfully
- ❌ **Save Operation**: BROKEN since Dec 8, 2024 (critical)
- ❌ **Copy Feature**: Markdown formatting not working
- ⚠️ **Memory Usage**: 82MB (target: 50MB)
- 🔄 **Testing**: Core features need validation

## 🚀 **Quick Start**

### Prerequisites
- macOS 14.0+
- Xcode 16+
- Ollama (for AI features - Phase 3)

### Build & Run
```bash
cd /Users/kstager/Desktop/promptbar
open PromptBar.xcodeproj

# Build and run in Xcode
# OR
xcodebuild -scheme PromptBar -configuration Debug build
```

### Database Location
```
~/Library/Containers/com.promptbar.PromptBar/Data/Library/Application Support/PromptBar/promptbar.db
```

## 🎯 **Implementation Phases**

Follow the complete implementation guide in `/docs/BUILD_SEQUENCE.md`:

- **Phase 1**: Foundation (Database, Menu Bar, Core Models) - ⚠️ ISSUES
- **Phase 2**: Core Features (Save, Search, Hotkeys) - 🔄 PENDING
- **Phase 3**: AI Integration (Ollama, Analysis Queue) - 🔄 PENDING  
- **Phase 4**: Polish (Preferences, Import/Export) - 🔄 PENDING

## 🔥 **URGENT: Fix Critical Issues**

Before implementing new features, resolve these blocking issues:

### 1. Save Operation Failure
**Problem**: Save button does nothing, no prompts saved  
**Debug Steps**:
```bash
# Monitor with Console.app while testing save
# Check FTS5 triggers and database constraints
# Test: Add prompt → Click Save → Check database
```

### 2. Markdown Copy Broken
**Problem**: Copy doesn't format as Markdown
**Debug Steps**:
```bash
# Test ClipboardManager.formatPromptAsMarkdown() directly
# Verify static method accessibility
# Check clipboard content after copy operation
```

### 3. Memory Over Target
**Problem**: 82MB idle (target: 50MB)
**Debug Steps**:
```bash
# Profile with Instruments
# Check for memory leaks in NSStatusItem
# Audit SearchCache and Theme allocations
```

## 📋 **Technical Architecture**

### Core Technologies
- **Framework**: SwiftUI with AppKit integration
- **Database**: SQLite with FTS5 full-text search
- **Architecture**: MVVM-C with dependency injection
- **AI**: Ollama HTTP client (local LLM)
- **Platform**: macOS 14.0+ (sandboxed)

### Key Components
```
PromptBar/
├── Core/Domain/Models/        # Prompt, Tag domain models
├── Core/Data/                 # SQLiteDatabase, Repositories
├── Services/                  # ClipboardManager, OllamaClient
├── Features/                  # MainView, SavePromptView
└── Shared/Theme/              # Design system
```

### Performance Targets
- Search: <50ms ✅ (currently 9ms)
- Save: <200ms ❌ (currently broken)
- Memory: <50MB idle ❌ (currently 82MB)
- AI Analysis: <5s 🔄 (not tested)

## 🛠️ **Development Setup**

### Project Configuration
- **Bundle ID**: com.promptbar.PromptBar
- **Deployment**: macOS 14.0+
- **Architecture**: arm64-apple-macos14.0
- **Sandboxing**: Enabled with container support

### Build Configuration
```bash
# Debug build
xcodebuild -scheme PromptBar -configuration Debug

# Release build
xcodebuild -scheme PromptBar -configuration Release

# Run tests
xcodebuild test -scheme PromptBar
```

### Key Files
- `AppDelegate.swift` - App lifecycle, NSStatusItem setup
- `DIContainer.swift` - Dependency injection
- `SQLiteDatabase.swift` - Database abstraction
- `MainViewModel.swift` - Primary UI logic
- `Theme.swift` - Design system

## 📚 **Documentation**

Essential reading in priority order:

1. **CLAUDE.md** - Current status and immediate next steps
2. **TECHNICAL_DEBT.md** - Critical issues and fixes
3. **docs/BUILD_SEQUENCE.md** - Complete implementation guide
4. **docs/TECHNICAL_ARCHITECTURE.md** - System design
5. **docs/PROJECT_REQUIREMENTS.md** - Feature specifications

## 🧪 **Testing & Validation**

### Manual Testing
```bash
# Test save operation
1. Open PromptBar (should appear in menu bar)
2. Click icon → popover opens
3. Enter title/content → click Save
4. Verify prompt appears in list

# Test search
1. Type in search box
2. Verify results update in <50ms
3. Test FTS5 search functionality

# Test copy
1. Click prompt → detail view opens
2. Click copy button
3. Paste → should be formatted as Markdown
```

### Automated Testing
```bash
# Run validation tests
cd test/
swift Phase1ValidationTest.swift
swift test_markdown_copy.swift
```

## 🔧 **Troubleshooting**

### Common Issues

**"DatabaseError error 0"**
- Database initialization failed
- Check path: Container/Data/Library/Application Support/PromptBar/
- Verify FTS5 support: `sqlite3 ':memory:' 'pragma compile_options;'`

**"Invalid input provided"**
- Repository validation failing
- Check empty database records
- Verify FTS5 triggers

**Save button does nothing**
- ✨ **CURRENT CRITICAL ISSUE**
- Check SavePromptUseCase execution
- Monitor Console.app for errors
- Test direct database INSERT

### Debug Tools
- **Console.app**: View app logs and print statements
- **Instruments**: Memory profiling and leak detection
- **sqlite3 CLI**: Direct database inspection
- **Xcode Debugger**: Breakpoints in save operation

## 🎯 **Project Goals**

### MVP Features (Phase 1-2)
- [x] Menu bar integration
- [x] SQLite database with FTS5
- [ ] Working save operation ❌ **BLOCKED**
- [ ] Fast search (<50ms)
- [ ] Clipboard detection
- [ ] Global hotkey (Cmd+Shift+P)

### Advanced Features (Phase 3-4)
- [ ] Ollama AI categorization
- [ ] Background analysis queue
- [ ] Preferences window
- [ ] Import/Export functionality
- [ ] Memory optimization (<50MB)

## 🤝 **Contributing**

1. **Fix critical issues first** - Don't add features while save is broken
2. **Follow BUILD_SEQUENCE.md** - Step-by-step implementation guide
3. **Maintain performance targets** - Validate all changes
4. **Use existing architecture** - MVVM-C, DIContainer, Theme system
5. **Test thoroughly** - Both manual and automated validation

## 📄 **License**

This project is developed as a functional macOS application for AI prompt management. See implementation details in the docs/ directory.

---

**⚠️ CRITICAL**: Save operation broken since Dec 8, 2024. This must be fixed before any feature development.
