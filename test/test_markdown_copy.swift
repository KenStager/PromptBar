#!/usr/bin/swift

import Foundation
import AppKit

// Test prompt data structure (simplified)
struct Tag {
    let name: String
}

struct TestPrompt {
    let id = UUID()
    let title: String
    let content: String
    let description: String?
    let category: String?
    let tags: [Tag]
    let createdAt = Date()
    let isFavorite = false
    let analysisStatus = "pending"
    let analysisConfidence: Double? = nil
}

// Copy of the formatPromptAsMarkdown function
func formatPromptAsMarkdown(_ prompt: TestPrompt) -> String {
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

// Test the function
print("Testing Markdown formatting...")

let testPrompt = TestPrompt(
    title: "Test Prompt",
    content: "This is a test prompt content.\nIt has multiple lines.\nAnd should format nicely.",
    description: "A sample prompt for testing",
    category: "Testing",
    tags: [Tag(name: "test"), Tag(name: "swift"), Tag(name: "markdown")]
)

let markdown = formatPromptAsMarkdown(testPrompt)
print("\n=== Generated Markdown ===")
print(markdown)
print("=== End Markdown ===\n")

// Test clipboard operations
let pasteboard = NSPasteboard.general
pasteboard.clearContents()
let success = pasteboard.setString(markdown, forType: .string)
print("Clipboard write success: \(success)")

if let clipboardContent = pasteboard.string(forType: .string) {
    print("Clipboard content verified: \(clipboardContent.count) characters")
    print("First 100 chars: \(clipboardContent.prefix(100))...")
} else {
    print("ERROR: Could not read clipboard content!")
}

print("\n✅ Test complete - check clipboard for Markdown content")
