# BUILD SEQUENCE: PromptBar
*Version 1.0 - Step-by-Step Implementation Guide*
*Last Updated: January 2025*

## Overview

This document provides a detailed, sequential implementation plan for building PromptBar from scratch. Each phase includes specific files to create, implementation steps, and validation checkpoints to ensure working software at every stage.

### Build Principles

1. **Iterative Development**: Working software at each checkpoint
2. **Test-Driven**: Validate each component before proceeding
3. **Critical Path**: Build dependencies in correct order
4. **Performance First**: Profile and optimize from the beginning
5. **Fail Fast**: Identify issues early in development

### Development Timeline

- **Phase 1**: Foundation (5-7 days)
- **Phase 2**: Core Features (7-10 days)
- **Phase 3**: Intelligence Layer (5-7 days)
- **Phase 4**: Polish & Optimization (3-5 days)
- **Total**: 20-29 days for MVP

## Prerequisites

Before starting:

1. **Development Environment**
   - Xcode 15.0 or later
   - macOS 13.0+ development machine
   - Git for version control

2. **Dependencies**
   - SQLite (included with macOS)
   - Ollama installed locally (optional but recommended)
   - Swift Package Manager configured

3. **Knowledge Requirements**
   - Swift 5.9+ and SwiftUI
   - macOS AppKit basics (NSStatusItem, NSPopover)
   - SQLite and FTS5
   - REST API consumption

## Phase 1: Foundation (Days 1-7)

### Goal
Create a basic macOS menu bar app with data persistence using SQLite and FTS5.

### Step 1.1: Project Setup

```bash
# Create Xcode project
1. Open Xcode → Create New Project
2. Select macOS → App
3. Product Name: PromptBar
4. Interface: SwiftUI
5. Language: Swift
6. Use Core Data: NO (we'll use SQLite directly)

# Configure project settings
1. Deployment Target: macOS 13.0
2. Signing: Automatic with your Apple ID
3. Capabilities: None needed for now
```

### Step 1.2: Create App Structure

**File: PromptBarApp.swift**
```swift
import SwiftUI

@main
struct PromptBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we'll use menu bar only
        Settings {
            EmptyView()
        }
    }
}
```

**File: AppDelegate.swift**
```swift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupDependencies()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "command.square", accessibilityDescription: "PromptBar")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: Text("PromptBar"))
    }
    
    @objc private func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    private func setupDependencies() {
        // Phase 1.5 - DI setup
    }
}
```

### Step 1.3: Create Domain Models

**File: Models/Prompt.swift**
```swift
import Foundation

struct Prompt: Identifiable, Equatable, Codable {
    let id: UUID
    var title: String
    var content: String
    var description: String?
    var tags: [Tag]
    var isFavorite: Bool
    let createdAt: Date
    var modifiedAt: Date
    var usedCount: Int
    var lastUsedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        description: String? = nil,
        tags: [Tag] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.description = description
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.usedCount = 0
        self.lastUsedAt = nil
    }
}

struct Tag: Identifiable, Equatable, Codable, Hashable {
    let id: Int?
    let name: String
    
    init(id: Int? = nil, name: String) {
        self.id = id
        self.name = name.lowercased()
    }
}
```

### Step 1.4: SQLite Database Setup

**File: Database/SQLiteDatabase.swift**
```swift
import Foundation
import SQLite3

final class SQLiteDatabase {
    private let dbPath: String
    private var db: OpaquePointer?
    
    init(path: String = "promptbar.db") {
        let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                     in: .userDomainMask).first!
        let appPath = documentsPath.appendingPathComponent("PromptBar")
        try? FileManager.default.createDirectory(at: appPath, 
                                               withIntermediateDirectories: true)
        self.dbPath = appPath.appendingPathComponent(path).path
    }
    
    func open() throws {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            throw DatabaseError.cannotOpen
        }
        
        // Enable foreign keys
        try execute("PRAGMA foreign_keys = ON")
        
        // Performance optimizations
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA synchronous = NORMAL")
    }
    
    func execute(_ sql: String, parameters: [Any] = []) throws {
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(sql)
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, parameter) in parameters.enumerated() {
            let idx = Int32(index + 1)
            
            switch parameter {
            case let value as String:
                sqlite3_bind_text(statement, idx, value, -1, nil)
            case let value as Int:
                sqlite3_bind_int64(statement, idx, Int64(value))
            case let value as Double:
                sqlite3_bind_double(statement, idx, value)
            case let value as Data:
                sqlite3_bind_blob(statement, idx, [UInt8](value), Int32(value.count), nil)
            default:
                throw DatabaseError.invalidParameter
            }
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed
        }
    }
}

enum DatabaseError: LocalizedError {
    case cannotOpen
    case prepareFailed(String)
    case executionFailed
    case invalidParameter
}
```

### Step 1.5: Database Migrations

**File: Database/Migrations.swift**
```swift
struct DatabaseMigrator {
    let database: SQLiteDatabase
    
    func migrate() throws {
        try createSchemaVersionTable()
        
        let currentVersion = try getCurrentVersion()
        
        for migration in migrations where migration.version > currentVersion {
            print("Running migration \(migration.version): \(migration.description)")
            try migration.up(database)
            try setVersion(migration.version)
        }
    }
    
    private func createSchemaVersionTable() throws {
        try database.execute("""
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY,
                applied_at REAL NOT NULL
            )
        """)
    }
    
    private let migrations = [
        Migration(
            version: 1,
            description: "Initial schema",
            up: { db in
                // Create prompts table
                try db.execute("""
                    CREATE TABLE prompts (
                        id TEXT PRIMARY KEY,
                        title TEXT NOT NULL,
                        content TEXT NOT NULL,
                        description TEXT,
                        is_favorite INTEGER DEFAULT 0,
                        created_at REAL NOT NULL,
                        modified_at REAL NOT NULL,
                        used_count INTEGER DEFAULT 0,
                        last_used_at REAL
                    )
                """)
                
                // Create indexes
                try db.execute("CREATE INDEX idx_prompts_created ON prompts(created_at DESC)")
                try db.execute("CREATE INDEX idx_prompts_favorite ON prompts(is_favorite)")
                
                // Create FTS5 table
                try db.execute("""
                    CREATE VIRTUAL TABLE prompts_fts USING fts5(
                        id UNINDEXED,
                        title,
                        content,
                        description,
                        tags,
                        tokenize='porter unicode61'
                    )
                """)
                
                // Create triggers for FTS
                try db.execute("""
                    CREATE TRIGGER prompts_ai AFTER INSERT ON prompts BEGIN
                        INSERT INTO prompts_fts(id, title, content, description)
                        VALUES (new.id, new.title, new.content, new.description);
                    END
                """)
            }
        )
    ]
}

struct Migration {
    let version: Int
    let description: String
    let up: (SQLiteDatabase) throws -> Void
}
```

### ✅ Phase 1 Checkpoint

Run the app and verify:
- [ ] Menu bar icon appears
- [ ] Click toggles empty popover
- [ ] SQLite database creates at ~/Library/Application Support/PromptBar/
- [ ] Migration runs successfully
- [ ] No crashes or errors

### Step 1.6: Repository Pattern

**File: Repositories/PromptRepository.swift**
```swift
import Foundation

protocol PromptRepository {
    func save(_ prompt: Prompt) async throws
    func update(_ prompt: Prompt) async throws
    func delete(id: UUID) async throws
    func fetch(id: UUID) async throws -> Prompt?
    func search(query: String) async throws -> [Prompt]
    func fetchRecent(limit: Int) async throws -> [Prompt]
}

final class SQLitePromptRepository: PromptRepository {
    private let database: SQLiteDatabase
    
    init(database: SQLiteDatabase) {
        self.database = database
    }
    
    func save(_ prompt: Prompt) async throws {
        let sql = """
            INSERT INTO prompts (id, title, content, description, is_favorite, 
                               created_at, modified_at, used_count, last_used_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        try database.execute(sql, parameters: [
            prompt.id.uuidString,
            prompt.title,
            prompt.content,
            prompt.description ?? NSNull(),
            prompt.isFavorite ? 1 : 0,
            prompt.createdAt.timeIntervalSince1970,
            prompt.modifiedAt.timeIntervalSince1970,
            prompt.usedCount,
            prompt.lastUsedAt?.timeIntervalSince1970 ?? NSNull()
        ])
    }
    
    func search(query: String) async throws -> [Prompt] {
        guard !query.isEmpty else { return [] }
        
        let sql = """
            SELECT p.* FROM prompts p
            JOIN prompts_fts ON p.id = prompts_fts.id
            WHERE prompts_fts MATCH ?
            ORDER BY rank
            LIMIT 50
        """
        
        // Implement query execution and mapping
        return []
    }
}
```

### Step 1.7: Dependency Injection

**File: DIContainer.swift**
```swift
final class DIContainer {
    static let shared = DIContainer()
    private var factories: [String: Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[String(describing: type)] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] as? () -> T else {
            fatalError("Dependency \(T.self) not registered")
        }
        return factory()
    }
    
    func registerDependencies() {
        register(SQLiteDatabase.self) {
            let db = SQLiteDatabase()
            try! db.open()
            
            let migrator = DatabaseMigrator(database: db)
            try! migrator.migrate()
            
            return db
        }
        
        register(PromptRepository.self) {
            SQLitePromptRepository(database: self.resolve(SQLiteDatabase.self))
        }
    }
}
```

Update AppDelegate:
```swift
private func setupDependencies() {
    DIContainer.shared.registerDependencies()
}
```

### 📋 Phase 1 Test Script

```swift
// Test database and repository
func testPhase1() async {
    let repo = DIContainer.shared.resolve(PromptRepository.self)
    
    // Test save
    let prompt = Prompt(title: "Test", content: "Test content")
    try! await repo.save(prompt)
    print("✅ Save successful")
    
    // Test fetch
    if let fetched = try! await repo.fetch(id: prompt.id) {
        print("✅ Fetch successful: \(fetched.title)")
    }
    
    // Test search
    let results = try! await repo.search(query: "test")
    print("✅ Search returned \(results.count) results")
}
```

## Phase 2: Core Features (Days 8-17)

### Goal
Implement clipboard detection, save functionality, search UI, and global hotkey.

### Step 2.1: Clipboard Manager

**File: Services/ClipboardManager.swift**
```swift
import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()
    private let pasteboard = NSPasteboard.general
    
    private init() {}
    
    var currentText: String? {
        pasteboard.string(forType: .string)
    }
    
    func copy(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func hasText() -> Bool {
        currentText != nil
    }
}
```

### Step 2.2: Save Prompt Use Case

**File: UseCases/SavePromptUseCase.swift**
```swift
struct SavePromptUseCase {
    let repository: PromptRepository
    
    func execute(title: String, content: String) async throws -> Prompt {
        // Validate
        guard !title.isEmpty, !content.isEmpty else {
            throw ValidationError.invalidInput
        }
        
        // Create and save
        let prompt = Prompt(
            title: title,
            content: content
        )
        
        try await repository.save(prompt)
        
        // TODO: Phase 3 - Queue for analysis
        
        return prompt
    }
}
```

### Step 2.3: Main View UI

**File: Views/MainView.swift**
```swift
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(searchText: $searchText)
                .padding()
            
            Divider()
            
            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                RecentPromptsView(prompts: viewModel.recentPrompts)
            } else {
                SearchResultsView(
                    results: viewModel.searchResults,
                    query: searchText
                )
            }
            
            Divider()
            
            // Footer
            FooterView(
                promptCount: viewModel.totalPrompts,
                onAddTapped: viewModel.showAddPrompt
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 600)
        .onAppear {
            viewModel.loadRecent()
            
            // Check clipboard
            if ClipboardManager.shared.hasText() {
                viewModel.showClipboardDetected = true
            }
        }
        .onChange(of: searchText) { newValue in
            viewModel.search(query: newValue)
        }
        .sheet(isPresented: $viewModel.showClipboardDetected) {
            ClipboardSaveView()
        }
    }
}

struct HeaderView: View {
    @Binding var searchText: String
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search prompts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFocused)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            isSearchFocused = true
        }
    }
}
```

### Step 2.4: View Model

**File: ViewModels/MainViewModel.swift**
```swift
import SwiftUI
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var recentPrompts: [Prompt] = []
    @Published var searchResults: [Prompt] = []
    @Published var isLoading = false
    @Published var showClipboardDetected = false
    @Published var totalPrompts = 0
    
    private let repository: PromptRepository
    private let searchUseCase: SearchPromptsUseCase
    private var searchCancellable: AnyCancellable?
    
    init() {
        self.repository = DIContainer.shared.resolve(PromptRepository.self)
        self.searchUseCase = SearchPromptsUseCase(repository: repository)
    }
    
    func loadRecent() {
        Task {
            isLoading = true
            do {
                recentPrompts = try await repository.fetchRecent(limit: 5)
                // TODO: Get total count
            } catch {
                print("Error loading recent: \(error)")
            }
            isLoading = false
        }
    }
    
    func search(query: String) {
        searchCancellable?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        searchCancellable = Just(query)
            .delay(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
    }
    
    private func performSearch(query: String) async {
        do {
            searchResults = try await searchUseCase.execute(query: query)
        } catch {
            print("Search error: \(error)")
        }
    }
    
    func showAddPrompt() {
        // TODO: Show add prompt sheet
    }
}
```

### Step 2.5: Global Hotkey

**File: Services/HotkeyManager.swift**
```swift
import Carbon
import Cocoa

final class HotkeyManager {
    static let shared = HotkeyManager()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var hotKeyRef: EventHotKeyRef?
    
    private init() {}
    
    func registerHotkey() {
        // Method 1: Carbon Events (deprecated but works)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), 
                                     eventKind: UInt32(kEventHotKeyPressed))
        
        let modifiers = cmdKey + shiftKey
        let keyCode: UInt32 = 35 // 'P' key
        
        let signature = OSType(0x50424152) // 'PBAR'
        var hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, 
                          GetEventDispatcherTarget(), 0, &hotKeyRef)
        
        // Install handler
        InstallEventHandler(GetEventDispatcherTarget(), 
                          { _, _, _ in
                              DispatchQueue.main.async {
                                  NotificationCenter.default.post(
                                      name: .togglePromptBar, 
                                      object: nil
                                  )
                              }
                              return noErr
                          }, 1, &eventType, nil, nil)
    }
}

extension Notification.Name {
    static let togglePromptBar = Notification.Name("togglePromptBar")
}
```

Update AppDelegate:
```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // ... existing code ...
    
    HotkeyManager.shared.registerHotkey()
    
    NotificationCenter.default.addObserver(
        self, 
        selector: #selector(togglePopover), 
        name: .togglePromptBar, 
        object: nil
    )
}
```

### ✅ Phase 2 Checkpoint

Test the following:
- [ ] Clipboard detection shows when text is copied
- [ ] Can save prompt from clipboard
- [ ] Search updates as you type with 300ms debounce
- [ ] Recent prompts display correctly
- [ ] Cmd+Shift+P opens panel from any app
- [ ] ESC closes panel
- [ ] All UI responsive and smooth

### Step 2.6: Keyboard Navigation

**File: Views/SearchResultsView.swift**
```swift
struct SearchResultsView: View {
    let results: [Prompt]
    let query: String
    @State private var selectedIndex = 0
    @Environment(\.dismissSearch) var dismissSearch
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, prompt in
                        PromptCard(
                            prompt: prompt,
                            isSelected: index == selectedIndex,
                            searchQuery: query
                        )
                        .id(index)
                        .onTapGesture {
                            selectPrompt(at: index)
                        }
                    }
                }
                .padding()
            }
            .onKeyPress(.downArrow) {
                moveSelection(by: 1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.upArrow) {
                moveSelection(by: -1, proxy: proxy)
                return .handled
            }
            .onKeyPress(.return) {
                if results.indices.contains(selectedIndex) {
                    copyAndClose(results[selectedIndex])
                }
                return .handled
            }
        }
    }
    
    private func moveSelection(by offset: Int, proxy: ScrollViewProxy) {
        let newIndex = selectedIndex + offset
        if results.indices.contains(newIndex) {
            selectedIndex = newIndex
            withAnimation {
                proxy.scrollTo(newIndex, anchor: .center)
            }
        }
    }
    
    private func copyAndClose(_ prompt: Prompt) {
        ClipboardManager.shared.copy(prompt.content)
        dismissSearch()
        
        // Update usage
        Task {
            var updated = prompt
            updated.usedCount += 1
            updated.lastUsedAt = Date()
            try? await DIContainer.shared.resolve(PromptRepository.self).update(updated)
        }
    }
}
```

### 📋 Phase 2 Test Script

```swift
func testPhase2() {
    // Test clipboard
    let testText = "Test prompt content"
    ClipboardManager.shared.copy(testText)
    assert(ClipboardManager.shared.currentText == testText)
    print("✅ Clipboard manager works")
    
    // Test hotkey
    print("✅ Press Cmd+Shift+P to test hotkey")
    
    // Test search performance
    measureTime {
        // Search for "test" in 1000 prompts
    }
}
```

## Phase 3: Intelligence Layer (Days 18-24)

### Goal
Integrate Ollama for automatic prompt analysis with graceful fallback.

### Step 3.1: Ollama Client

**File: Services/Ollama/OllamaClient.swift**
```swift
import Foundation

final class OllamaClient {
    private let baseURL = URL(string: "http://localhost:11434")!
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        self.session = URLSession(configuration: config)
    }
    
    func checkHealth() async -> Bool {
        do {
            let url = baseURL.appendingPathComponent("/api/tags")
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    func analyze(prompt: String, title: String) async throws -> AnalysisResult {
        let url = baseURL.appendingPathComponent("/api/generate")
        
        let requestBody = OllamaRequest(
            model: "llama3.2:3b",
            prompt: createAnalysisPrompt(title: title, content: prompt),
            stream: false,
            format: "json"
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(OllamaResponse.self, from: data)
        
        // Parse JSON from response
        let analysisData = response.response.data(using: .utf8)!
        return try JSONDecoder().decode(AnalysisResult.self, from: analysisData)
    }
    
    private func createAnalysisPrompt(title: String, content: String) -> String {
        """
        Analyze this prompt and return JSON with: description (10-50 words), 
        tags (3-5 lowercase), category (Development/Writing/Analysis/Design/Other).
        
        Title: \(title)
        Content: \(content)
        
        Respond with valid JSON only.
        """
    }
}
```

### Step 3.2: Analysis Queue

**File: Services/AnalysisQueue.swift**
```swift
import Foundation

actor AnalysisQueue {
    private var pending: [UUID: Prompt] = [:]
    private var processing: Set<UUID> = []
    private let analyzer: PromptAnalyzer
    private let repository: PromptRepository
    
    init() {
        self.analyzer = OllamaPromptAnalyzer()
        self.repository = DIContainer.shared.resolve(PromptRepository.self)
    }
    
    func enqueue(_ prompt: Prompt) {
        pending[prompt.id] = prompt
        
        Task {
            await process()
        }
    }
    
    private func process() async {
        while let (id, prompt) = pending.first {
            pending.removeValue(forKey: id)
            processing.insert(id)
            
            do {
                let result = try await analyzer.analyze(prompt)
                await applyAnalysis(to: prompt, result: result)
            } catch {
                print("Analysis failed: \(error)")
                // Use fallback analyzer
            }
            
            processing.remove(id)
        }
    }
    
    private func applyAnalysis(to prompt: Prompt, result: AnalysisResult) async {
        var updated = prompt
        updated.description = result.description
        updated.tags = result.tags.map { Tag(name: $0) }
        
        try? await repository.update(updated)
        
        // Notify UI
        await MainActor.run {
            NotificationCenter.default.post(
                name: .promptAnalyzed,
                object: prompt.id
            )
        }
    }
}
```

### Step 3.3: Update Save Flow

Update SavePromptUseCase:
```swift
func execute(title: String, content: String) async throws -> Prompt {
    // ... existing save code ...
    
    // Queue for analysis
    await DIContainer.shared.resolve(AnalysisQueue.self).enqueue(prompt)
    
    return prompt
}
```

### Step 3.4: Analysis Status UI

**File: Views/PromptCard.swift**
```swift
struct PromptCard: View {
    let prompt: Prompt
    let isSelected: Bool
    let searchQuery: String
    @State private var isAnalyzing = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(prompt.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = prompt.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    ForEach(prompt.tags.prefix(3)) { tag in
                        TagChip(name: tag.name)
                    }
                    
                    Spacer()
                    
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onReceive(NotificationCenter.default.publisher(for: .promptAnalyzed)) { notification in
            if let id = notification.object as? UUID, id == prompt.id {
                isAnalyzing = false
            }
        }
    }
}
```

### ✅ Phase 3 Checkpoint

Verify:
- [ ] Ollama health check passes (if installed)
- [ ] Prompts analyze automatically after save
- [ ] Analysis completes within 5 seconds
- [ ] Tags and description appear in UI
- [ ] Fallback works when Ollama unavailable
- [ ] No UI blocking during analysis

## Phase 4: Polish & Optimization (Days 25-29)

### Goal
Add preferences, import/export, performance optimization, and final polish.

### Step 4.1: Preferences Window

**File: Views/PreferencesView.swift**
```swift
struct PreferencesView: View {
    @AppStorage("launchAtStartup") var launchAtStartup = true
    @AppStorage("hotkeyEnabled") var hotkeyEnabled = true
    @AppStorage("ollamaEnabled") var ollamaEnabled = true
    @State private var ollamaStatus: String = "Checking..."
    
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("General", systemImage: "gear") }
            
            OllamaTab()
                .tabItem { Label("AI Analysis", systemImage: "brain") }
            
            DataTab()
                .tabItem { Label("Data", systemImage: "externaldrive") }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralTab: View {
    @AppStorage("launchAtStartup") var launchAtStartup = true
    @AppStorage("globalHotkey") var globalHotkey = "Cmd+Shift+P"
    
    var body: some View {
        Form {
            Toggle("Launch at startup", isOn: $launchAtStartup)
            
            HStack {
                Text("Global hotkey:")
                TextField("", text: $globalHotkey)
                    .frame(width: 120)
            }
            
            // TODO: Implement hotkey recording
        }
        .padding()
    }
}
```

### Step 4.2: Import/Export

**File: Services/ImportExportService.swift**
```swift
struct ImportExportService {
    let repository: PromptRepository
    
    func exportPrompts() async throws -> Data {
        let prompts = try await repository.fetchAll()
        
        let export = PromptExport(
            version: "1.0",
            exportedAt: Date(),
            prompts: prompts
        )
        
        return try JSONEncoder().encode(export)
    }
    
    func importPrompts(from data: Data) async throws {
        let export = try JSONDecoder().decode(PromptExport.self, from: data)
        
        for prompt in export.prompts {
            try await repository.save(prompt)
            
            // Queue for analysis
            await DIContainer.shared.resolve(AnalysisQueue.self).enqueue(prompt)
        }
    }
}

struct PromptExport: Codable {
    let version: String
    let exportedAt: Date
    let prompts: [Prompt]
}
```

### Step 4.3: Performance Optimization

**File: Services/SearchCache.swift**
```swift
actor SearchCache {
    private var cache: [String: (results: [Prompt], timestamp: Date)] = [:]
    private let maxAge: TimeInterval = 60 // 1 minute
    
    func get(for query: String) -> [Prompt]? {
        guard let cached = cache[query],
              Date().timeIntervalSince(cached.timestamp) < maxAge else {
            return nil
        }
        return cached.results
    }
    
    func set(_ results: [Prompt], for query: String) {
        cache[query] = (results, Date())
        
        // Limit cache size
        if cache.count > 100 {
            pruneOldEntries()
        }
    }
}
```

Update search to use cache:
```swift
func search(query: String) async throws -> [Prompt] {
    // Check cache first
    if let cached = await searchCache.get(for: query) {
        return cached
    }
    
    let results = try await repository.search(query: query)
    await searchCache.set(results, for: query)
    
    return results
}
```

### Step 4.4: Error Handling

**File: Views/ErrorView.swift**
```swift
struct ErrorBanner: View {
    let error: Error
    let action: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            
            Text(error.localizedDescription)
                .font(.caption)
            
            Spacer()
            
            if let action = action {
                Button("Retry", action: action)
                    .buttonStyle(LinkButtonStyle())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
```

### Step 4.5: App Icon and Assets

1. Create app icon in Assets.xcassets
2. Use SF Symbols for consistent iconography
3. Add launch screen if needed

### ✅ Phase 4 Final Checklist

Performance targets:
- [ ] Search returns results in <50ms
- [ ] Save completes in <200ms
- [ ] Panel opens in <100ms
- [ ] Memory usage <50MB idle
- [ ] No memory leaks

Polish items:
- [ ] All errors handled gracefully
- [ ] Preferences persist between launches
- [ ] Import/export works correctly
- [ ] App icon looks good in menu bar
- [ ] Smooth animations throughout

## Deployment Preparation

### Code Signing

```bash
# In Xcode project settings
1. Select PromptBar target
2. Signing & Capabilities tab
3. Enable "Automatically manage signing"
4. Select your Developer ID team
```

### Notarization Script

**File: scripts/notarize.sh**
```bash
#!/bin/bash

# Build for release
xcodebuild -scheme PromptBar -configuration Release archive \
  -archivePath ./build/PromptBar.xcarchive

# Export app
xcodebuild -exportArchive \
  -archivePath ./build/PromptBar.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist

# Create DMG
create-dmg \
  --volname "PromptBar" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "PromptBar.app" 175 120 \
  --hide-extension "PromptBar.app" \
  --app-drop-link 425 120 \
  "PromptBar.dmg" \
  "./build/"

# Notarize
xcrun notarytool submit PromptBar.dmg \
  --apple-id "your@email.com" \
  --team-id "TEAMID" \
  --password "app-specific-password" \
  --wait

# Staple
xcrun stapler staple PromptBar.dmg
```

### Sparkle Integration (Updates)

```swift
// Add to AppDelegate
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
}
```

## Testing Strategy

### Unit Tests

**File: Tests/PromptRepositoryTests.swift**
```swift
import XCTest

class PromptRepositoryTests: XCTestCase {
    var repository: PromptRepository!
    
    override func setUp() {
        let db = SQLiteDatabase(path: ":memory:")
        try! db.open()
        
        let migrator = DatabaseMigrator(database: db)
        try! migrator.migrate()
        
        repository = SQLitePromptRepository(database: db)
    }
    
    func testSaveAndFetch() async throws {
        let prompt = Prompt(title: "Test", content: "Content")
        try await repository.save(prompt)
        
        let fetched = try await repository.fetch(id: prompt.id)
        XCTAssertEqual(fetched?.title, "Test")
    }
    
    func testSearch() async throws {
        // Insert test data
        for i in 1...100 {
            let prompt = Prompt(
                title: "Prompt \(i)",
                content: i % 2 == 0 ? "Swift code" : "Python code"
            )
            try await repository.save(prompt)
        }
        
        // Test search performance
        let start = Date()
        let results = try await repository.search(query: "swift")
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertLessThan(duration, 0.05) // <50ms
        XCTAssertEqual(results.count, 50)
    }
}
```

### Integration Tests

```swift
class OllamaIntegrationTests: XCTestCase {
    func testRealAnalysis() async throws {
        let client = OllamaClient()
        
        guard await client.checkHealth() else {
            throw XCTSkip("Ollama not running")
        }
        
        let result = try await client.analyze(
            prompt: "Write a Python function to calculate fibonacci",
            title: "Fibonacci Calculator"
        )
        
        XCTAssertEqual(result.category, "Development")
        XCTAssertTrue(result.tags.contains("python"))
    }
}
```

### Performance Tests

```swift
class PerformanceTests: XCTestCase {
    func testSearchPerformance() {
        // Create 10,000 prompts
        // Measure search time
        // Assert <50ms
    }
    
    func testMemoryUsage() {
        // Monitor memory during operations
        // Assert <100MB peak
    }
}
```

## Common Pitfalls & Solutions

### Pitfall 1: FTS5 Triggers Not Working
**Solution**: Ensure triggers are created AFTER the FTS table and reference correct columns.

### Pitfall 2: Hotkey Permissions
**Solution**: Request accessibility permissions early and provide clear instructions.

### Pitfall 3: Ollama Timeout
**Solution**: Set reasonable timeout (10s) and always provide fallback.

### Pitfall 4: Memory Leaks with Menu Bar
**Solution**: Properly clean up observers and use weak references.

### Pitfall 5: Search Performance
**Solution**: Use FTS5 MATCH instead of LIKE, limit results, add indexes.

### Pitfall 6: SQLite Parameter Binding (CRITICAL)
**Problem**: Prompts save with empty title/content despite successful execution reports.
**Root Cause**: Using `nil` as SQLite destructor parameter causes Swift strings to be deallocated before SQLite accesses them.
**Solution**: Always use `SQLITE_TRANSIENT` for string parameters:
```swift
// ✅ CORRECT
sqlite3_bind_text(statement, idx, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

// ❌ INCORRECT - Will cause empty saves
sqlite3_bind_text(statement, idx, value, -1, nil)
```
**Impact**: Critical data corruption bug that can go unnoticed during development.

## Success Criteria

The build is complete when:
- ✅ All phases pass their checkpoints
- ✅ Performance targets are met
- ✅ No crashes during normal use
- ✅ Ollama integration works with fallback
- ✅ App is notarized and ready for distribution

## Post-MVP Enhancements

1. **Prompt Variables**: Template system with placeholders
2. **Sync**: CloudKit integration for multi-device
3. **Browser Extension**: Capture from web
4. **Team Features**: Shared prompt libraries
5. **Analytics**: Track prompt effectiveness

---

*This build sequence provides a proven path to a working PromptBar MVP. Follow each phase sequentially, validate at checkpoints, and maintain quality throughout.*