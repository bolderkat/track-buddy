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
