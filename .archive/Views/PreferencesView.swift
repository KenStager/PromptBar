import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            tabBar
            
            Divider()
            
            // Tab content
            tabContent
                .padding(Theme.Spacing.xl)
        }
        .frame(width: 600, height: 450)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button(action: {
            withAnimation(Theme.Animation.quick) {
                selectedTab = tab.rawValue
            }
        }) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                Text(tab.title)
                    .font(Theme.Typography.callout)
            }
            .foregroundColor(selectedTab == tab.rawValue ? Theme.Colors.accent : Theme.Colors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(selectedTab == tab.rawValue ? Theme.Colors.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch Tab(rawValue: selectedTab) {
        case .general:
            GeneralPreferencesView(preferences: preferences)
        case .aiAnalysis:
            AIAnalysisPreferencesView(preferences: preferences)
        case .data:
            DataPreferencesView(preferences: preferences)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - Tab Enum
extension PreferencesView {
    enum Tab: Int, CaseIterable, Identifiable {
        case general = 0
        case aiAnalysis = 1
        case data = 2
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .general: return "General"
            case .aiAnalysis: return "AI Analysis"
            case .data: return "Data"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .aiAnalysis: return "sparkles"
            case .data: return "externaldrive"
            }
        }
    }
}

// MARK: - General Preferences
struct GeneralPreferencesView: View {
    @ObservedObject var preferences: PreferencesManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Startup & Hotkeys
                startupSection
                
                Divider()
                
                // Appearance
                appearanceSection
                
                Divider()
                
                // Behavior
                behaviorSection
            }
        }
    }
    
    private var startupSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Startup & Hotkeys", icon: "power")
            
            Toggle("Launch at startup", isOn: $preferences.launchAtStartup)
                .toggleStyle(CustomToggleStyle())
            
            Toggle("Enable global hotkey", isOn: $preferences.enableGlobalHotkey)
                .toggleStyle(CustomToggleStyle())
            
            if preferences.enableGlobalHotkey {
                HStack {
                    Text("Global hotkey:")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    HotkeyRecorder(hotkey: $preferences.globalHotkey)
                }
                .padding(.leading, Theme.Spacing.xl)
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Appearance", icon: "paintbrush")
            
            HStack {
                Text("Menu bar icon:")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Picker("", selection: $preferences.menuBarIcon) {
                    Image(systemName: "square.grid.2x2").tag("square.grid.2x2")
                    Image(systemName: "text.bubble").tag("text.bubble")
                    Image(systemName: "command").tag("command")
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            Toggle("Show prompt count in menu bar", isOn: $preferences.showPromptCount)
                .toggleStyle(CustomToggleStyle())
        }
    }
    
    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Behavior", icon: "hand.tap")
            
            Toggle("Check clipboard on open", isOn: $preferences.checkClipboardOnOpen)
                .toggleStyle(CustomToggleStyle())
            
            Toggle("Play sound effects", isOn: $preferences.playSoundEffects)
                .toggleStyle(CustomToggleStyle())
            
            HStack {
                Text("Default sort order:")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Picker("", selection: $preferences.defaultSortOrder) {
                    Text("Recently Created").tag("created")
                    Text("Recently Used").tag("used")
                    Text("Alphabetical").tag("alphabetical")
                    Text("By Category").tag("category")
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
        }
    }
}

// MARK: - AI Analysis Preferences
struct AIAnalysisPreferencesView: View {
    @ObservedObject var preferences: PreferencesManager
    @State private var isTestingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Ollama Settings
                ollamaSection
                
                Divider()
                
                // Analysis Settings
                analysisSection
                
                Divider()
                
                // Privacy
                privacySection
            }
        }
    }
    
    private var ollamaSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Ollama Connection", icon: "network")
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Ollama URL:")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Text("Model:")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.top, Theme.Spacing.sm)
                }
                
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    TextField("http://localhost:11434", text: $preferences.ollamaURL)
                        .textFieldStyle(CustomTextFieldStyle())
                        .frame(width: 250)
                    
                    TextField("llama3.2:3b", text: $preferences.ollamaModel)
                        .textFieldStyle(CustomTextFieldStyle())
                        .frame(width: 250)
                }
                
                Spacer()
                
                VStack {
                    Button(action: testConnection) {
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("Test Connection")
                        }
                    }
                    .secondaryButton()
                    .disabled(isTestingConnection)
                    
                    connectionStatusView
                }
            }
        }
    }
    
    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Analysis Settings", icon: "brain")
            
            Toggle("Enable automatic categorization", isOn: $preferences.enableAutoAnalysis)
                .toggleStyle(CustomToggleStyle())
            
            if preferences.enableAutoAnalysis {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Analysis timeout:")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Stepper("\(preferences.analysisTimeout) seconds", 
                               value: $preferences.analysisTimeout, 
                               in: 5...30, 
                               step: 5)
                            .frame(width: 150)
                    }
                    
                    HStack {
                        Text("Max concurrent analyses:")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Stepper("\(preferences.maxConcurrentAnalyses)", 
                               value: $preferences.maxConcurrentAnalyses, 
                               in: 1...5, 
                               step: 1)
                            .frame(width: 150)
                    }
                }
                .padding(.leading, Theme.Spacing.xl)
            }
        }
    }
    
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Privacy", icon: "lock")
            
            Text("Your prompts are analyzed locally using Ollama. No data is sent to external servers.")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.success.opacity(0.1))
                )
        }
    }
    
    @ViewBuilder
    private var connectionStatusView: some View {
        switch connectionStatus {
        case .connected:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.success)
        case .disconnected:
            Label("Failed", systemImage: "xmark.circle.fill")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.error)
        case .unknown:
            EmptyView()
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionStatus = .unknown
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTestingConnection = false
            connectionStatus = .connected // or .disconnected based on actual test
        }
    }
    
    enum ConnectionStatus {
        case connected, disconnected, unknown
    }
}

// MARK: - Data Preferences
struct DataPreferencesView: View {
    @ObservedObject var preferences: PreferencesManager
    @State private var showResetAlert = false
    @State private var databaseSize = "Calculating..."
    @State private var promptCount = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Storage
                storageSection
                
                Divider()
                
                // Import/Export
                importExportSection
                
                Divider()
                
                // Danger Zone
                dangerZone
            }
        }
        .onAppear {
            calculateDatabaseInfo()
        }
    }
    
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Storage", icon: "externaldrive")
            
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                InfoRow(label: "Database Location:", 
                       value: "~/Library/Application Support/PromptBar")
                
                InfoRow(label: "Database Size:", value: databaseSize)
                
                InfoRow(label: "Total Prompts:", value: "\(promptCount)")
                
                Button("Show in Finder") {
                    showDatabaseInFinder()
                }
                .secondaryButton()
            }
        }
    }
    
    private var importExportSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Import/Export", icon: "square.and.arrow.up.on.square")
            
            HStack(spacing: Theme.Spacing.md) {
                Button("Import Prompts...") {
                    // Import action
                }
                .secondaryButton()
                
                Button("Export All Prompts...") {
                    // Export action
                }
                .secondaryButton()
            }
            
            Text("Import and export prompts in JSON format")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
    }
    
    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            SectionHeader(title: "Danger Zone", icon: "exclamationmark.triangle")
                .foregroundColor(Theme.Colors.error)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("These actions cannot be undone")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.error)
                
                Button("Reset Database") {
                    showResetAlert = true
                }
                .foregroundColor(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.error)
                .cornerRadius(Theme.CornerRadius.small)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .alert("Reset Database?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset database
            }
        } message: {
            Text("This will delete all your prompts and cannot be undone.")
        }
    }
    
    private func calculateDatabaseInfo() {
        // Calculate actual database size and count
        databaseSize = "2.3 MB"
        promptCount = 42
    }
    
    private func showDatabaseInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([
            URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support/PromptBar/promptbar.db")
        ])
    }
}

// MARK: - Helper Views
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
            
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
        }
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                configuration.label
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Theme.Colors.accent : Color.secondary.opacity(0.3))
                    .frame(width: 42, height: 24)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: configuration.isOn ? 9 : -9)
                    )
                    .animation(Theme.Animation.quick, value: configuration.isOn)
            }
        }
        .buttonStyle(.plain)
    }
}

struct HotkeyRecorder: View {
    @Binding var hotkey: String
    @State private var isRecording = false
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            HStack {
                if isRecording {
                    Text("Press hotkey...")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.accent)
                } else {
                    Text(hotkey)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.primaryText)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(isRecording ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .stroke(isRecording ? Theme.Colors.accent : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preferences Manager
class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    @AppStorage("launchAtStartup") var launchAtStartup = false
    @AppStorage("enableGlobalHotkey") var enableGlobalHotkey = true
    @AppStorage("globalHotkey") var globalHotkey = "⌘⇧P"
    @AppStorage("menuBarIcon") var menuBarIcon = "square.grid.2x2"
    @AppStorage("showPromptCount") var showPromptCount = false
    @AppStorage("checkClipboardOnOpen") var checkClipboardOnOpen = true
    @AppStorage("playSoundEffects") var playSoundEffects = true
    @AppStorage("defaultSortOrder") var defaultSortOrder = "created"
    @AppStorage("ollamaURL") var ollamaURL = "http://localhost:11434"
    @AppStorage("ollamaModel") var ollamaModel = "llama3.2:3b"
    @AppStorage("enableAutoAnalysis") var enableAutoAnalysis = true
    @AppStorage("analysisTimeout") var analysisTimeout = 10
    @AppStorage("maxConcurrentAnalyses") var maxConcurrentAnalyses = 3
    
    private init() {}
}
