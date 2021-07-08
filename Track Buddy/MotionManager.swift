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
import Accelerate

class MotionManager: ObservableObject {
    private enum Parameters {
        static let deviceMotionUpdateInterval: TimeInterval = 1/100
        static let graphUpdateInterval = RunLoop.SchedulerTimeType.Stride(1/15)
        static let secondsStoredForTracer: TimeInterval = 3
        static let pointStorageLimit = Int(1 / graphUpdateInterval.magnitude * secondsStoredForTracer)
        static let numberOfInterpolatedPathPoints = vDSP_Length(1 / deviceMotionUpdateInterval * secondsStoredForTracer)
        /// Unit stride for Accelerate calculations
        static let stride = vDSP_Stride(1)
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
        let xPoints = recentPoints.map { Double($0.x * factor) }
        let yPoints = recentPoints.map { Double($0.y * factor) }
        
        /* Interpolate points to fill in gaps between rate-limited points to create a smooth tracer line.
         
         Using this interpolate-to-smooth approach because generating the line with the raw accelerometer data at 100 Hz
         can produce visible divergence between the movement of the dot in the graph and the line that is traced under it.
         
         */
        
        let interpolatedXPoints = interpolate(xPoints)
        let interpolatedYPoints = interpolate(yPoints)
        
        let path = CGMutablePath()
        guard interpolatedXPoints.count == interpolatedYPoints.count else { return path }
        
        var interpolatedPoints: [CGPoint] = []
        for i in 0..<interpolatedXPoints.count {
            interpolatedPoints.append(CGPoint(
                x: interpolatedXPoints[i],
                y: interpolatedYPoints[i]
            ))
        }
        
        path.addLines(between: interpolatedPoints)
        return path
    }
    
    private func interpolate(_ points: [Double]) -> [Double] {
        var indices: [Double] = []
        for i in 0..<points.count {
            indices.append(Double(i) * 1 / graphUpdateInterval)
        }
        
        guard points.count > 0 else { return [] }
        let numberOfInterpolatedPoints = Int(Double(1) / Parameters.deviceMotionUpdateInterval * Double(points.count))
        
        var result = [Double](repeating: 0, count: numberOfInterpolatedPoints)
        vDSP_vgenpD(points, Parameters.stride,
                    indices, Parameters.stride,
                    &result, Parameters.stride,
                    vDSP_Length(numberOfInterpolatedPoints),
                    vDSP_Length(points.count))
        
        return result
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
            .sink { [weak self] point in
                self?.throttledPoint = point
                self?.addToDeque(with: point)
            }
        
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
