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
        VStack {
            Text("x: \(motionManager.x)")
            Text("y: \(motionManager.y)")
            Text("z: \(motionManager.z)")
        }
        .padding()
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
