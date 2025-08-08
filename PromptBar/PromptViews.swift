import SwiftUI

// MARK: - Recent Prompts View
struct RecentPromptsView: View {
    let prompts: [Prompt]
    let onCopy: (Prompt) -> Void
    let onToggleFavorite: (Prompt) -> Void
    let onSelect: (Prompt) -> Void
    
    var body: some View {
        ScrollView {
            if prompts.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(prompts) { prompt in
                        PromptCard(
                            prompt: prompt,
                            onCopy: onCopy,
                            onToggleFavorite: onToggleFavorite,
                            onSelect: onSelect
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("No prompts yet")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Save your first prompt from the clipboard")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "command")
                    Text("+")
                    Image(systemName: "shift")
                    Text("+")
                    Text("P")
                }
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.secondaryBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }
            
            Spacer()
            
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.accent)
                Text("AI will automatically categorize your prompts")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .padding(.bottom, Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let results: [Prompt]
    let query: String
    let onCopy: (Prompt) -> Void
    let onToggleFavorite: (Prompt) -> Void
    let onSelect: (Prompt) -> Void
    
    var body: some View {
        ScrollView {
            if results.isEmpty {
                noResultsView
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("\(results.count) result\(results.count == 1 ? "" : "s") for \"\(query)\"")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.md)
                    
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(results) { prompt in
                            PromptCard(
                                prompt: prompt,
                                onCopy: onCopy,
                                onToggleFavorite: onToggleFavorite,
                                onSelect: onSelect,
                                highlightText: query
                            )
                            .transition(.asymmetric(
                                insertion: .slide.combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.lg)
                }
            }
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("No results found")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Try different keywords or check your spelling")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Prompt Card
struct PromptCard: View {
    let prompt: Prompt
    let onCopy: (Prompt) -> Void
    let onToggleFavorite: (Prompt) -> Void
    var onSelect: ((Prompt) -> Void)? = nil
    var highlightText: String? = nil
    
    @State private var isHovered = false
    @State private var isCopied = false
    
    var body: some View {
        Button(action: {
            onSelect?(prompt)
        }) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(prompt.title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primaryText)
                            .lineLimit(1)
                        
                        if prompt.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.warning)
                        }
                    }
                    
                    if let category = prompt.category {
                        CategoryTag(category: category)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: Theme.Spacing.xs) {
                    AnalysisIndicator(
                        status: prompt.analysisStatus.rawValue,
                        confidence: prompt.analysisConfidence ?? 0
                    )
                    
                    Button(action: { onToggleFavorite(prompt) }) {
                        Image(systemName: prompt.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(prompt.isFavorite ? Theme.Colors.warning : Theme.Colors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .opacity(isHovered ? 1 : 0)
                    
                    Button(action: {
                        onCopy(prompt)
                        withAnimation(Theme.Animation.quick) {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(Theme.Animation.quick) {
                                isCopied = false
                            }
                        }
                    }) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(isCopied ? Theme.Colors.success : Theme.Colors.accent)
                    }
                    .buttonStyle(.plain)
                    .help(isCopied ? "Copied!" : "Copy to clipboard")
                }
            }
            
            // Description
            if let description = prompt.description {
                Text(description)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            // Content preview
            Text(prompt.content)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .lineLimit(3)
            
            // Footer
            HStack {
                Text(timeAgo(from: prompt.createdAt))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
                
                Spacer()
                
                if isCopied {
                    Text("Copied")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.success)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        }
        .buttonStyle(.plain)
        .cardStyle(isSelected: false, isHovered: isHovered)
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovered = hovering
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Category Tag
struct CategoryTag: View {
    let category: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: categoryIcon)
                .font(.system(size: 10, weight: .medium))
            Text(category)
                .font(Theme.Typography.caption)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 2)
        .background(categoryColor.opacity(0.15))
        .cornerRadius(Theme.CornerRadius.small)
    }
    
    private var categoryIcon: String {
        switch category.lowercased() {
        case "coding": return "chevron.left.forwardslash.chevron.right"
        case "writing": return "pencil"
        case "analysis": return "chart.line.uptrend.xyaxis"
        case "creative": return "paintbrush"
        case "data": return "tablecells"
        default: return "tag"
        }
    }
    
    private var categoryColor: Color {
        Theme.Colors.categoryColors[category] ?? Theme.Colors.info
    }
}

// MARK: - Analysis Indicator
struct AnalysisIndicator: View {
    let status: String
    let confidence: Double
    
    var body: some View {
        Group {
            switch status {
            case "analyzed":
                ProgressRing(progress: confidence, size: 20)
            case "pending":
                ProgressView()
                    .scaleEffect(0.7)
            case "failed":
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.error)
            default:
                EmptyView()
            }
        }
    }
}

// MARK: - Highlighted Text
extension Text {
    func highlightedText(searchText: String) -> some View {
        // This is a simplified version - in production you'd want proper text highlighting
        self
    }
}
