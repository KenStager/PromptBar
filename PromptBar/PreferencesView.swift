import SwiftUI
import UniformTypeIdentifiers

struct PreferencesView: View {
    @AppStorage("launchAtStartup") var launchAtStartup = true
    @AppStorage("hotkeyEnabled") var hotkeyEnabled = true
    @AppStorage("ollamaEnabled") var ollamaEnabled = true
    @State private var ollamaStatus = "Checking..."
    @State private var isHealthChecking = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            HStack(spacing: 0) {
                TabButton(title: "General", icon: "gearshape.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "AI Analysis", icon: "brain", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "Data", icon: "externaldrive.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            
            Divider()
            
            // Tab content
            Group {
                switch selectedTab {
                case 0:
                    GeneralTab(launchAtStartup: $launchAtStartup, hotkeyEnabled: $hotkeyEnabled)
                case 1:
                    OllamaTab(
                        ollamaEnabled: $ollamaEnabled,
                        ollamaStatus: $ollamaStatus,
                        isHealthChecking: $isHealthChecking
                    )
                case 2:
                    DataTab()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
        }
        .frame(width: 550, height: 450)
        .background(Theme.Colors.background)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.secondaryText)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(isSelected ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
            .background(isSelected ? Theme.Colors.selectedBackground : Color.clear)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .buttonStyle(.plain)
    }
}

struct GeneralTab: View {
    @Binding var launchAtStartup: Bool
    @Binding var hotkeyEnabled: Bool
    @AppStorage("globalHotkey") var globalHotkey = "⌘⇧P"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Startup & Hotkeys Section
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Startup & Hotkeys")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        PreferenceToggle(
                            title: "Launch at startup",
                            subtitle: "Start PromptBar when you log in",
                            isOn: $launchAtStartup,
                            icon: "power"
                        )
                        .onChange(of: launchAtStartup) { _, newValue in
                            setLaunchAtStartup(enabled: newValue)
                        }
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.md)
                        
                        PreferenceToggle(
                            title: "Enable global hotkey",
                            subtitle: "Press \(globalHotkey) to open PromptBar from anywhere",
                            isOn: $hotkeyEnabled,
                            icon: "keyboard"
                        )
                        .onChange(of: hotkeyEnabled) { _, newValue in
                            if newValue {
                                HotkeyManager.shared.registerHotkey()
                            } else {
                                HotkeyManager.shared.unregisterHotkey()
                            }
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Information Section
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Information")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        InfoRow(label: "App Version:", value: getAppVersion())
                        Divider()
                            .padding(.horizontal, Theme.Spacing.md)
                        InfoRow(label: "Database Location:", value: getDatabaseLocation(), isPath: true)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

struct OllamaTab: View {
    @Binding var ollamaEnabled: Bool
    @Binding var ollamaStatus: String
    @Binding var isHealthChecking: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // AI Analysis Section
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("AI Analysis")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        PreferenceToggle(
                            title: "Enable AI categorization",
                            subtitle: "Automatically categorize prompts using Ollama",
                            isOn: $ollamaEnabled,
                            icon: "brain"
                        )
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.md)
                        
                        // Status Row
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                                .font(.system(size: 14))
                            
                            Text("Status:")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Text(ollamaStatus)
                                .font(Theme.Typography.body)
                                .foregroundColor(statusColor)
                            
                            Spacer()
                            
                            Button(action: checkOllamaHealth) {
                                HStack(spacing: Theme.Spacing.xs) {
                                    if isHealthChecking {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Check")
                                        .font(Theme.Typography.caption)
                                }
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(Theme.Colors.accent.opacity(0.1))
                                .foregroundColor(Theme.Colors.accent)
                                .cornerRadius(Theme.CornerRadius.small)
                            }
                            .buttonStyle(.plain)
                            .disabled(isHealthChecking)
                        }
                        .padding(Theme.Spacing.md)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Instructions Section
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("Setup Instructions")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        InstructionStep(number: 1, text: "Install Ollama from https://ollama.ai")
                        InstructionStep(number: 2, text: "Run: ollama pull llama3.2:3b")
                        InstructionStep(number: 3, text: "Keep Ollama running in the background")
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.info.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            checkOllamaHealth()
        }
    }
    
    private var statusIcon: String {
        switch ollamaStatus.lowercased() {
        case "connected", "running", "active":
            return "checkmark.circle.fill"
        case "checking...":
            return "clock.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch ollamaStatus.lowercased() {
        case "connected", "running", "active":
            return Theme.Colors.success
        case "checking...":
            return Theme.Colors.info
        default:
            return Theme.Colors.error
        }
    }
    
    private func checkOllamaHealth() {
        isHealthChecking = true
        ollamaStatus = "Checking..."
        
        Task {
            let health = await OllamaClient().checkHealth()
            await MainActor.run {
                ollamaStatus = health ? "Connected" : "Not Available"
                isHealthChecking = false
            }
        }
    }
}

struct DataTab: View {
    @State private var showImportDialog = false
    @State private var showExportDialog = false
    @State private var isImporting = false
    @State private var isExporting = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Import/Export Section
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Import & Export")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(spacing: Theme.Spacing.md) {
                        DataActionButton(
                            title: "Import Prompts",
                            subtitle: "Import prompts from a JSON file",
                            icon: "square.and.arrow.down",
                            isLoading: isImporting,
                            action: importPrompts
                        )
                        
                        Divider()
                            .padding(.horizontal, Theme.Spacing.md)
                        
                        DataActionButton(
                            title: "Export Prompts",
                            subtitle: "Export all prompts to a JSON file",
                            icon: "square.and.arrow.up",
                            isLoading: isExporting,
                            action: exportPrompts
                        )
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Storage Section
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("Storage")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    VStack(spacing: 0) {
                        Button(action: openDatabaseFolder) {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.Colors.accent)
                                
                                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                    Text("Show in Finder")
                                        .font(Theme.Typography.body)
                                        .foregroundColor(Theme.Colors.primaryText)
                                    
                                    Text("Open the database folder in Finder")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.Colors.tertiaryText)
                            }
                            .padding(Theme.Spacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Theme.Colors.hoverBackground.opacity(0.001))
                        .onHover { isHovering in
                            withAnimation(Theme.Animation.quick) {
                                // Handle hover state if needed
                            }
                        }
                    }
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .fileImporter(
            isPresented: $showImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
    }
    
    private func importPrompts() {
        showImportDialog = true
    }
    
    private func exportPrompts() {
        isExporting = true
        Task {
            do {
                let repository = try DIContainer.shared.resolve(PromptRepository.self)
                let service = ImportExportService(repository: repository)
                let data = try await service.exportPrompts()
                
                await MainActor.run {
                    isExporting = false
                    
                    // Create save panel
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.json]
                    savePanel.nameFieldStringValue = "promptbar-export-\(Date().timeIntervalSince1970).json"
                    
                    if savePanel.runModal() == .OK, let url = savePanel.url {
                        do {
                            try data.write(to: url)
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                        } catch {
                            print("Failed to save export: \(error)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    print("Export failed: \(error)")
                }
            }
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        
        isImporting = true
        Task {
            do {
                let data = try Data(contentsOf: url)
                let repository = try DIContainer.shared.resolve(PromptRepository.self)
                let service = ImportExportService(repository: repository)
                let count = try await service.importPrompts(from: data)
                await MainActor.run {
                    isImporting = false
                    print("Imported \(count) prompts")
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    print("Import failed: \(error)")
                }
            }
        }
    }
    
    private func openDatabaseFolder() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbFolder = appSupport.appendingPathComponent("PromptBar")
        NSWorkspace.shared.open(dbFolder)
    }
}

// MARK: - Helper Components

struct PreferenceToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isPath: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(label)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 120, alignment: .trailing)
            
            Text(value)
                .font(isPath ? Theme.Typography.caption : Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Text("\(number).")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 20)
            
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DataActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.accent)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Helper Functions

private func setLaunchAtStartup(enabled: Bool) {
    // Implementation for launch at startup
    print("Launch at startup: \(enabled)")
}

private func getAppVersion() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    return "\(version) (\(build))"
}

private func getDatabaseLocation() -> String {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dbPath = appSupport.appendingPathComponent("PromptBar/promptbar.db")
    return dbPath.path
}
