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
    
    @IBOutlet weak var touchbarTextButton: NSButton!
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
    
    
    @IBAction func tapOnLabel(_ sender: AnyObject) {
        _=try? connectionController.setMessage(text: touchbarTextButton.title)
        let task = Process()
        task.launchPath = "/usr/bin/say"
        task.arguments = [touchbarTextButton.title]
        task.launch()
        task.waitUntilExit()
    }
    
    @IBOutlet weak var bgColorWell: NSColorWell!
    @IBAction func bgcolorDidChange(_ sender: AnyObject) {
        var color : NSColor! = (sender as? NSColorWell)?.color
        
        if #available(OSX 10.12.2, *) {
            if color == nil {
                color = (sender as? NSColorPickerTouchBarItem)?.color
            }
        }
        
        guard color != nil else { return }
        
        bgColorWell.color = color
        messageTextField.backgroundColor = color
        
        if #available(OSX 10.12.2, *) {
            if let tb = (sender as? NSView)?.superview?.touchBar,
                tb.itemIdentifiers.count > 1,
                let item = tb.item(forIdentifier: tb.itemIdentifiers[1]) as? NSColorPickerTouchBarItem
            {
                item.color = color
            }
        }
        
        do {
            try connectionController.setMessage(bgcolor : (red: Float(color.redComponent),
                                                           green: Float(color.greenComponent),
                                                           blue: Float(color.blueComponent)))
        } catch {
            // Problem during transmission, inform the user
            updateUI()
            NSAlert(error: error).runModal()
        }
    }
    
    /// ColorWell reference for text color selection
    @IBOutlet weak var colorWell: NSColorWell!
    /// Action to perform when the users update the color of the text
    @IBAction func colorDidChange(_ sender: AnyObject) {
        // The color is coming from a color well
        var color : NSColor! = (sender as? NSColorWell)?.color
        
        // The color is coming from a colorpicker on the touch bar
        if #available(OSX 10.12.2, *) {
            if color == nil {
                color = (sender as? NSColorPickerTouchBarItem)?.color
            }
        }
        
        // If we did not get the color, we cannot get further
        guard color != nil else { return }
        
        // Update the color in the color well, the textfield and the touchbar
        colorWell.color = color
        messageTextField.textColor = color
        if #available(OSX 10.12.2, *) {
            if let tb = (sender as? NSView)?.superview?.touchBar,
                let identifier = tb.itemIdentifiers.first,
                let item = tb.item(forIdentifier: identifier) as? NSColorPickerTouchBarItem
            {
                item.color = color
            }
        }
        
        // Send the color to the server
        do {
            try connectionController.setMessage(color : (red: Float(color.redComponent),
                                                         green: Float(color.greenComponent),
                                                         blue: Float(color.blueComponent)))
        } catch {
            // Problem during transmission, inform the user
            updateUI()
            NSAlert(error: error).runModal()
        }
    }
    
    /// Action to perform when the user enters a message in the textfield
    @IBAction func messageDidChanged(_ sender: NSTextField) {
        do {
            try connectionController.setMessage(text: sender.stringValue)
            touchbarTextButton.title = sender.stringValue
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
    
    @IBAction func showHour(_ sender: Any) {
        try? connectionController.showTime()
    }
    @IBAction func nyan(_ sender: Any) {
        try? connectionController.nyan()
    }
    @IBAction func dedim(_ sender: Any) {
        try? connectionController.dedim()
    }
    
    func updateUI() {
        addressComboBox.removeAllItems()
        addressComboBox.addItems(withObjectValues: connectionController.lastServers.map { $0 + ":\($1)" })
        addressComboBox.isEnabled = !connectionController.connected
        messageStackview.isHidden = !connectionController.connected
        disconnectButton.isEnabled = addressComboBox.stringValue.count > 0
        disconnectButton.state = connectionController.connected ? NSOnState : NSOffState
    }
}
