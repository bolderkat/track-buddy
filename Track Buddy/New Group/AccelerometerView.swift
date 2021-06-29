//
//  AccelerometerView.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/22/21.
//

import SwiftUI

struct AccelerometerView: View {
    @ObservedObject private var motionManager = MotionManager()
    
    var body: some View {
        HStack {
            maxLabel(for: .right)
            VStack {
                maxLabel(for: .braking)
                AccelerometerGraph(motionManager: motionManager)
                maxLabel(for: .acceleration)
            }
            maxLabel(for: .left)
        }
    }
    
    private func maxLabel(for direction: Direction) -> some View {
        // TODO: can use .formatted() for numbers if we set target to iOS 15.0
        
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
    
    private func currentLabel(for direction: Direction) -> some View {
        var value: Double = 0.0
        
        switch direction {
        case .braking, .acceleration:
            value = motionManager.z
        case .right, .left:
            value = motionManager.x
        }
        
        let valueString = value > 0 ? String(format: "%.2f", value) : "0.00"
        
        return Text(valueString)
            .foregroundColor(.orange)
    }
    
    private enum Direction {
        case braking
        case acceleration
        case right
        case left
    }
    
}


struct AccelerometerView_Previews: PreviewProvider {
    static var previews: some View {
        AccelerometerView()
    }
}
