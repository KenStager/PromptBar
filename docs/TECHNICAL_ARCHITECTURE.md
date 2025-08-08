# TECHNICAL ARCHITECTURE: PromptBar
*Version 1.0 - System Design Specification*
*Last Updated: January 2025*

## Executive Summary

PromptBar is architected as a lightweight macOS menu bar application prioritizing sub-second response times and minimal resource usage. The system uses MVVM-C architecture with SwiftUI, SQLite FTS5 for search, and optional Ollama integration for intelligent features.

### Architecture Principles

1. **Speed First**: Every architectural decision optimizes for <100ms user-perceived latency
2. **Minimal Resource Usage**: <50MB memory footprint when idle
3. **Native macOS Integration**: Leverage platform capabilities for optimal UX
4. **Modular Design**: Clear separation between UI, business logic, and data layers
5. **Offline First**: Full functionality without network dependencies

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI 5.0+ with AppKit integration
- **Minimum macOS**: 13.0 (Ventura)
- **Database**: SQLite 3.37+ with FTS5
- **AI Integration**: Ollama HTTP API (optional)
- **Concurrency**: Swift Concurrency (async/await)
- **Testing**: XCTest + Swift Testing

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Menu Bar UI Layer                      │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  NSStatusItem│  │   NSPopover  │  │  SwiftUI Views   │   │
│  │   (Icon)    │  │  (Container)  │  │  (Content)       │   │
│  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘   │
└─────────┼─────────────────┼──────────────────┼─────────────┘
          │                 │                  │
┌─────────▼─────────────────▼──────────────────▼─────────────┐
│                    Presentation Layer                         │
│  ┌────────────┐  ┌─────────────┐  ┌───────────────────┐    │
│  │ViewModels  │  │Coordinators │  │State Management   │    │
│  │(@Observable)│  │(Navigation) │  │(@StateObject)     │    │
│  └──────┬─────┘  └──────┬──────┘  └────────┬─────────┘    │
└─────────┼───────────────┼──────────────────┼──────────────┘
          │               │                  │
┌─────────▼───────────────▼──────────────────▼──────────────┐
│                    Business Logic Layer                      │
│  ┌───────────┐  ┌────────────┐  ┌─────────────────────┐   │
│  │Use Cases  │  │ Services   │  │ Domain Models       │   │
│  │(Interactors)│ │(Ollama,etc)│  │ (Prompt, Tag, etc) │   │
│  └──────┬────┘  └──────┬─────┘  └──────────┬─────────┘   │
└─────────┼──────────────┼───────────────────┼──────────────┘
          │              │                   │
┌─────────▼──────────────▼───────────────────▼──────────────┐
│                      Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Repositories │  │SQLite + FTS5 │  │ Cache Manager   │  │
│  │ (Protocols)  │  │(Persistence) │  │ (In-Memory)     │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**Menu Bar UI Layer**
- Manages NSStatusItem lifecycle
- Handles NSPopover presentation/dismissal
- Renders SwiftUI content within AppKit container

**Presentation Layer**
- ViewModels handle business logic for views
- Coordinators manage navigation flow
- State management via SwiftUI property wrappers

**Business Logic Layer**
- Use cases encapsulate business rules
- Services provide external integrations
- Domain models represent core entities

**Data Layer**
- Repositories abstract data access
- SQLite provides persistent storage
- Cache manager optimizes performance

## Module Structure

```
/PromptBar
├── /App
│   ├── PromptBarApp.swift           # @main entry point
│   ├── AppDelegate.swift            # NSStatusItem setup
│   ├── /Configuration
│   │   ├── Constants.swift          # App-wide constants
│   │   ├── DIContainer.swift        # Dependency injection
│   │   └── AppConfiguration.swift   # Environment config
│   └── /Coordinators
│       ├── AppCoordinator.swift     # Root coordinator
│       └── NavigationPath.swift     # Navigation state
│
├── /Core
│   ├── /Domain
│   │   ├── /Models
│   │   │   ├── Prompt.swift         # Core prompt model
│   │   │   ├── Tag.swift            # Tag model
│   │   │   ├── Category.swift       # Category model
│   │   │   └── AnalysisResult.swift # Ollama result
│   │   ├── /UseCases
│   │   │   ├── SavePromptUseCase.swift
│   │   │   ├── SearchPromptsUseCase.swift
│   │   │   ├── AnalyzePromptUseCase.swift
│   │   │   └── CopyPromptUseCase.swift
│   │   └── /Protocols
│   │       ├── PromptRepository.swift
│   │       ├── AnalysisService.swift
│   │       └── ClipboardService.swift
│   │
│   ├── /Data
│   │   ├── /Repositories
│   │   │   ├── PromptRepositoryImpl.swift
│   │   │   └── /SQLite
│   │   │       ├── SQLiteDatabase.swift
│   │   │       ├── Migrations.swift
│   │   │       └── FTS5Configuration.swift
│   │   └── /Cache
│   │       ├── SearchCache.swift
│   │       └── AnalysisCache.swift
│   │
│   └── /Services
│       ├── /Ollama
│       │   ├── OllamaService.swift
│       │   ├── OllamaModels.swift
│       │   └── AnalysisQueue.swift
│       ├── /System
│       │   ├── ClipboardManager.swift
│       │   ├── HotkeyManager.swift
│       │   └── NotificationService.swift
│       └── /Storage
│           ├── BackupService.swift
│           └── ImportExportService.swift
│
├── /Features
│   ├── /MenuBar
│   │   ├── MenuBarController.swift  # NSStatusItem management
│   │   └── PopoverManager.swift     # NSPopover lifecycle
│   │
│   ├── /Main
│   │   ├── MainView.swift           # Root SwiftUI view
│   │   ├── MainViewModel.swift      # Main screen logic
│   │   └── /Components
│   │       ├── SearchBar.swift
│   │       ├── TabSelector.swift
│   │       └── FooterBar.swift
│   │
│   ├── /Search
│   │   ├── SearchView.swift
│   │   ├── SearchViewModel.swift
│   │   └── /Components
│   │       ├── SearchResultCard.swift
│   │       ├── SearchHighlight.swift
│   │       └── EmptySearchState.swift
│   │
│   ├── /QuickSave
│   │   ├── QuickSaveView.swift
│   │   ├── QuickSaveViewModel.swift
│   │   └── ClipboardDetector.swift
│   │
│   ├── /Categories
│   │   ├── CategoriesView.swift
│   │   ├── CategoriesViewModel.swift
│   │   └── CategoryTile.swift
│   │
│   └── /Settings
│       ├── SettingsWindow.swift
│       ├── /Tabs
│       │   ├── GeneralSettings.swift
│       │   ├── OllamaSettings.swift
│       │   ├── DataSettings.swift
│       │   └── AdvancedSettings.swift
│       └── SettingsStore.swift
│
├── /Shared
│   ├── /UI
│   │   ├── /Components
│   │   │   ├── TagView.swift
│   │   │   ├── LoadingIndicator.swift
│   │   │   └── KeyboardShortcutView.swift
│   │   ├── /Modifiers
│   │   │   ├── HoverEffect.swift
│   │   │   └── KeyboardNavigation.swift
│   │   └── /Styles
│   │       ├── Colors.swift
│   │       └── Typography.swift
│   │
│   ├── /Extensions
│   │   ├── String+Extensions.swift
│   │   ├── View+Extensions.swift
│   │   └── NSPasteboard+Extensions.swift
│   │
│   └── /Utilities
│       ├── Debouncer.swift
│       ├── Logger.swift
│       └── PerformanceMonitor.swift
│
└── /Resources
    ├── Assets.xcassets
    ├── Info.plist
    └── Entitlements.plist
```

## Architectural Patterns

### MVVM-C (Model-View-ViewModel-Coordinator)

**Rationale**: MVVM-C provides clear separation of concerns while supporting SwiftUI's declarative nature and complex navigation requirements.

```swift
// View
struct SearchView: View {
    @StateObject private var viewModel: SearchViewModel
    
    var body: some View {
        VStack {
            SearchBar(text: $viewModel.searchQuery)
            
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchResults) { prompt in
                        SearchResultCard(prompt: prompt)
                            .onTapGesture {
                                viewModel.selectPrompt(prompt)
                            }
                    }
                }
            }
        }
        .onAppear {
            viewModel.startSearch()
        }
    }
}

// ViewModel
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Prompt] = []
    
    private let searchUseCase: SearchPromptsUseCase
    private let coordinator: SearchCoordinator
    private var searchTask: Task<Void, Never>?
    
    init(searchUseCase: SearchPromptsUseCase, coordinator: SearchCoordinator) {
        self.searchUseCase = searchUseCase
        self.coordinator = coordinator
        
        // Debounced search
        $searchQuery
            .debounce(for: .milliseconds(150), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    func selectPrompt(_ prompt: Prompt) {
        coordinator.didSelectPrompt(prompt)
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        
        searchTask = Task {
            do {
                let results = try await searchUseCase.execute(query: query)
                if !Task.isCancelled {
                    searchResults = results
                }
            } catch {
                // Handle error
            }
        }
    }
}

// Coordinator
final class SearchCoordinator {
    weak var parentCoordinator: AppCoordinator?
    
    func didSelectPrompt(_ prompt: Prompt) {
        // Copy to clipboard
        ClipboardManager.shared.copy(prompt.content)
        
        // Dismiss popover
        parentCoordinator?.dismissPopover()
        
        // Track usage
        Task {
            try? await DIContainer.shared.resolve(UpdatePromptUseCase.self)
                .execute(promptId: prompt.id, lastUsedAt: Date())
        }
    }
}
```

### Dependency Injection

Simple, type-safe DI without external frameworks:

```swift
final class DIContainer {
    static let shared = DIContainer()
    private var factories: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] as? () -> T else {
            fatalError("Dependency \(T.self) not registered")
        }
        return factory()
    }
    
    // App startup registration
    func registerDependencies() {
        // Data Layer
        register(SQLiteDatabase.self) {
            SQLiteDatabase(path: Constants.databasePath)
        }
        
        register(PromptRepository.self) {
            PromptRepositoryImpl(database: self.resolve(SQLiteDatabase.self))
        }
        
        // Services
        register(OllamaService.self) {
            OllamaService(baseURL: Constants.ollamaURL)
        }
        
        register(ClipboardService.self) {
            ClipboardManager()
        }
        
        // Use Cases
        register(SavePromptUseCase.self) {
            SavePromptUseCase(
                repository: self.resolve(PromptRepository.self),
                analysisService: self.resolve(OllamaService.self)
            )
        }
        
        register(SearchPromptsUseCase.self) {
            SearchPromptsUseCase(
                repository: self.resolve(PromptRepository.self),
                cache: SearchCache.shared
            )
        }
    }
}
```

### Repository Pattern

Abstraction over data access:

```swift
protocol PromptRepository {
    func save(_ prompt: Prompt) async throws
    func update(_ prompt: Prompt) async throws
    func delete(id: UUID) async throws
    func fetch(id: UUID) async throws -> Prompt?
    func fetchAll() async throws -> [Prompt]
    func search(query: String) async throws -> [Prompt]
    func fetchRecent(limit: Int) async throws -> [Prompt]
    func fetchFavorites() async throws -> [Prompt]
    func fetchByCategory(_ category: String) async throws -> [Prompt]
}

final class PromptRepositoryImpl: PromptRepository {
    private let database: SQLiteDatabase
    private let queue = DispatchQueue(label: "com.promptbar.repository", qos: .userInitiated)
    
    func search(query: String) async throws -> [Prompt] {
        let sanitizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedQuery.isEmpty else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                do {
                    let sql = """
                        SELECT p.*, snippet(prompts_fts, -1, '<mark>', '</mark>', '...', 20) as snippet
                        FROM prompts p
                        JOIN prompts_fts ON p.id = prompts_fts.id
                        WHERE prompts_fts MATCH ?
                        ORDER BY rank
                        LIMIT 50
                    """
                    
                    let results = try self?.database.query(sql, parameters: [sanitizedQuery])
                    let prompts = results?.compactMap(Prompt.init(from:)) ?? []
                    continuation.resume(returning: prompts)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

## Menu Bar Application Specifics

### NSStatusItem Management

```swift
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: EventMonitor?
    
    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.square", accessibilityDescription: "PromptBar")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient
        popover?.animates = true
        
        let hostingController = NSHostingController(rootView: MainView())
        popover?.contentViewController = hostingController
    }
    
    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                showPopover(relativeTo: button)
            }
        }
    }
    
    private func showPopover(relativeTo button: NSButton) {
        guard let popover = popover else { return }
        
        // Calculate position to ensure popover is fully visible
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
        
        var preferredEdge = NSRectEdge.minY
        
        // If too close to right edge, adjust position
        if buttonFrame.maxX > screenFrame.maxX - 400 {
            // Position will be adjusted by AppKit
        }
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: preferredEdge)
        
        // Focus search field immediately
        NotificationCenter.default.post(name: .focusSearchField, object: nil)
    }
}
```

### Global Hotkey Registration

```swift
final class HotkeyManager {
    static let shared = HotkeyManager()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    func registerHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        // Request accessibility permissions if needed
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            Logger.error("Accessibility permissions required for global hotkeys")
            return
        }
        
        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                if let nsEvent = NSEvent(cgEvent: event),
                   nsEvent.keyCode == HotkeyManager.shared.targetKeyCode,
                   nsEvent.modifierFlags.intersection(.deviceIndependentFlagsMask) == HotkeyManager.shared.targetModifiers {
                    
                    // Post notification to show popover
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .showPromptBar, object: nil)
                    }
                    
                    // Consume the event
                    return nil
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        )
        
        // Add to run loop
        if let eventTap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }
}
```

## Performance Architecture

### Search Performance Optimization

```swift
final class SearchCache {
    static let shared = SearchCache()
    private var cache: [String: (results: [Prompt], timestamp: Date)] = [:]
    private let cacheQueue = DispatchQueue(label: "com.promptbar.searchcache", attributes: .concurrent)
    private let maxCacheAge: TimeInterval = 60 // 1 minute
    
    func get(for query: String) -> [Prompt]? {
        cacheQueue.sync {
            guard let cached = cache[query],
                  Date().timeIntervalSince(cached.timestamp) < maxCacheAge else {
                return nil
            }
            return cached.results
        }
    }
    
    func set(_ results: [Prompt], for query: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache[query] = (results, Date())
            
            // Limit cache size
            if self.cache.count > 100 {
                self.pruneOldEntries()
            }
        }
    }
}
```

### SQLite FTS5 Configuration

```swift
extension SQLiteDatabase {
    func configureFTS5() throws {
        // Create FTS5 virtual table
        let createFTS = """
            CREATE VIRTUAL TABLE IF NOT EXISTS prompts_fts USING fts5(
                id UNINDEXED,
                title,
                content,
                description,
                tags,
                tokenize='porter unicode61 remove_diacritics 1',
                content='prompts',
                content_rowid='rowid'
            );
        """
        try execute(createFTS)
        
        // Create triggers to keep FTS in sync
        let insertTrigger = """
            CREATE TRIGGER IF NOT EXISTS prompts_ai AFTER INSERT ON prompts BEGIN
                INSERT INTO prompts_fts(id, title, content, description, tags)
                VALUES (new.id, new.title, new.content, new.description, new.tags);
            END;
        """
        try execute(insertTrigger)
        
        let updateTrigger = """
            CREATE TRIGGER IF NOT EXISTS prompts_au AFTER UPDATE ON prompts BEGIN
                UPDATE prompts_fts 
                SET title = new.title,
                    content = new.content,
                    description = new.description,
                    tags = new.tags
                WHERE id = new.id;
            END;
        """
        try execute(updateTrigger)
        
        // Optimize FTS index
        try execute("INSERT INTO prompts_fts(prompts_fts) VALUES('optimize');")
    }
}
```

### Background Processing

```swift
actor AnalysisQueue {
    private var pendingAnalyses: [UUID: Prompt] = [:]
    private var activeTask: Task<Void, Never>?
    private let ollamaService: OllamaService
    
    init(ollamaService: OllamaService) {
        self.ollamaService = ollamaService
    }
    
    func enqueue(_ prompt: Prompt) {
        pendingAnalyses[prompt.id] = prompt
        
        if activeTask == nil {
            activeTask = Task {
                await processPendingAnalyses()
            }
        }
    }
    
    private func processPendingAnalyses() async {
        while !pendingAnalyses.isEmpty {
            let (id, prompt) = pendingAnalyses.first!
            pendingAnalyses.removeValue(forKey: id)
            
            do {
                let analysis = try await ollamaService.analyzePrompt(prompt)
                await updatePromptWithAnalysis(prompt, analysis)
            } catch {
                Logger.error("Failed to analyze prompt \(id): \(error)")
                // Retry logic here
            }
            
            // Rate limiting
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        activeTask = nil
    }
}
```

## Ollama Integration Architecture

### Service Layer

```swift
protocol AnalysisService {
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult
    func checkAvailability() async -> Bool
}

final class OllamaService: AnalysisService {
    private let baseURL: URL
    private let session: URLSession
    private let timeout: TimeInterval = 5.0
    
    init(baseURL: URL = URL(string: "http://localhost:11434")!) {
        self.baseURL = baseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }
    
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult {
        let endpoint = baseURL.appendingPathComponent("/api/generate")
        
        let requestBody = OllamaRequest(
            model: "llama3.2:3b",
            prompt: createAnalysisPrompt(for: prompt),
            stream: false,
            options: OllamaOptions(
                temperature: 0.3,
                top_p: 0.9,
                num_predict: 200
            )
        )
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OllamaError.invalidResponse
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return try parseAnalysisResult(from: ollamaResponse.response)
    }
    
    private func createAnalysisPrompt(for prompt: Prompt) -> String {
        """
        Analyze this AI prompt and provide a JSON response with the following structure:
        {
            "description": "Brief description of what this prompt does",
            "tags": ["tag1", "tag2", "tag3"],
            "category": "One of: Development, Writing, Analysis, Design, Other",
            "use_cases": ["use case 1", "use case 2"],
            "complexity": "simple|intermediate|advanced"
        }
        
        Prompt to analyze:
        \(prompt.content)
        
        Respond with valid JSON only.
        """
    }
}
```

### Fallback Strategy

```swift
final class FallbackAnalysisService: AnalysisService {
    func analyzePrompt(_ prompt: Prompt) async throws -> AnalysisResult {
        // Simple keyword-based analysis
        let content = prompt.content.lowercased()
        
        var tags: [String] = []
        var category = "Other"
        
        // Development keywords
        if content.contains(where: { ["code", "debug", "function", "class", "api"].contains($0) }) {
            category = "Development"
            tags.append("coding")
        }
        
        // Writing keywords
        if content.contains(where: { ["write", "article", "blog", "content", "copy"].contains($0) }) {
            category = "Writing"
            tags.append("content")
        }
        
        // Extract potential tags from prompt
        let words = content.split(separator: " ").map(String.init)
        let commonTags = words.filter { word in
            Constants.commonTags.contains(word) && word.count > 3
        }.prefix(5)
        
        tags.append(contentsOf: commonTags)
        
        return AnalysisResult(
            description: "Prompt for \(category.lowercased()) tasks",
            tags: Array(Set(tags)), // Remove duplicates
            category: category,
            useCases: [],
            complexity: prompt.content.count > 500 ? "advanced" : "simple"
        )
    }
    
    func checkAvailability() async -> Bool {
        false // Always unavailable, this is the fallback
    }
}
```

## Data Flow Architecture

### Save Prompt Flow

```
1. User Input → QuickSaveView
       ↓
2. Clipboard Detection → ClipboardManager
       ↓
3. Save Action → SavePromptUseCase
       ↓
4. Persistence → PromptRepository → SQLite
       ↓                          ↓
5. Background Analysis ←─────────────┘
       ↓ (Async)
6. Ollama Service → AnalysisQueue
       ↓
7. Update Prompt → PromptRepository
       ↓
8. UI Update ← NSNotification
```

### Search Flow

```
1. Search Input → SearchBar (Debounced)
       ↓
2. SearchViewModel → SearchPromptsUseCase
       ↓
3. Cache Check → SearchCache
       ↓ (Miss)
4. FTS5 Query → PromptRepository
       ↓
5. Results → Cache Update
       ↓
6. UI Update → LazyVStack
```

## Testing Strategy

### Unit Testing

```swift
// ViewModel Testing
final class SearchViewModelTests: XCTestCase {
    func testSearchDebouncing() async throws {
        let mockUseCase = MockSearchPromptsUseCase()
        let viewModel = SearchViewModel(
            searchUseCase: mockUseCase,
            coordinator: MockSearchCoordinator()
        )
        
        // Rapid query changes
        viewModel.searchQuery = "s"
        viewModel.searchQuery = "sw"
        viewModel.searchQuery = "swift"
        
        // Wait for debounce
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Should only search once with final query
        XCTAssertEqual(mockUseCase.searchCount, 1)
        XCTAssertEqual(mockUseCase.lastQuery, "swift")
    }
}

// Repository Testing with In-Memory SQLite
final class PromptRepositoryTests: XCTestCase {
    var repository: PromptRepository!
    var database: SQLiteDatabase!
    
    override func setUp() async throws {
        database = SQLiteDatabase(inMemory: true)
        try await database.initialize()
        repository = PromptRepositoryImpl(database: database)
    }
    
    func testFTS5Search() async throws {
        // Insert test data
        let prompts = [
            Prompt(title: "Swift async", content: "Handle async await in Swift"),
            Prompt(title: "Python debug", content: "Debug Python applications"),
            Prompt(title: "Swift debug", content: "Debug Swift code with LLDB")
        ]
        
        for prompt in prompts {
            try await repository.save(prompt)
        }
        
        // Search for "swift debug"
        let results = try await repository.search(query: "swift debug")
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Swift debug")
    }
}
```

### Performance Testing

```swift
final class PerformanceTests: XCTestCase {
    func testSearchPerformance() async throws {
        let repository = createRepositoryWith10000Prompts()
        
        measure {
            let expectation = expectation(description: "Search completes")
            
            Task {
                let results = try await repository.search(query: "swift async")
                XCTAssertFalse(results.isEmpty)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 0.05) // 50ms target
        }
    }
    
    func testPopoverAppearance() {
        let menuBarController = MenuBarController()
        
        measure(metrics: [XCTClockMetric()]) {
            menuBarController.showPopover()
            
            // Verify popover is visible within 100ms
            let start = Date()
            while menuBarController.popover?.isShown != true {
                if Date().timeIntervalSince(start) > 0.1 {
                    XCTFail("Popover took too long to appear")
                    break
                }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
            }
        }
    }
}
```

## Security & Privacy Architecture

### Data Protection

```swift
extension FileManager {
    func securePromptDirectory() -> URL? {
        guard let appSupport = urls(for: .applicationSupportDirectory, 
                                   in: .userDomainMask).first else {
            return nil
        }
        
        let promptBarDir = appSupport.appendingPathComponent("PromptBar")
        
        // Create directory with restricted permissions
        do {
            try createDirectory(at: promptBarDir, 
                              withIntermediateDirectories: true,
                              attributes: [.posixPermissions: 0o700])
            
            // Exclude from backups
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try promptBarDir.setResourceValues(resourceValues)
            
            return promptBarDir
        } catch {
            Logger.error("Failed to create secure directory: \(error)")
            return nil
        }
    }
}
```

### Keychain Integration (Future)

```swift
protocol SecureStorage {
    func store(_ data: Data, for key: String) throws
    func retrieve(for key: String) throws -> Data?
    func delete(for key: String) throws
}

final class KeychainStorage: SecureStorage {
    func store(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.promptbar",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.storeFailed(status)
        }
    }
}
```

## Error Handling Strategy

### Comprehensive Error Types

```swift
enum PromptBarError: LocalizedError {
    // Storage errors
    case databaseConnectionFailed
    case migrationFailed(version: Int)
    case promptNotFound(id: UUID)
    case storageFull
    
    // Analysis errors  
    case ollamaUnavailable
    case analysisTimeout
    case invalidAnalysisResponse
    
    // System errors
    case clipboardEmpty
    case hotkeyRegistrationFailed
    case accessibilityPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .databaseConnectionFailed:
            return "Failed to connect to database"
        case .migrationFailed(let version):
            return "Database migration failed at version \(version)"
        case .promptNotFound(let id):
            return "Prompt not found: \(id)"
        case .storageFull:
            return "Storage is full. Please free up space."
        case .ollamaUnavailable:
            return "Ollama is not running"
        case .analysisTimeout:
            return "Analysis timed out"
        case .invalidAnalysisResponse:
            return "Invalid response from Ollama"
        case .clipboardEmpty:
            return "Clipboard is empty"
        case .hotkeyRegistrationFailed:
            return "Failed to register global hotkey"
        case .accessibilityPermissionDenied:
            return "Accessibility permission required for global hotkeys"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .ollamaUnavailable:
            return "Start Ollama or disable AI features in settings"
        case .accessibilityPermissionDenied:
            return "Grant permission in System Preferences > Security & Privacy"
        default:
            return nil
        }
    }
}
```

### Error Propagation

```swift
@MainActor
final class ErrorHandler: ObservableObject {
    @Published var currentError: PromptBarError?
    @Published var showError = false
    
    func handle(_ error: Error) {
        if let promptBarError = error as? PromptBarError {
            currentError = promptBarError
            showError = true
            
            // Log error
            Logger.error("\(promptBarError)")
            
            // Auto-dismiss non-critical errors
            if !promptBarError.isCritical {
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    showError = false
                }
            }
        }
    }
}
```

## Migration Strategy

### Database Migrations

```swift
struct DatabaseMigrator {
    private let migrations: [Migration] = [
        Migration(version: 1, up: createInitialSchema, down: dropAllTables),
        Migration(version: 2, up: addFavoriteColumn, down: dropFavoriteColumn),
        Migration(version: 3, up: addAnalysisColumns, down: dropAnalysisColumns)
    ]
    
    func migrate(database: SQLiteDatabase) async throws {
        let currentVersion = try await getCurrentVersion(database)
        
        for migration in migrations where migration.version > currentVersion {
            Logger.info("Running migration \(migration.version)")
            
            try await database.transaction { db in
                try migration.up(db)
                try setVersion(migration.version, in: db)
            }
        }
    }
    
    private func createInitialSchema(_ db: SQLiteDatabase) throws {
        try db.execute("""
            CREATE TABLE prompts (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                created_at REAL NOT NULL,
                modified_at REAL NOT NULL,
                used_count INTEGER DEFAULT 0,
                last_used_at REAL
            );
        """)
        
        try db.execute("""
            CREATE INDEX idx_prompts_created_at ON prompts(created_at DESC);
        """)
        
        try db.execute("""
            CREATE INDEX idx_prompts_used_count ON prompts(used_count DESC);
        """)
    }
}
```

## Performance Benchmarks

### Target Metrics

| Operation | Target | Maximum |
|-----------|--------|---------|
| App Launch to Ready | <500ms | 1000ms |
| Hotkey to Popover | <100ms | 200ms |
| Search Results (First) | <50ms | 100ms |
| Save Prompt | <200ms | 500ms |
| Copy to Clipboard | <10ms | 50ms |
| Ollama Analysis | <5s | 10s |
| Memory (Idle) | <50MB | 75MB |
| Memory (Active) | <100MB | 150MB |

### Performance Monitoring

```swift
actor PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var metrics: [String: [TimeInterval]] = [:]
    
    func measure<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            Task {
                await record(operation, duration: duration)
            }
        }
        return try await block()
    }
    
    private func record(_ operation: String, duration: TimeInterval) {
        metrics[operation, default: []].append(duration)
        
        // Alert on slow operations
        if let threshold = performanceThresholds[operation],
           duration > threshold {
            Logger.warning("Slow operation: \(operation) took \(duration)s")
        }
        
        // Periodic reporting
        if metrics[operation]?.count ?? 0 >= 100 {
            generateReport(for: operation)
        }
    }
}
```

## Deployment Architecture

### Build Configuration

```yaml
configurations:
  Debug:
    SWIFT_OPTIMIZATION_LEVEL: -Onone
    SWIFT_ACTIVE_COMPILATION_CONDITIONS: DEBUG
    MTL_ENABLE_DEBUG_INFO: YES
    
  Release:
    SWIFT_OPTIMIZATION_LEVEL: -O
    SWIFT_ACTIVE_COMPILATION_CONDITIONS: RELEASE
    ENABLE_NS_ASSERTIONS: NO
    VALIDATE_PRODUCT: YES
    
  TestFlight:
    inherit: Release
    SWIFT_ACTIVE_COMPILATION_CONDITIONS: RELEASE TESTFLIGHT
    OTHER_SWIFT_FLAGS: -DTESTFLIGHT
```

### Code Signing & Notarization

```bash
# Build script
#!/bin/bash

# Build
xcodebuild -project PromptBar.xcodeproj \
          -scheme PromptBar \
          -configuration Release \
          -archivePath ./build/PromptBar.xcarchive \
          archive

# Export
xcodebuild -exportArchive \
          -archivePath ./build/PromptBar.xcarchive \
          -exportPath ./build \
          -exportOptionsPlist ExportOptions.plist

# Notarize
xcrun notarytool submit ./build/PromptBar.app \
                       --apple-id "$APPLE_ID" \
                       --team-id "$TEAM_ID" \
                       --password "$APP_PASSWORD" \
                       --wait

# Staple
xcrun stapler staple ./build/PromptBar.app
```

## Architecture Decision Records (ADRs)

### ADR-001: Use NSPopover over NSWindow
**Status**: Accepted  
**Decision**: Use NSPopover for the dropdown interface  
**Rationale**: 
- Native menu bar behavior with auto-dismiss
- Proper positioning relative to status item
- Built-in animation support
- Handles screen edge cases automatically

### ADR-002: SQLite with FTS5 over Core Data
**Status**: Accepted  
**Decision**: Use SQLite directly with FTS5 extension  
**Rationale**:
- FTS5 provides superior full-text search performance
- More control over query optimization
- Smaller memory footprint
- Direct SQL allows complex search queries

#### SQLite Implementation Best Practices

**Parameter Binding**: Always use `SQLITE_TRANSIENT` for string parameters to ensure data integrity:

```swift
// ✅ CORRECT: Tells SQLite to make a copy of the string data
sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

// ❌ INCORRECT: Can cause data corruption if Swift deallocates string early
sqlite3_bind_text(statement, idx, value, -1, nil)
```

**Critical Bug Fixed**: Initial implementation used `nil` as destructor parameter, causing Swift strings to be deallocated before SQLite could access them during INSERT operations. This resulted in empty database saves despite successful execution reports.

**Transaction Management**: Use WAL mode for better concurrent access:
```swift
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
```

**FTS5 Optimization**: Configure appropriate tokenizers for search performance:
```sql
CREATE VIRTUAL TABLE prompts_fts USING fts5(
    title, content, description, tags,
    tokenize='porter unicode61'
);
```

### ADR-003: MVVM-C Architecture
**Status**: Accepted  
**Decision**: Use MVVM with Coordinators  
**Rationale**:
- Clear separation of concerns
- SwiftUI compatible
- Testable ViewModels
- Coordinators handle complex navigation

### ADR-004: Local Ollama over Cloud API
**Status**: Accepted  
**Decision**: Use local Ollama installation  
**Rationale**:
- Complete privacy - no data leaves device
- No API costs or rate limits
- Works offline
- User controls model selection

### ADR-005: Swift Concurrency over Combine
**Status**: Accepted  
**Decision**: Use async/await as primary concurrency model  
**Rationale**:
- Native to Swift
- Better error handling
- Easier to understand and maintain
- Structured concurrency prevents leaks

## Summary

This architecture provides a solid foundation for PromptBar that prioritizes:
- ✅ Sub-second response times through caching and optimization
- ✅ Native macOS integration for seamless UX
- ✅ Privacy-first design with local storage and processing
- ✅ Maintainable code through clear separation of concerns
- ✅ Testability at all levels
- ✅ Future extensibility without major refactoring

The modular design allows for incremental development while maintaining performance targets throughout the implementation process.

---
*Version 1.0 - Implementation Ready*