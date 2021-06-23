//
//  AccelerometerView.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/22/21.
//

import SwiftUI

struct AccelerometerView: View {
    @StateObject var viewModel: ViewModel
    
    @ObservedObject var motionManager = MotionManager()
    
    var body: some View {
        HStack {
            maxLabel(for: .right)
            VStack {
                maxLabel(for: .braking)
                graph
                maxLabel(for: .acceleration)
            }
            maxLabel(for: .left)
        }
    }
    
    private func maxLabel(for direction: Direction) -> some View {
        // TODO: can use .formatted() for numbers if we set target to iOS 15.0
        // TODO: also if we can find a way to pass values from motionManager through the vm to the view, we can move all this formatting logic to the vm
        
        var labelString = ""
        var value: Double = 0.0
        
        switch direction {
        case .braking:
            labelString = "Max Braking"
            value = motionManager.maxBraking
        case .acceleration:
            labelString = "Max Accel"
            value = motionManager.maxAcceleration
        case .right:
            labelString = "Max Right"
            value = motionManager.maxRight
        case .left:
            labelString = "Max Left"
            value = motionManager.maxLeft
        }
        
        let valueString = String(format: "%.2f", abs(value))
        
        return VStack {
            Text(labelString)
            Text("\(valueString) G")
        }
    }
    
    private var graph: some View {
        GeometryReader { geometry in
            let bounds = min(geometry.size.width, geometry.size.height)
            let innerCircleDiameter = bounds / outerToInnerCircleDiamaterRatio
            let xPosition = -bounds * motionManager.x / outerEdgeGValue
            let yPosition = -bounds * motionManager.z / outerEdgeGValue
            
            ZStack(alignment: .center) {
                Circle()
                Circle()
                // Vertical axis corresponds with car acceleration/deceleration (z axis in Core Motion)
                // Relevant CM axes will also change depending on device orientation.
                    .foregroundColor(.orange)
                    .offset(x: xPosition, y: yPosition)
                    .frame(width: innerCircleDiameter, height: innerCircleDiameter)
            }
        }
    }
    
    // MARK: Drawing Constants
    private let outerToInnerCircleDiamaterRatio = 20.0
    private let outerEdgeGValue = 3.0
    
    private enum Direction {
        case braking
        case acceleration
        case right
        case left
    }
    
}

extension AccelerometerView {
    class ViewModel: ObservableObject {
        //        @Published private var motionManager = MotionManager()
        //        var x: Double { motionManager.x }
        //        var y: Double { motionManager.y }
        //        var z: Double { motionManager.z }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccelerometerView(viewModel: AccelerometerView.ViewModel())
    }
}
