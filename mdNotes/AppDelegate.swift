//
//  AppDelegate.swift
//  mdNotes
//
//  Created by Austin Chiatto on 2024-05-31.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var recentCharacters = [String]()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        startMonitoringKeystrokes()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // Start monitoring keystrokes
    func startMonitoringKeystrokes() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUpEvent(event)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            self?.handleKeyUpEvent(event)
            return event
        }
    }
    
    func handleKeyUpEvent(_ event: NSEvent) {
        guard let characters = event.characters else { return }
        
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           frontApp.bundleIdentifier == "com.apple.Notes" {
            recentCharacters.append(contentsOf: characters.map { String($0) })
            if recentCharacters.count > 3 {
                recentCharacters.removeFirst(recentCharacters.count - 3)
            }
            
            if recentCharacters.joined() == "## " {
                simulateBackspace(count: 3)
                triggerKeyboardShortcut()
                recentCharacters.removeAll()
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
    
    // Function to trigger the "Shift + Command + J" keyboard shortcut
        func triggerKeyboardShortcut() {
            let shiftDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(56), keyDown: true)
            let cmdDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(55), keyDown: true)
            let jKeyDown = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(38), keyDown: true)
            let jKeyUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(38), keyDown: false)
            let cmdUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(55), keyDown: false)
            let shiftUp = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(56), keyDown: false)

            shiftDown?.flags = [.maskShift]
            cmdDown?.flags = [.maskCommand]
            jKeyDown?.flags = [.maskCommand, .maskShift]
            jKeyUp?.flags = [.maskCommand, .maskShift]
            cmdUp?.flags = [.maskCommand]
            shiftUp?.flags = [.maskShift]

            shiftDown?.post(tap: .cghidEventTap)
            cmdDown?.post(tap: .cghidEventTap)
            jKeyDown?.post(tap: .cghidEventTap)
            jKeyUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
            shiftUp?.post(tap: .cghidEventTap)
        }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

