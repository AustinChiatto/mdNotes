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
        checkAndRequestPermissions()
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
    
    func checkAndRequestPermissions() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if accessEnabled {
            startGlobalMonitoringKeystrokes()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showPermissionsAlert()
            }
        }
    }
    
    func showPermissionsAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Accessibility Permissions Required"
        alert.informativeText = """
        This application requires Accessibility permissions to work properly.
        Please go to System Preferences > Security & Privacy > Accessibility and grant access to this app.
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
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

        // Sort mdCommands by key length in descending order
        let sortedCommands = mdCommands.keys.sorted { $0.count > $1.count }

        for mdCommand in sortedCommands {
            if recentString.hasSuffix(mdCommand), let shortcutKeys = mdCommands[mdCommand] {
                simulateBackspace(count: mdCommand.count)
                triggerFormatting(keys: shortcutKeys)
                recentCharacters.removeAll()
                break
            }
        }
    }
    
    func simulateBackspace(count: Int) {
       let backspace = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(51), keyDown: true)
       let backspaceUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(51), keyDown: false)
       
       for _ in 0..<count {
           backspace?.post(tap: .cghidEventTap)
           backspaceUp?.post(tap: .cghidEventTap)
       }
   }
    
    // Trigger specified Apple Notes formatting shortcut
    func triggerFormatting(keys: [CGKeyCode]) {

        let source = CGEventSource(stateID: .hidSystemState)
        let keyFlags: CGEventFlags = [.maskShift, .maskCommand]

        func createKeyEvent(key: CGKeyCode, keyDown: Bool) -> CGEvent? {
            return CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: keyDown)
        }

        keys.forEach { key in
            if let event = createKeyEvent(key: key, keyDown: true) {
                event.flags = keyFlags
                event.post(tap: CGEventTapLocation.cghidEventTap)
            }
        }

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
}

extension Optional {
    func apply(_ transform: (Wrapped) throws -> Void) rethrows -> Wrapped? {
        if let value = self { try transform(value) }
        return self
    }
}

