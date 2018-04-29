//
//  ViewController.swift
//  DisplayMessageiOS
//
//  Created by Michael Mouchous on 11/03/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import UIKit
import WatchConnectivity
import Photos
class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, WCSessionDelegate {
    let connectionController = ConnectionController()
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var lastConnectionsPicker: UIPickerView!
    
    @IBOutlet weak var disconnectButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        updateUI()
        hostTextField.text = connectionController.lastServers.first?.0
        let port = connectionController.lastServers.last?.1 ?? 0
        portTextField.text = port == 0 ? nil : "\(port)"
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }
    
    @IBAction func disconnect(_ sender: Any) {
        connectionController.disconnect()
        updateUI()
        messageTextField.resignFirstResponder()
    }
    
    @IBAction func connect(_ sender: AnyObject) {
        PHPhotoLibrary.requestAuthorization() { NSLog("\($0)") }
        
        defer { updateUI() }
        do {
            try connectionController.connect(host: hostTextField.text ?? "",
                                             port: UInt16(portTextField.text ?? "0") ?? 0)
            messageTextField.becomeFirstResponder()

        } catch {
            let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func messageDidChanged(_ sender: UITextField) {
        do { try connectionController.setMessage(text:sender.text ?? "")
            try connectionController.setMessage(color:lastTextColor)
            try connectionController.setMessage(bgcolor:lastBGColor)
        }
        catch {
            updateUI()
            let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == lastConnectionsPicker {
            return connectionController.lastServers.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == lastConnectionsPicker {
            let host_port = connectionController.lastServers[row]
            return host_port.0 + ":\(host_port.1)"
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == lastConnectionsPicker {
            let host_port = connectionController.lastServers[row]
            hostTextField.text = host_port.0
            let port = host_port.1
            portTextField.text = port == 0 ? nil : "\(port)"
        }
    }
    
    func updateUI() {
        lastConnectionsPicker.reloadAllComponents()
        hostTextField.isEnabled = !connectionController.connected
        portTextField.isEnabled = !connectionController.connected
        messageSV.isHidden = !connectionController.connected
        disconnectButton.isHidden = !connectionController.connected
        lastConnectionsPicker.isHidden = connectionController.connected || lastConnectionsPicker.numberOfRows(inComponent: 0) == 0
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Nothing to do
        NSLog(#function+" \(String(describing: error))")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Nothing to do
        NSLog(#function)
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Nothing to do
        NSLog(#function)
    }
    
    func handleMessageOnMainThread(message: [String : Any]) {
        if let text = message["TEXT"] as? String {
            messageTextField.text = text
            _ = try? connectionController.setMessage(text: text)
        }
        if let hue = message["COLORHUE"] as? CGFloat,
            let sat = message["COLORSAT"] as? CGFloat,
            let bri = message["COLORBRI"] as? CGFloat
        {
            let color = UIColor(hue: hue,
                                saturation: sat,
                                brightness: bri,
                                alpha: 1)
            messageTextField.textColor = color
            var r = CGFloat()
            var g = CGFloat()
            var b = CGFloat()
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            _ = try? connectionController.setMessage(color: (Float(r),
                                                             Float(g),
                                                             Float(b)))
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        performSelector(onMainThread: #selector(handleMessageOnMainThread(message:)), with: message, waitUntilDone: true)
    }
    
    var lastTextColor : (red: Float, green: Float, blue: Float) = (0.5,0.5,0.5)
    var lastBGColor : (red: Float, green: Float, blue: Float) = (0,0,0)
    
    @IBOutlet weak var messageSV: UIStackView!
    @IBOutlet weak var bgColorSlider: UISlider!
    @IBOutlet weak var bgColorWheelSelector: UIView!
    @IBOutlet weak var pointBGColorWheel: UIImageView!
    @IBAction func tapOnBGColorWheel(_ sender: UIGestureRecognizer) {
        let o = sender.location(in: bgColorWheelSelector)
        var r = colorAt(point: o, size:bgColorWheelSelector.frame.size)
        r.point.x -= pointBGColorWheel.frame.size.width/2
        r.point.y -= pointBGColorWheel.frame.size.height/2
        pointBGColorWheel.frame.origin = r.point
        let color = UIColor(hue: 1-r.hue,
                            saturation: r.sat,
                            brightness: 1-CGFloat((bgColorSlider.maximumValue-bgColorSlider.value)/(bgColorSlider.maximumValue-bgColorSlider.minimumValue)),
                            alpha: 1)
        messageTextField.backgroundColor = color
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        lastBGColor.red = Float(red)
        lastBGColor.green = Float(green)
        lastBGColor.blue = Float(blue)
        _ = try? connectionController.setMessage(bgcolor: lastBGColor)
    }
    
    @IBOutlet weak var colorSlider: UISlider!
    @IBOutlet weak var colorWheelSelector: UIView!
    @IBOutlet weak var pointColorWheel: UIImageView!
    @IBAction func tapOnColorWheel(_ sender: UIGestureRecognizer) {
        let o = sender.location(in: colorWheelSelector)
        var r = colorAt(point: o, size:colorWheelSelector.frame.size)
        r.point.x -= pointColorWheel.frame.size.width/2
        r.point.y -= pointColorWheel.frame.size.height/2
        pointColorWheel.frame.origin = r.point
        let color = UIColor(hue: 1-r.hue,
                            saturation: r.sat,
                            brightness: 1-CGFloat((colorSlider.maximumValue-colorSlider.value)/(colorSlider.maximumValue-colorSlider.minimumValue)),
                            alpha: 1)
        messageTextField.textColor = color
        var red = CGFloat()
        var green = CGFloat()
        var blue = CGFloat()
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        lastTextColor.red = Float(red)
        lastTextColor.green = Float(green)
        lastTextColor.blue = Float(blue)
        _ = try? connectionController.setMessage(color: lastTextColor)
    }
    @IBAction func showHour(_ sender: Any) {
        _ = try? connectionController.showTime()
        
    }
    @IBAction func tapNyan(_ sender: Any) {
        _ = try? connectionController.nyan()
    }
}

