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
    private enum Parameters {
        static let deviceMotionUpdateInterval: TimeInterval = 1/100
        static let graphUpdateInterval = RunLoop.SchedulerTimeType.Stride(1/15)
        static var pointStorageLimit: Int {
            // final number after multiplier == number of seconds retained for tracer line
            Int(1 / graphUpdateInterval.magnitude * 3)
        }
    }
    
    /// Provides rate of throttled accelerometer data updates in seconds for UI rendering purposes.
    var graphUpdateInterval: TimeInterval { Parameters.graphUpdateInterval.magnitude }

    init() {
        motionManager = CMMotionManager()
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = Parameters.deviceMotionUpdateInterval
            startDeviceMotion()
        }
        setUpThrottledPointPublisher()
    }
    
    private var motionManager: CMMotionManager
    
    /* With device oriented vertically, axes are:
     +Z - acceleration
     -Z - braking
     +X - left
     -X - right
     
     */
    
    // Acceleration values
    private(set) var x: Double = 0.0
    private(set) var y: Double = 0.0
    private(set) var z: Double = 0.0
    
    
    // Max G force values
    @Published private(set) var maxBraking: Double = 0.0
    @Published private(set) var maxAcceleration: Double = 0.0
    @Published private(set) var maxRight: Double = 0.0
    @Published private(set) var maxLeft: Double = 0.0

    
    // Rate-limited point that updates at `graphUpdateInterval` to smooth out graph movement
    @Published private(set) var throttledPoint: CGPoint = .zero
    private let pointPublisher = PassthroughSubject<CGPoint, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    
    // Store recent rate-limited points to render path representing past G force values
    private var recentPoints: Deque<CGPoint> = [] // TODO: dluo- think about thread safety?
    
    func pointPath(atScale factor: CGFloat) -> CGMutablePath {
        let points = recentPoints.map { CGPoint(x: $0.x * factor, y: $0.y * factor) }
        let path = CGMutablePath()
        path.addLines(between: points)
        return path
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
    
    private func setUpThrottledPointPublisher() {
        let cancellable = pointPublisher
            .throttle(for: Parameters.graphUpdateInterval, scheduler: RunLoop.main, latest: true)
            .receive(on: DispatchQueue.main, options: nil)
            .sink(receiveValue: { [weak self] point in
                self?.throttledPoint = point
                self?.addToDeque(with: point)
            })
        
        subscriptions.insert(cancellable)
    }
    
    // TODO: dluo - a good place to use @MainActor here
    private func process(_ acceleration: CMAcceleration) {
        x = acceleration.x
        y = acceleration.y
        z = acceleration.z
        
        if z > maxAcceleration {
            maxAcceleration = z
        } else if z < maxBraking {
            maxBraking = z
        }
        
        if x > maxLeft {
            maxLeft = x
        } else if x < maxRight {
            maxRight = x
        }
        
        let point = CGPoint(x: x, y: z)
        pointPublisher.send(point)
    }
    
    func resetMaxValues() {
        maxBraking = 0.0
        maxAcceleration = 0.0
        maxRight = 0.0
        maxLeft = 0.0
    }
    
    func addToDeque(with point: CGPoint) {
        if self.recentPoints.count >= Parameters.pointStorageLimit {
            // If Deque methods are updated to use @discardableResult we can get rid of _ =
            _ = self.recentPoints.popFirst()
        }
        self.recentPoints.append(point)
    }
}
