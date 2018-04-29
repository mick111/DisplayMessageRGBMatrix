//
//  InterfaceController.swift
//  DisplayMessageWatch Extension
//
//  Created by Michael Mouchous on 14/03/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import HealthKit
class InterfaceControllerBG: InterfaceController {
    override var isForBackground: Bool { return true }
}

class InterfaceController: WKInterfaceController, WKCrownDelegate {
    var isForBackground: Bool { return false }
    var motionManager: CMMotionManager { return extensionDelegate.motionManager }
    var extensionDelegate: ExtensionDelegate { return WKExtension.shared().delegate as! ExtensionDelegate }
    
    @IBOutlet var group: WKInterfaceGroup!
    @IBOutlet var slider: WKInterfaceSlider!
    @IBOutlet var groupBG: WKInterfaceGroup!
    @IBOutlet var groupBGBG: WKInterfaceGroup!
    
    var bri : Float = 1
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        bri += Float(rotationalDelta)
        bri = max(min(bri, 1.0), 0)
        slider.setValue(bri*255)
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.focus()
        crownSequencer.delegate = self
    }
    
    override func willDisappear() {
        // This method is called when watch view controller is no longer visible
        super.willDisappear()
        motionManager.stopAccelerometerUpdates()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        extensionDelegate.activateSession()
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
            guard let data = data else { return }
            
            let x = CGFloat(data.acceleration.x)*2
            let y = CGFloat(data.acceleration.y)*2
            let r = colorAt(point:.init(x:x,y:y),
                            size:.init(width: 130, height: 130))
            let sat = r.sat
            let hue = r.hue
            let color = UIColor(hue: hue,
                                saturation: sat,
                                brightness: CGFloat(self.bri),
                                alpha: 1)
            let posX = r.point.x + 6
            let posY = r.point.y + 6
            
            self.animate(withDuration: self.motionManager.accelerometerUpdateInterval/2){
                self.group.setWidth(posX)
                self.group.setHeight(posY)
                self.groupBGBG.setBackgroundColor(color)
                self.slider.setColor(color)
            }
            if self.isForBackground {
                self.extensionDelegate.sendBGColor(hue: hue, sat: sat, bri: CGFloat(self.bri))
            } else {
                self.extensionDelegate.sendColor(hue: hue, sat: sat, bri: CGFloat(self.bri))
            }
        }
    }
    
    @IBAction func didTouch(_ sender: WKTapGestureRecognizer) {
        extensionDelegate.sendHour()
    }
}
