//
//  AppDelegate.swift
//  mdNotes
//
//  Created by Austin Chiatto on 2024-05-31.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var recentCharacters = [String]()
    
    let mdCommands: [String: [CGKeyCode]] = [
        "# ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(17)],                // ⇧ ⌘ T
        "## ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(4)],                // ⇧ ⌘ H
        "### ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(38)],              // ⇧ ⌘ J
        "#### ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(11)],             // ⇧ ⌘ B
        "``` ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(46)],              // ⇧ ⌘ M
        "> ": [CGKeyCode(55), CGKeyCode(39)],                               // ⌘'
        "[] ": [CGKeyCode(56), CGKeyCode(55), CGKeyCode(37)],               // ⇧ ⌘ L
    ]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
            setupStatusItem()
            checkAccessibilityPermissions()
            startGlobalMonitoringKeystrokes()
        }
    
    func setupStatusItem() {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem?.button?.title = "mdNotes"
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            statusItem?.menu = menu
        }

        @objc func quit() {
            NSApplication.shared.terminate(self)
        }
    
    func checkAccessibilityPermissions() {
            DispatchQueue.main.async {
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
                let accessEnabled = AXIsProcessTrustedWithOptions(options)

                if !accessEnabled {
                    print("Accessibility permissions are not enabled. Prompting user for permissions.")
                } else {
                    print("Accessibility permissions are enabled.")
                }
            }
        }
    
    func startGlobalMonitoringKeystrokes() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUpEvent(event)
        }
    }
    
    
    func handleKeyUpEvent(_ event: NSEvent) {
        guard let characters = event.characters, let notesApp = NSWorkspace.shared.frontmostApplication, notesApp.bundleIdentifier == "com.apple.Notes" else {
            return
        }
        
        recentCharacters.append(contentsOf: characters.map { String($0) })
        
        let maxRecentCharacters = 5
        if recentCharacters.count > maxRecentCharacters {
            recentCharacters.removeFirst(recentCharacters.count - maxRecentCharacters)
        }

        let recentString = recentCharacters.joined()
        for (mdCommand, shortcutKeys) in mdCommands {
            if recentString.hasSuffix(mdCommand) {
                triggerFormatting(keys: shortcutKeys)
                recentCharacters.removeAll()
                break
            }
        }
    }
    
    // Trigger specified Apple Notes formatting shortcut
    func triggerFormatting(keys: [CGKeyCode]) {
        print("Triggering formatting for keys: \(keys)")

        let source = CGEventSource(stateID: .hidSystemState)
        let keyFlags: CGEventFlags = [.maskShift, .maskCommand]

        func createKeyEvent(key: CGKeyCode, keyDown: Bool) -> CGEvent? {
            return CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: keyDown)
        }

        // Press down all modifier keys
        keys.forEach { key in
            if let event = createKeyEvent(key: key, keyDown: true) {
                event.flags = keyFlags
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
        }

        // Release all modifier keys
        keys.reversed().forEach { key in
            if let event = createKeyEvent(key: key, keyDown: false) {
                event.flags = keyFlags
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
        }
    }


    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
           return true
       }

       func applicationShouldRestoreApplicationState(_ app: NSApplication) -> Bool {
           return false
       }

       func applicationShouldSaveApplicationState(_ app: NSApplication) -> Bool {
           return false
       }
}

extension Optional {
    func apply(_ transform: (Wrapped) throws -> Void) rethrows -> Wrapped? {
        if let value = self { try transform(value) }
        return self
    }
}

