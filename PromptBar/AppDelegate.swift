import Cocoa
import SwiftUI
import Carbon
import AppKit
import Foundation
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var mainViewModel: MainViewModel?
    
    private func log(_ message: String) {
        // Debug logging disabled in sandboxed environment
        // To enable logging, redirect to container-accessible location
        print("PromptBar: \(message)")
    }
    
    override init() {
        super.init()
        log("AppDelegate init called")
        print("PromptBar: AppDelegate init called")
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 PromptBar: Application launched successfully!")
        print("🚀 PromptBar: Debug logging enabled - look for 🔥 messages")
        print("🚀 PromptBar: SavePromptUseCase now included in build ✅")
        
        log("Application launching...")
        print("PromptBar: Application launching...")
        
        // Enforce single instance
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!)
        log("Found \(runningApps.count) running instances")
        if runningApps.count > 1 {
            log("Another instance is already running, terminating...")
            print("PromptBar: Another instance is already running, terminating...")
            NSApp.terminate(nil)
            return
        }
        
        log("Setting up dependencies...")
        setupDependencies()
        log("Setting up menu bar...")
        setupMenuBar() 
        log("Setting up hotkey...")
        setupHotkey()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        log("Setup complete")
        print("PromptBar: Setup complete")
    }
    
    @MainActor
    private func setupMenuBar() {
        log("Setting up menu bar...")
        print("PromptBar: Setting up menu bar...")
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        log("Status item created: \(statusItem != nil)")
        
        if let button = statusItem?.button {
            // Try both system symbol and fallback text
            if let image = NSImage(systemSymbolName: "command.square", accessibilityDescription: "PromptBar") {
                button.image = image
                log("Icon set successfully with system symbol")
                print("PromptBar: Icon set successfully")
            } else {
                // Fallback to text if symbol not available
                button.title = "⌘"
                log("Using text fallback for icon")
                print("PromptBar: Using text fallback for icon")
            }
            button.action = #selector(togglePopover)
            button.target = self
        } else {
            log("ERROR - Could not get button from status item")
            print("PromptBar: ERROR - Could not get button from status item")
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient
        
        // Create main view with Phase 2 functionality
        do {
            log("Resolving repository...")
            let repository = try DIContainer.shared.resolve(PromptRepository.self)
            log("Repository resolved successfully: \(type(of: repository))")
            
            // Repository resolved successfully, proceeding with setup
            
            let savePromptUseCase = SavePromptUseCase(repository: repository)
            log("Creating MainViewModel...")
            let viewModel = MainViewModel(repository: repository, savePromptUseCase: savePromptUseCase)
            log("MainViewModel created, storing reference...")
            self.mainViewModel = viewModel
            log("Creating MainView...")
            let mainView = MainView(viewModel: viewModel)
            log("MainView created")
            
            popover?.contentViewController = NSHostingController(rootView: mainView)
            
            log("Menu bar setup complete")
            print("PromptBar: Menu bar setup complete")
        } catch {
            log("ERROR - Failed to setup main view: \(error)")
            print("PromptBar: ERROR - Failed to setup main view: \(error)")
            // Show error to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "PromptBar Initialization Failed"
                alert.informativeText = "Failed to initialize database: \(error.localizedDescription)"
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Quit")
                alert.runModal()
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    @MainActor
    @objc private func togglePopover() {
        print("PromptBar: Toggle popover called")
        
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
                print("PromptBar: Closing popover")
            } else {
                // Check clipboard content when showing popover
                mainViewModel?.checkClipboard()
                
                // Refresh recent prompts when opening
                Task {
                    await mainViewModel?.loadRecentPrompts()
                }
                
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                print("PromptBar: Showing popover")
            }
        } else {
            print("PromptBar: ERROR - No button available for popover")
        }
    }
    
    private func setupDependencies() {
        log("Setting up dependencies...")
        print("PromptBar: Setting up dependencies...")
        DIContainer.shared.registerDependencies()
        log("Dependencies registered")
    }
    
    private func setupHotkey() {
        print("PromptBar: Setting up hotkey...")
        HotkeyManager.shared.registerHotkey()
        
        // Listen for hotkey notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(togglePopover),
            name: .togglePromptBar,
            object: nil
        )
    }

}

// MARK: - Phase 2 Components

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let exportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

// MARK: - ImportExportService
struct ImportExportService {
    let repository: PromptRepository
    
    func exportPrompts() async throws -> Data {
        let prompts = try await repository.fetchAll()
        
        let export = PromptExport(
            version: "1.0",
            exportedAt: Date(),
            prompts: prompts
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(export)
    }
    
    func importPrompts(from data: Data) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let export = try decoder.decode(PromptExport.self, from: data)
        
        for prompt in export.prompts {
            // Create new prompt with new ID to avoid conflicts
            var newPrompt = prompt
            newPrompt = Prompt(
                title: prompt.title,
                content: prompt.content,
                description: prompt.description
            )
            
            try await repository.save(newPrompt)
            
            // Queue for analysis if enabled (default: true)
            let ollamaEnabled = UserDefaults.standard.object(forKey: "ollamaEnabled") as? Bool ?? true
            print("🔄 DIALOG: ollamaEnabled = \(ollamaEnabled)")
            if ollamaEnabled {
                print("🔄 DIALOG: Enqueueing prompt for analysis: \(newPrompt.title)")
                Task {
                    await AnalysisQueue.shared.enqueue(newPrompt)
                }
            }
        }
    }
}

struct PromptExport: Codable {
    let version: String
    let exportedAt: Date
    let prompts: [Prompt]
}

// MARK: - SearchCache Actor
actor SearchCache {
    private var cache: [String: CachedResult] = [:]
    private let maxAge: TimeInterval = 60 // 1 minute
    private let maxSize = 100
    
    private struct CachedResult {
        let results: [Prompt]
        let timestamp: Date
    }
    
    func get(for query: String) -> [Prompt]? {
        guard let cached = cache[query],
              Date().timeIntervalSince(cached.timestamp) < maxAge else {
            cache.removeValue(forKey: query)
            return nil
        }
        return cached.results
    }
    
    func set(_ results: [Prompt], for query: String) {
        cache[query] = CachedResult(results: results, timestamp: Date())
        if cache.count > maxSize {
            pruneOldEntries()
        }
    }
    
    func clear() {
        cache.removeAll()
    }
    
    private func pruneOldEntries() {
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(cache.count - maxSize + 10)
        for (key, _) in entriesToRemove {
            cache.removeValue(forKey: key)
        }
    }
}

// MARK: - MainViewModel
@MainActor
class MainViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Prompt] = []
    @Published var recentPrompts: [Prompt] = [] {
        didSet {
            print("🟣 MAINVIEWMODEL: recentPrompts didSet - old: \(oldValue.count), new: \(recentPrompts.count)")
            for (index, prompt) in recentPrompts.enumerated() {
                print("🟣 MAINVIEWMODEL: recentPrompts[\(index)] = '\(prompt.title)'")
            }
            DispatchQueue.main.async {
                self.objectWillChange.send()
                print("🟣 MAINVIEWMODEL: Manually sent objectWillChange")
            }
        }
    }
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var showSaveDialog = false
    @Published var showPreferences = false
    @Published var clipboardContent = ""
    @Published var saveTitle = ""
    @Published var saveDescription = ""
    @Published var selectedPrompt: Prompt?
    @Published var showPromptDetail = false
    
    let repository: PromptRepository
    private let savePromptUseCase: SavePromptUseCase
    private let searchCache = SearchCache()
    
    init(repository: PromptRepository, savePromptUseCase: SavePromptUseCase) {
        print("🔴 MAINVIEWMODEL: init() called")
        self.repository = repository
        self.savePromptUseCase = savePromptUseCase
        print("🔴 MAINVIEWMODEL: repository and savePromptUseCase stored")
        
        
        // Check clipboard synchronously on init
        checkClipboard()
        print("🔴 MAINVIEWMODEL: clipboard checked")
        
        print("🔴 MAINVIEWMODEL: Starting Task to loadRecentPrompts")
        Task {
            print("🔴 MAINVIEWMODEL: Inside Task - calling loadRecentPrompts")
            await loadRecentPrompts()
            print("🔴 MAINVIEWMODEL: loadRecentPrompts completed - recentPrompts count: \(self.recentPrompts.count)")
        }
        print("🔴 MAINVIEWMODEL: init() completed")
    }
    
    func loadRecentPrompts() async {
        print("❗️ MAINVIEWMODEL: loadRecentPrompts called")
        do {
            print("❗️ MAINVIEWMODEL: About to call repository.fetchAll()")
            let prompts = try await repository.fetchAll()
            print("❗️ MAINVIEWMODEL: repository.fetchAll() returned \(prompts.count) prompts")
            
            for (index, prompt) in prompts.enumerated() {
                print("❗️ MAINVIEWMODEL: Prompt [\(index)]: id=\(prompt.id), title='\(prompt.title)', content='\(prompt.content.prefix(50))...'")
            }
            
            // Ensure UI update happens on main actor
            await MainActor.run {
                print("❗️ MAINVIEWMODEL: Inside MainActor.run, updating recentPrompts")
                let oldCount = self.recentPrompts.count
                self.recentPrompts = Array(prompts.prefix(10))
                print("❗️ MAINVIEWMODEL: Updated recentPrompts from \(oldCount) to \(self.recentPrompts.count) items")
                
                for (index, prompt) in self.recentPrompts.enumerated() {
                    print("❗️ MAINVIEWMODEL: recentPrompts[\(index)]: title='\(prompt.title)'")
                }
                
                // Force UI update by triggering objectWillChange
                self.objectWillChange.send()
                print("❗️ MAINVIEWMODEL: Sent objectWillChange notification")
            }
        } catch {
            print("❗️ MAINVIEWMODEL: Failed to load prompts: \(error)")
            print("❗️ MAINVIEWMODEL: Error details: \(String(describing: error))")
            await MainActor.run {
                self.errorMessage = "Failed to load recent prompts: \(error.localizedDescription)"
            }
        }
    }
    
    func checkClipboard() {
        print("PromptBar: checkClipboard called")
        if ClipboardManager.shared.hasText() {
            clipboardContent = ClipboardManager.shared.getCurrentTextSafe()
            print("PromptBar: Clipboard content detected: \(clipboardContent.prefix(50))...")
        } else {
            clipboardContent = ""
            print("PromptBar: No clipboard content detected")
        }
    }
    
    func showSaveFromClipboard() {
        print("PromptBar: showSaveFromClipboard called")
        checkClipboard()
        if !clipboardContent.isEmpty {
            saveTitle = ""
            saveDescription = ""
            showSaveDialog = true
            print("PromptBar: Showing save dialog with content: \(clipboardContent.prefix(50))...")
        } else {
            print("PromptBar: No clipboard content to save")
            errorMessage = "No content in clipboard"
        }
    }
    
    func savePrompt() async {
        print("🔥 SAVE: savePrompt() called")
        print("🔥 SAVE: saveTitle = '\(saveTitle)'")
        print("🔥 SAVE: clipboardContent = '\(clipboardContent.prefix(50))...'")
        
        // Validate title
        let trimmedTitle = saveTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title is required"
            print("🔥 SAVE: Failed - empty title after trimming")
            return
        }
        
        // Validate content
        let trimmedContent = clipboardContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            errorMessage = "Content is required"
            print("🔥 SAVE: Failed - empty content after trimming")
            return
        }
        
        isLoading = true
        print("🔥 SAVE: Starting save operation...")
        print("🔥 SAVE: Trimmed title: '\(trimmedTitle)'")
        print("🔥 SAVE: Trimmed content length: \(trimmedContent.count)")
        
        do {
            print("🔥 SAVE: Calling savePromptUseCase.execute()")
            
            let savedPrompt = try await savePromptUseCase.execute(
                title: trimmedTitle,
                content: trimmedContent,
                description: saveDescription.isEmpty ? nil : saveDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            print("🔥 SAVE: Prompt saved successfully - id: \(savedPrompt.id), title: '\(savedPrompt.title)'")
            
            // Add to recent prompts immediately for instant feedback
            var updatedPrompts = [savedPrompt]
            updatedPrompts.append(contentsOf: recentPrompts)
            recentPrompts = Array(updatedPrompts.prefix(10))
            
            // Reload recent prompts from database
            await loadRecentPrompts()
            
            // Clear form and close dialog
            saveTitle = ""
            saveDescription = ""
            clipboardContent = ""
            showSaveDialog = false
            
            // Clear any error messages
            errorMessage = nil
            
        } catch {
            print("🔥 SAVE: Error occurred - \(error)")
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func performSearch() {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        Task {
            do {
                if let cached = await searchCache.get(for: query) {
                    await MainActor.run {
                        self.searchResults = cached
                        self.isSearching = false
                    }
                    return
                }
                
                let results = try await repository.search(query: query)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
                await searchCache.set(results, for: query)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func copyPrompt(_ prompt: Prompt) {
        print("🔥 COPY: copyPrompt called for prompt: \(prompt.title)")
        let markdown = ClipboardManager.formatPromptAsMarkdown(prompt)
        print("🔥 COPY: Markdown formatted, length: \(markdown.count) characters")
        print("🔥 COPY: Markdown preview:\n\(markdown)")
        ClipboardManager.shared.copy(markdown)
        print("🔥 COPY: Markdown copied to clipboard")
    }
    
    func search(query: String) {
        searchQuery = query
        performSearch()
    }
    
    func selectPrompt(_ prompt: Prompt) {
        selectedPrompt = prompt
        showPromptDetail = true
    }
    
    func updatePrompt(_ prompt: Prompt) async {
        do {
            try await repository.save(prompt)
            await loadRecentPrompts()
            
            // Update the selectedPrompt if it's the same one
            if selectedPrompt?.id == prompt.id {
                selectedPrompt = prompt
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update prompt: \(error.localizedDescription)"
            }
        }
    }
    
    func deletePrompt(_ prompt: Prompt) async {
        do {
            try await repository.delete(id: prompt.id)
            await loadRecentPrompts()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete prompt: \(error.localizedDescription)"
            }
        }
    }

}
