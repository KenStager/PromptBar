import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @State private var editedDescription = ""
    @State private var showDeleteConfirmation = false
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
                .background(Theme.Colors.divider)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Title and Category
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        if isEditing {
                            TextField("Title", text: $editedTitle)
                                .textFieldStyle(.plain)
                                .font(Theme.Typography.largeTitle)
                                .foregroundColor(Theme.Colors.primaryText)
                        } else {
                            Text(prompt.title)
                                .font(Theme.Typography.largeTitle)
                                .foregroundColor(Theme.Colors.primaryText)
                                .textSelection(.enabled)
                        }
                        
                        HStack(spacing: Theme.Spacing.sm) {
                            if let category = prompt.category {
                                CategoryTag(category: category)
                            }
                            
                            AnalysisIndicator(
                                status: prompt.analysisStatus.rawValue,
                                confidence: prompt.analysisConfidence ?? 0
                            )
                            
                            if prompt.isFavorite {
                                Label("Favorite", systemImage: "star.fill")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.warning)
                            }
                        }
                    }
                    
                    // Description
                    if isEditing || prompt.description != nil {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Description")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            if isEditing {
                                TextField("Add a description...", text: $editedDescription, axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.primaryText)
                                    .lineLimit(3...6)
                            } else if let description = prompt.description {
                                Text(description)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.primaryText)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Content")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        if isEditing {
                            TextEditor(text: $editedContent)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primaryText)
                                .scrollContentBackground(.hidden)
                                .background(Theme.Colors.secondaryBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .frame(minHeight: 200)
                        } else {
                            Text(prompt.content)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primaryText)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Information")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: Theme.Spacing.lg, verticalSpacing: Theme.Spacing.sm) {
                            GridRow {
                                Text("Created")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.tertiaryText)
                                
                                Text(formatDate(prompt.createdAt))
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            
                            if prompt.modifiedAt != prompt.createdAt {
                                GridRow {
                                    Text("Modified")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.tertiaryText)
                                    
                                    Text(formatDate(prompt.modifiedAt))
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                            
                            if let analysisDescription = prompt.analysisDescription {
                                GridRow {
                                    Text("AI Analysis")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.tertiaryText)
                                    
                                    Text(analysisDescription)
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .frame(width: 600, height: 500)
        .background(Theme.Colors.primaryBackground)
        .cornerRadius(Theme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.divider, lineWidth: 1)
        )
        .shadow(radius: 20)
        .onAppear {
            editedTitle = prompt.title
            editedContent = prompt.content
            editedDescription = prompt.description ?? ""
        }
        .alert("Delete Prompt", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePrompt(prompt)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this prompt? This action cannot be undone.")
        }
    }
    
    private var header: some View {
        HStack {
            Text("Prompt Details")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: Theme.Spacing.sm) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation(Theme.Animation.standard) {
                            isEditing = false
                            editedTitle = prompt.title
                            editedContent = prompt.content
                            editedDescription = prompt.description ?? ""
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Theme.Colors.tertiaryText)
                    
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                } else {
                    Button(action: {
                        viewModel.copyPrompt(prompt)
                        withAnimation(Theme.Animation.quick) {
                            isCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(Theme.Animation.quick) {
                                isCopied = false
                            }
                        }
                    }) {
                        Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button(action: {
                        withAnimation(Theme.Animation.standard) {
                            isEditing = true
                        }
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .foregroundColor(Theme.Colors.destructive)
                }
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .padding(Theme.Spacing.lg)
    }
    
    private func saveChanges() async {
        var updatedPrompt = prompt
        updatedPrompt.title = editedTitle
        updatedPrompt.content = editedContent
        updatedPrompt.description = editedDescription.isEmpty ? nil : editedDescription
        updatedPrompt.modifiedAt = Date()
        
        await viewModel.updatePrompt(updatedPrompt)
        withAnimation(Theme.Animation.standard) {
            isEditing = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
