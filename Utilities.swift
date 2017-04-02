//
//  Utilities.swift
//  DisplayMessage
//
//  Created by Michael Mouchous on 02/04/2017.
//  Copyright © 2017 Michael Mouchous. All rights reserved.
//

import Foundation
import CoreGraphics

func colorAt(point: CGPoint, size:CGSize) -> (point: CGPoint, hue: CGFloat, sat: CGFloat) {
    let x = max(min(1.0, point.x/size.width), 0)*2 - 1
    let y = max(min(1.0, point.y/size.height), 0)*2 - 1
    
    let teta = atan2(y,x)
    let sat = min(1.0, sqrt(x*x+y*y))
    let hue = 0.5 + (teta / CGFloat(2*Double.pi))
    let posX = 0.5 + 0.5 * cos(teta) * sat
    let posY = 0.5 + 0.5 * sin(teta) * sat
    return (.init(x: posX*size.width, y: posY*size.height), hue, sat)
}
