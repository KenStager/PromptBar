import Carbon
import Cocoa

final class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    
    private init() {}
    
    func registerHotkey() {
        // Unregister existing hotkey first
        unregisterHotkey()
        
        // Register Cmd+Shift+P hotkey
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let modifiers = UInt32(cmdKey + shiftKey)
        let keyCode: UInt32 = 35 // 'P' key
        
        let signature = OSType(0x50424152) // 'PBAR'
        var hotKeyID = EventHotKeyID(signature: signature, id: 1)
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
            return
        }
        
        // Install event handler
        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .togglePromptBar,
                        object: nil
                    )
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        
        print("Hotkey Cmd+Shift+P registered successfully")
    }
    
    func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}

extension Notification.Name {
    static let togglePromptBar = Notification.Name("togglePromptBar")
}