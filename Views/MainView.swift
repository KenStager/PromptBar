import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            // Background with subtle material effect
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with app title and actions
                headerView
                
                // Search bar
                searchBarView
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                
                // Content area
                contentView
            }
        }
        .frame(width: 420, height: 600)
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { newValue in
            withAnimation(Theme.Animation.quick) {
                isSearching = !newValue.isEmpty
            }
            viewModel.search(query: newValue)
        }
        .sheet(isPresented: $viewModel.showSaveDialog) {
            SavePromptView(
                clipboardContent: viewModel.clipboardContent,
                title: $viewModel.saveTitle,
                description: $viewModel.saveDescription,
                onSave: {
                    Task {
                        await viewModel.savePrompt()
                    }
                },
                onCancel: {
                    viewModel.showSaveDialog = false
                }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
            
            Text("PromptBar")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            if !viewModel.clipboardContent.isEmpty {
                Button(action: {
                    withAnimation(Theme.Animation.spring) {
                        viewModel.showSaveFromClipboard()
                    }
                }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "doc.on.clipboard.fill")
                        Text("Save")
                            .font(Theme.Typography.caption)
                    }
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .foregroundColor(Theme.Colors.accent)
                    .cornerRadius(Theme.CornerRadius.small)
                }
                .buttonStyle(.plain)
                .help("Save content from clipboard")
            }
            
            Button(action: {
                // Open preferences
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .help("Preferences")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.sm)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField("Search prompts...", text: $searchText)
                .textFieldStyle(.plain)
                .font(Theme.Typography.body)
                .focused($isSearchFocused)
                .onSubmit {
                    viewModel.search(query: searchText)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(Theme.Animation.quick) {
                        searchText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
            
            if isSearching && viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.7)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.secondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(isSearchFocused ? Theme.Colors.accent.opacity(0.5) : Color.clear, lineWidth: 2)
                )
        )
        .animation(Theme.Animation.quick, value: isSearchFocused)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if searchText.isEmpty {
                RecentPromptsView(
                    prompts: viewModel.recentPrompts,
                    onCopy: viewModel.copyPrompt,
                    onToggleFavorite: viewModel.toggleFavorite
                )
            } else {
                SearchResultsView(
                    results: viewModel.searchResults,
                    query: searchText,
                    onCopy: viewModel.copyPrompt,
                    onToggleFavorite: viewModel.toggleFavorite
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .controlSize(.large)
            Text("Loading prompts...")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.warning)
            
            Text("Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(message)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
            
            Button("Try Again") {
                viewModel.clearError()
                Task {
                    await viewModel.loadRecentPrompts()
                }
            }
            .primaryButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Main View Model Extension
extension MainViewModel {
    func toggleFavorite(_ prompt: Prompt) {
        Task {
            do {
                var updatedPrompt = prompt
                updatedPrompt.isFavorite.toggle()
                try await repository.update(updatedPrompt)
                await loadRecentPrompts()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update favorite status"
                }
            }
        }
    }
}
