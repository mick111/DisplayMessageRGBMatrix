//
//  ViewController.swift
//  DisplayMessageiOS
//
//  Created by Michael Mouchous on 11/03/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    let colors = ["red", "blue", "green", "yellow", "cyan", "magenta", "white"]
    let connectionController = ConnectionController()
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var hostTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var lastConnectionsPicker: UIPickerView!
    @IBOutlet weak var colorPicker: UIPickerView!
    
    @IBOutlet weak var disconnectButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateUI()
        hostTextField.text = connectionController.lastServers.first?.0
        let port = connectionController.lastServers.last?.1 ?? 0
        portTextField.text = port == 0 ? nil : "\(port)"
    }
    
    @IBAction func disconnect(_ sender: Any) {
        connectionController.disconnect()
        updateUI()
        messageTextField.resignFirstResponder()
    }
    
    @IBAction func connect(_ sender: Any) {
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
             try connectionController.setMessage(color:colors[colorPicker.selectedRow(inComponent: 0)])
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
        if pickerView == colorPicker {
            return colors.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == lastConnectionsPicker {
            let host_port = connectionController.lastServers[row]
            return host_port.0 + ":\(host_port.1)"
        }
        if pickerView == colorPicker {
            return colors[row]
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
        if pickerView == colorPicker {
            do { try connectionController.setMessage(color:colors[row]) }
            catch {
                updateUI()
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func updateUI() {
        lastConnectionsPicker.reloadAllComponents()
        hostTextField.isEnabled = !connectionController.connected
        portTextField.isEnabled = !connectionController.connected
        messageTextField.isHidden = !connectionController.connected
        disconnectButton.isHidden = !connectionController.connected
        lastConnectionsPicker.isHidden = connectionController.connected || lastConnectionsPicker.numberOfRows(inComponent: 0) == 0
        colorPicker.isHidden = !connectionController.connected || colorPicker.numberOfRows(inComponent: 0) == 0
    }
}

