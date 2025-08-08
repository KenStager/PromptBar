import Cocoa
import SwiftUI

// Simplified version for testing - replace AppDelegate.swift content with this if needed
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("PromptBar: Starting...")
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use simple text
            button.title = "P"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            print("PromptBar: Menu bar item created with title 'P'")
        }
        
        // Keep app as menu bar only
        NSApp.setActivationPolicy(.accessory)
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        print("PromptBar: Menu bar item clicked!")
        
        // Show a simple alert to confirm it's working
        let alert = NSAlert()
        alert.messageText = "PromptBar"
        alert.informativeText = "Menu bar app is working!"
        alert.runModal()
    }
    
    private func setupDependencies() {
        // Placeholder for now
    }
}