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
    @Published private(set) var x: Double = 0.0
    @Published private(set) var y: Double = 0.0
    @Published private(set) var z: Double = 0.0
    
    // Max G force values
    @Published private(set) var maxBraking: Double = 0.0
    @Published private(set) var maxAcceleration: Double = 0.0
    @Published private(set) var maxRight: Double = 0.0
    @Published private(set) var maxLeft: Double = 0.0
    
    // Parameters
    private let deviceMotionUpdateInterval: TimeInterval = 1/100
    private let pointStorageLimit = 300 // number of motion updates stored for tracer graph
    
    private(set) var recentPoints: Deque<CGPoint> = [] // TODO: think about thread safety?
    
    func pointPath(atScale factor: CGFloat) -> CGMutablePath {
        var points: [CGPoint] = []
        for point in recentPoints {
            let x = point.x * factor
            let y = point.y * factor
            points.append(CGPoint(x: x, y: y))
        }
        let path = CGMutablePath()
        path.addLines(between: points)
        return path
    }
    
    init() {
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = deviceMotionUpdateInterval
            startDeviceMotion()
        }
    }
    
    private func startDeviceMotion() {
        guard !motionManager.isDeviceMotionActive else { return }

        let queue = OperationQueue()
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motionData, error in
            guard error == nil else {
                // TODO: error handling
                print(error!)
                return
            }
            
            
            if let data = motionData {
                DispatchQueue.main.async {
                    self?.process(data.userAcceleration)
                }
            }
        }
    }
    
    // TODO: a good place to use @MainActor here
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
        // Store values over the five seconds for graph tracer line
        if recentPoints.count >= pointStorageLimit {
            // TODO: if Deque methods are updated to use @discardableResult we can get rid of _ =
            _ = recentPoints.popFirst()
        }

        recentPoints.append(point)
        
    }
}
