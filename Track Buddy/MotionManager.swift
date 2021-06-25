//
//  MotionManager.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/22/21.
//

import Foundation
import CoreMotion
import Combine
import Collections
import CoreGraphics

class MotionManager: ObservableObject {
    private var motionManager: CMMotionManager
    
    /* With device oriented vertically, axes are:
     +Z - braking
     -Z - acceleration
     +X - right
     -X - left
     
     */
    
    // Acceleration values
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    
    // Max G force values
    @Published var maxBraking: Double = 0.0
    @Published var maxAcceleration: Double = 0.0
    @Published var maxRight: Double = 0.0
    @Published var maxLeft: Double = 0.0
    
    private var recentPoints: Deque<CGPoint> = [] // TODO: think about thread safety?
    var recentPointsArray: [CGPoint] {
        Array(recentPoints)
    }
    
    init() {
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/100
            startDeviceMotion()
        }
    }
    
    private func startDeviceMotion() {
        guard !motionManager.isDeviceMotionActive else { return }
        
        // TODO: not recommended to handle updates on main queue
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motionData, error in
            guard error == nil else {
                // TODO: error handling
                print(error!)
                return
            }
            
            if let data = motionData {
                self?.process(data.userAcceleration)
            }
        }
    }
    
    private func process(_ acceleration: CMAcceleration) {
        x = acceleration.x
        y = acceleration.y
        z = acceleration.z
        
        if z > maxBraking {
            maxBraking = z
        } else if z < maxAcceleration {
            maxAcceleration = z
        }
        
        if x > maxRight {
            maxRight = x
        } else if x < maxLeft {
            maxLeft = x
        }
        
        let point = CGPoint(x: x, y: z)
        // Store values over the last minute for graph tracer line
        if recentPoints.count >= 60 * 100 {
            // TODO: if Deque methods are updated to use @discardableResult we can get rid of _ =
            _ = recentPoints.popFirst()
        }

        recentPoints.append(point)
        
    }
}
