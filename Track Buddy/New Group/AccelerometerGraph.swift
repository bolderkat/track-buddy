//
//  AccelerometerGraph.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/23/21.
//

import Foundation
import SwiftUI

struct AccelerometerGraph: View {
    @ObservedObject private(set) var motionManager: MotionManager
    
    var body: some View {
        GeometryReader { geometry in
            let bounds = min(geometry.size.width, geometry.size.height)
            let pointScaleFactor = -bounds / outerEdgeGValue
            let xPosition = motionManager.x * pointScaleFactor
            let yPosition = motionManager.z * pointScaleFactor
            let innerCircleDiameter = bounds / outerToInnerCircleDiamaterRatio
            
            ZStack(alignment: .center) {
                Circle()
                Path(motionManager.pointPath(atScale: pointScaleFactor))
                    .stroke(Color.red, lineWidth: tracerLineWidth)
                    .offset(x: geometry.size.width / 2, y: geometry.size.height / 2)
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
    private let outerEdgeGValue = 3.0 // circle size doesn't appear to correspond with this set G value when graph is resized, check your maffs :(
    private let tracerLineWidth = 1.0
}

struct AccelerometerGraph_Previews: PreviewProvider {
    static var previews: some View {
        AccelerometerGraph(motionManager: MotionManager())
    }
}
