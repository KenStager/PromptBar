import SwiftUI

@main
struct PromptBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we'll use menu bar only
        Settings {
            EmptyView()
        }
        .commands {
            // Remove the "New Window" menu item
            CommandGroup(replacing: .newItem) { }
        }
    }
}