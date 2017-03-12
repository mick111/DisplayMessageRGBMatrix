//
//  AppDelegate.swift
//  DisplayMessage
//
//  Created by Michael Mouchous on 11/03/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let connectionController = ConnectionController()
    
    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var messageStackview: NSStackView!
    @IBOutlet weak var addressComboBox: NSComboBox!
    @IBOutlet weak var messageTextField: NSTextField!
    @IBOutlet weak var disconnectButton: NSButton!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        updateUI()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    @IBAction func selectionChanged(_ sender: Any) {
        updateUI()
    }
    
    @IBAction func connect(_ sender: Any) {
        
        defer { updateUI() }
        if (sender as? NSButton)?.state == NSOffState {
            connectionController.disconnect()
        } else {
            do {
                let hostPort = addressComboBox.stringValue.components(separatedBy: ":")
                
                try connectionController.connect(host: hostPort.first ?? "",
                                                 port: UInt16(hostPort.last ?? "0") ?? 0)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    
    @IBOutlet weak var colorWell: NSColorWell!
    
    @IBAction func colorDidChange(_ sender: Any) {
        
        var color : NSColor! = (sender as? NSColorWell)?.color
        
        if #available(OSX 10.12.2, *) {
            if color == nil {
                color = (sender as? NSColorPickerTouchBarItem)?.color
            }
        }
        
        guard color != nil else { return }
        
        colorWell.color = color
        messageTextField.textColor = color
        
        if #available(OSX 10.12.2, *) {
            if let tb = ((sender as? NSView)?.superview as? NSTouchBarProvider)?.touchBar,
                let identifier = tb.itemIdentifiers.first,
                let item = tb.item(forIdentifier: identifier) as? NSColorPickerTouchBarItem
                {
                    item.color = color
            }
        }
        
        do {
            try connectionController.setMessage(color : (red: Float(color.redComponent),
                                               green: Float(color.greenComponent),
                                               blue: Float(color.blueComponent)))
        } catch {
            updateUI()
            NSAlert(error: error).runModal()
        }
    }

    @IBAction func messageDidChanged(_ sender: NSTextField) {
        do {
            try connectionController.setMessage(text: sender.stringValue)
            if let color = sender.textColor {
                try connectionController.setMessage(color : (red: Float(color.redComponent),
                                                         green: Float(color.greenComponent),
                                                         blue: Float(color.blueComponent)))
            }
        } catch {
            updateUI()
            NSAlert(error: error).runModal()
        }
    }
    
    func updateUI() {
        addressComboBox.removeAllItems()
        addressComboBox.addItems(withObjectValues: connectionController.lastServers.map { $0 + ":\($1)" })
        addressComboBox.isEnabled = !connectionController.connected
        messageStackview.isHidden = !connectionController.connected
        disconnectButton.isEnabled = addressComboBox.stringValue.characters.count > 0
        disconnectButton.state = connectionController.connected ? NSOnState : NSOffState
    }
}
