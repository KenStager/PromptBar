import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()
    private let pasteboard = NSPasteboard.general
    
    private init() {}
    
    var currentText: String? {
        pasteboard.string(forType: .string)
    }
    
    func copy(_ text: String) {
        print("🔥 CLIPBOARD: copy() called with text length: \(text.count)")
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        print("🔥 CLIPBOARD: setString result: \(success)")
        if let copiedText = pasteboard.string(forType: .string) {
            print("🔥 CLIPBOARD: Verified clipboard now contains: \(copiedText.prefix(100))...")
        } else {
            print("🔥 CLIPBOARD: ERROR - Could not verify clipboard contents")
        }
    }
    
    func hasText() -> Bool {
        currentText != nil && !(currentText?.isEmpty ?? true)
    }
    
    func getCurrentTextSafe() -> String {
        return currentText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    // Format a prompt as Markdown for copying
    static func formatPromptAsMarkdown(_ prompt: Prompt) -> String {
        var markdown = "# \(prompt.title)\n\n"
        
        // Add description if present
        if let description = prompt.description, !description.isEmpty {
            markdown += "*\(description)*\n\n"
        }
        
        // Add the main content
        markdown += prompt.content + "\n\n"
        
        // Build metadata footer
        var metadata: [String] = []
        
        // Add category if present
        if let category = prompt.category, !category.isEmpty {
            metadata.append("Category: \(category)")
        }
        
        // Add tags if present
        if !prompt.tags.isEmpty {
            let tagNames = prompt.tags.map { $0.name }.joined(separator: ", ")
            metadata.append("Tags: \(tagNames)")
        }
        
        // Add creation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        metadata.append("Created: \(dateFormatter.string(from: prompt.createdAt))")
        
        // Add metadata footer if we have any metadata
        if !metadata.isEmpty {
            markdown += "---\n" + metadata.joined(separator: " | ")
        }
        
        return markdown
    }
}
