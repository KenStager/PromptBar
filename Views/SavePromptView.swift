import SwiftUI

struct SavePromptView: View {
    let clipboardContent: String
    @Binding var title: String
    @Binding var description: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var contentHeight: CGFloat = 150
    @FocusState private var titleFocused: Bool
    
    private var characterCount: Int {
        clipboardContent.count
    }
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .padding(.top, Theme.Spacing.md)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Title field
                    titleField
                    
                    // Description field
                    descriptionField
                    
                    // Content preview
                    contentPreview
                    
                    // AI indicator
                    aiIndicator
                }
                .padding(Theme.Spacing.xl)
            }
            
            Divider()
            
            // Footer with actions
            footerView
        }
        .frame(width: 500, minHeight: 500)
        .background(Theme.Colors.background)
        .onAppear {
            titleFocused = true
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
            
            Text("Save Prompt")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .buttonStyle(.plain)
            .help("Cancel (Esc)")
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Title Field
    private var titleField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label {
                Text("Title")
                    .font(Theme.Typography.headline)
                Text("*")
                    .foregroundColor(Theme.Colors.error)
            } icon: {
                Image(systemName: "text.cursor")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            TextField("Enter a descriptive title...", text: $title)
                .textFieldStyle(CustomTextFieldStyle())
                .focused($titleFocused)
                .onSubmit {
                    if isValid {
                        onSave()
                    }
                }
            
            if !title.isEmpty && title.count < 3 {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Title should be at least 3 characters")
                        .font(Theme.Typography.caption)
                }
                .foregroundColor(Theme.Colors.warning)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Description Field
    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label {
                Text("Description")
                    .font(Theme.Typography.headline)
                Text("(optional)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            } icon: {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            TextField("Add a brief description...", text: $description)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
    
    // MARK: - Content Preview
    private var contentPreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label {
                    Text("Content")
                        .font(Theme.Typography.headline)
                } icon: {
                    Image(systemName: "doc.text")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                Text("\(characterCount) characters")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            
            ScrollView {
                Text(clipboardContent)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
            }
            .frame(height: contentHeight)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Resize handle
            HStack {
                Spacer()
                Image(systemName: "arrow.up.and.down")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .onDrag {
                        NSItemProvider()
                    }
                    .onDrop(of: [.text], delegate: ResizeDelegate(height: $contentHeight))
            }
        }
    }
    
    // MARK: - AI Indicator
    private var aiIndicator: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.Colors.accent)
            
            Text("AI will automatically categorize this prompt")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.tertiaryText)
                .help("Ollama will analyze and categorize your prompt in the background")
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.accent.opacity(0.1))
        )
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button("Cancel", action: onCancel)
                .secondaryButton()
                .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            if title.isEmpty {
                Text("Enter a title to save")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            
            Button("Save", action: onSave)
                .primaryButton()
                .disabled(!isValid)
                .keyboardShortcut(.return, modifiers: [])
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Theme.Typography.body)
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                    .fill(Theme.Colors.secondaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .stroke(
                                isFocused ? Theme.Colors.accent : Color.secondary.opacity(0.2),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .focused($isFocused)
            .animation(Theme.Animation.quick, value: isFocused)
    }
}

// MARK: - Resize Delegate
struct ResizeDelegate: DropDelegate {
    @Binding var height: CGFloat
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        let newHeight = height + info.location.y
        height = max(100, min(400, newHeight))
        return DropProposal(operation: .move)
    }
}

// MARK: - Preview
struct SavePromptView_Previews: PreviewProvider {
    static var previews: some View {
        SavePromptView(
            clipboardContent: "This is a sample prompt content that would be saved from the clipboard.",
            title: .constant(""),
            description: .constant(""),
            onSave: {},
            onCancel: {}
        )
    }
}
