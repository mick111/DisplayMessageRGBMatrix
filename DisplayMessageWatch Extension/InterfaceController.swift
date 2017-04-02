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
import WatchConnectivity
import HealthKit

class InterfaceController: WKInterfaceController, WCSessionDelegate, WKCrownDelegate {

    let motionManager = CMMotionManager()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.focus()
        crownSequencer.delegate = self
    }
    
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

    override func willActivate() {
        
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if WCSession.isSupported() {
            let session = WCSession.default()
            session.delegate = self
            session.activate()
        }
        
        motionManager.accelerometerUpdateInterval = 1
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
            guard let data = data else { return }
            
            let x = CGFloat(data.acceleration.x)*2
            let y = CGFloat(data.acceleration.y)*2
            let r = colorAt(point:.init(x:x,y:y),
                            size:.init(width: 73, height: 73))
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
            
            if WCSession.isSupported() {
                let session = WCSession.default()
                if session.activationState == .activated {
                    session.sendMessage(
                        ["COLORHUE": hue,
                         "COLORSAT": sat,
                         "COLORBRI": CGFloat(self.bri)
                        ], replyHandler: nil)
                }
            }
        }
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            session.sendMessage(["TEXT":"\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short))"], replyHandler: nil)
        }
    }
    
    @IBAction func didTouch(_ sender: WKTapGestureRecognizer) {
        let session = WCSession.default()
        if session.activationState == .activated {
            session.sendMessage(["TEXT":"\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short))"], replyHandler: nil)
        }
    }
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        motionManager.stopAccelerometerUpdates()
    }

}
