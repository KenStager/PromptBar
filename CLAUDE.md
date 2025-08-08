# CLAUDE.md

This file provides implementation guidance for Claude Code to build PromptBar from scratch (0-1).

## TL;DR

**What**: PromptBar is a macOS menu bar app for lightning-fast AI prompt management with local Ollama intelligence.

**Start Here**: Follow `/docs/BUILD_SEQUENCE.md` Phase 1 - Create Xcode project and implement foundation.

**Timeline**: 20-29 days to complete MVP following the 4-phase build sequence.

## 🚀 START HERE - Implementation Roadmap

### Your Mission
Build PromptBar exactly as specified in the north star documents. This is not a planning exercise - we have complete specifications ready for implementation.

### Implementation Phases (Follow BUILD_SEQUENCE.md)

**Phase 1: Foundation (Days 1-7)** ✅ Start Here
- Create macOS menu bar app with NSStatusItem
- Implement SQLite with FTS5 for <50ms search
- Build domain models and repository pattern
- **Success**: Menu bar icon appears, database works, tests pass

**Phase 2: Core Features (Days 8-17)**
- Clipboard detection and quick save
- Search with live results
- Global hotkey (Cmd+Shift+P)
- **Success**: Can save/search/retrieve prompts in <200ms

**Phase 3: Intelligence (Days 18-24)**
- Ollama HTTP client for AI analysis
- Background processing queue
- Fallback strategies
- **Success**: Prompts auto-categorize in <5s

**Phase 4: Polish (Days 25-29)**
- Preferences window
- Import/export functionality
- Performance optimization
- **Success**: All targets met, ready to ship

### Quick Start Commands

```bash
# 1. Create Xcode project (Phase 1, Step 1.1)
# Open Xcode → Create New Project → macOS → App
# Product Name: PromptBar
# Interface: SwiftUI, Language: Swift
# NO Core Data (we use SQLite directly)

# 2. Set up project structure
mkdir -p PromptBar/{App,Core,Features,Shared,Resources}
mkdir -p PromptBar/Core/{Domain,Data,Services}
mkdir -p PromptBar/Core/Domain/{Models,UseCases}

# 3. Install Ollama (for Phase 3)
curl -fsSL https://ollama.ai/install.sh | sh
ollama pull llama3.2:3b

# 4. Build commands (after Phase 1 setup)
xcodebuild -scheme PromptBar -configuration Debug build
xcodebuild test -scheme PromptBar -destination 'platform=macOS'
```

## 📋 Implementation Checklist

Follow this exact sequence from BUILD_SEQUENCE.md:

### Phase 1 Files (Create in Order)
- [x] `PromptBarApp.swift` - @main entry point
- [x] `AppDelegate.swift` - NSStatusItem setup
- [x] `Models/Prompt.swift` - Domain models
- [x] `Database/SQLiteDatabase.swift` - Database wrapper
- [x] `Database/Migrations.swift` - Schema setup
- [x] `Repositories/PromptRepository.swift` - Data access
- [x] `DIContainer.swift` - Dependency injection
- [x] **Run Phase 1 tests before proceeding**

### Phase 2 Files
- [x] `Services/ClipboardManager.swift`
- [x] `UseCases/SavePromptUseCase.swift`
- [x] `Views/MainView.swift` - SwiftUI content
- [x] `Services/HotkeyManager.swift`
- [x] `ViewModels/MainViewModel.swift`
- [x] **Verify <50ms search, <200ms save**

### Phase 3 Files
- [x] `Services/Ollama/OllamaClient.swift`
- [x] `Services/AnalysisQueue.swift`
- [x] `Views/PromptCard.swift` - With status
- [x] **Test Ollama integration with fallback**

### Phase 4 Files
- [x] `Views/PreferencesView.swift`
- [x] `Services/ImportExportService.swift`
- [x] `Services/SearchCache.swift`
- [x] **Profile memory <50MB idle**

## 🎯 Critical Implementation Requirements

### Performance Targets (MUST MEET)
```swift
// These are non-negotiable from specifications
let SEARCH_TARGET_MS = 50      // Search results
let SAVE_TARGET_MS = 200       // Save operation
let POPUP_TARGET_MS = 100      // Menu bar open
let ANALYSIS_TARGET_S = 5      // Ollama analysis
let MEMORY_IDLE_MB = 50        // Idle memory
let MEMORY_PEAK_MB = 100       // Peak memory
```

### Database Configuration (EXACT)
```sql
-- From DATA_SCHEMAS.md - DO NOT MODIFY
CREATE VIRTUAL TABLE prompts_fts USING fts5(
    id UNINDEXED,
    title,
    content,
    description,
    tags,
    tokenize='porter unicode61'
);
```

### Menu Bar Setup (CRITICAL)
```swift
// From TECHNICAL_ARCHITECTURE.md - handles edge cases
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
popover?.contentSize = NSSize(width: 400, height: 600)
popover?.behavior = .transient
```

## 📚 North Star Documents

All implementation decisions MUST follow these specifications:

1. **BUILD_SEQUENCE.md** - Your primary guide with step-by-step instructions
2. **PROJECT_REQUIREMENTS.md** - Feature specs and acceptance criteria
3. **TECHNICAL_ARCHITECTURE.md** - System design and patterns
4. **DATA_SCHEMAS.md** - Database and model specifications
5. **OLLAMA_INTEGRATION.md** - AI pipeline implementation

## ⚠️ Common Pitfalls (From BUILD_SEQUENCE.md)

### Pitfall 1: FTS5 Triggers
**Problem**: Search doesn't update after save
**Solution**: Create triggers AFTER FTS table with exact column names

### Pitfall 2: Hotkey Permissions
**Problem**: Global hotkey doesn't work
**Solution**: Request accessibility permissions early with clear UI

### Pitfall 3: Ollama Timeout
**Problem**: UI freezes during analysis
**Solution**: 10s timeout, background queue, always provide fallback

### Pitfall 4: Memory Leaks
**Problem**: Memory grows over time
**Solution**: Weak references in closures, proper NSStatusItem cleanup

### Pitfall 5: Search Performance
**Problem**: Search takes >50ms
**Solution**: Use FTS5 MATCH not LIKE, limit to 50 results

### Pitfall 6: SQLite Parameter Binding (CRITICAL - RESOLVED ✅)
**Problem**: Prompts save with empty title/content despite successful execution reports
**Root Cause**: Using `nil` as SQLite destructor parameter causes Swift strings to be deallocated before SQLite accesses them
**Solution**: Always use `SQLITE_TRANSIENT` for string parameters:
```swift
// ✅ CORRECT
sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
// ❌ INCORRECT - Will cause empty saves
sqlite3_bind_text(statement, idx, value, -1, nil)
```
**Status**: ✅ **FIXED** - This critical bug has been resolved in the current codebase

## 🧪 Validation at Each Phase

### Phase 1 Validation
```swift
// Run this test after Phase 1
func validatePhase1() async {
    // Menu bar appears
    assert(NSStatusBar.system.statusItem != nil)
    
    // Database works
    let repo = DIContainer.shared.resolve(PromptRepository.self)
    let prompt = Prompt(title: "Test", content: "Test")
    try! await repo.save(prompt)
    
    // FTS5 search works
    let results = try! await repo.search(query: "test")
    assert(!results.isEmpty)
    
    print("✅ Phase 1 Complete")
}
```

### Phase 2 Validation
```swift
func validatePhase2() {
    // Measure search performance
    let start = Date()
    let results = searchUseCase.execute("test")
    let duration = Date().timeIntervalSince(start)
    assert(duration < 0.05) // <50ms
    
    // Test hotkey
    print("Press Cmd+Shift+P - panel should appear")
    
    print("✅ Phase 2 Complete")
}
```

## 🏗️ Architecture Patterns (Follow Exactly)

### MVVM-C Structure
```
View (SwiftUI) → ViewModel (@Observable) → Use Case → Repository → SQLite
                      ↑                                    ↓
                 Coordinator ←──────── Navigation ────────┘
```

### Dependency Injection
```swift
// Register in AppDelegate.setupDependencies()
DIContainer.shared.register(SQLiteDatabase.self) { 
    // Implementation from BUILD_SEQUENCE Phase 1.7
}
```

### Actor-Based Queue (Phase 3)
```swift
actor AnalysisQueue {
    // Implementation from OLLAMA_INTEGRATION.md
    // MUST handle concurrent requests safely
}
```

## 🚦 Success Criteria

You have successfully built PromptBar when:

1. **All phase checkpoints pass** (see BUILD_SEQUENCE.md)
2. **Performance targets met**:
   - Search: <50ms for 10,000 prompts
   - Save: <200ms including UI feedback
   - Memory: <50MB idle, <100MB peak
3. **Features work as specified**:
   - Global hotkey opens panel
   - Clipboard detection on open
   - Ollama categorizes (with fallback)
   - Keyboard-only navigation
4. **Quality standards**:
   - No crashes in normal use
   - Graceful error handling
   - Native macOS look and feel

## 💡 Development Tips

1. **Start with Phase 1** - Don't skip ahead
2. **Test continuously** - Run validation after each step
3. **Follow specifications exactly** - Don't improvise
4. **Fix issues directly** - No workarounds or diagnostic scripts
5. **Check performance early** - Profile from the beginning

## 🐛 When Things Go Wrong

1. **Check BUILD_SEQUENCE.md** - Has troubleshooting for each phase
2. **Verify against specifications** - Are you following the docs exactly?
3. **Run phase validation** - Which checkpoint is failing?
4. **Check common pitfalls** - Listed above with solutions
5. **Review test output** - Tests will indicate specific failures

## 📦 Final Deployment

After Phase 4 completion:

```bash
# 1. Archive for release
xcodebuild -scheme PromptBar -configuration Release archive

# 2. Export for notarization
xcodebuild -exportArchive -archivePath ./PromptBar.xcarchive

# 3. Create DMG (see BUILD_SEQUENCE.md for full script)
create-dmg PromptBar.dmg ./build/

# 4. Notarize and staple
xcrun notarytool submit PromptBar.dmg --wait
xcrun stapler staple PromptBar.dmg
```

---

**Remember**: This is an implementation project, not a planning exercise. Every specification you need is in the `/docs/` folder. Follow BUILD_SEQUENCE.md step by step, validate at each checkpoint, and you'll have a working PromptBar in under 30 days.