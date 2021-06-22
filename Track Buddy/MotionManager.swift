//
//  MotionManager.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/22/21.
//

import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private var motionManager: CMMotionManager
    
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    
    init() {
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/60
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
                self?.x = data.userAcceleration.x
                self?.y = data.userAcceleration.y
                self?.z = data.userAcceleration.z
            }
        }
    }
}
