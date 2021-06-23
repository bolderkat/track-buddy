//
//  AccelerometerOverlay.swift
//  Track Buddy
//
//  Created by Daniel Luo on 6/22/21.
//

import SwiftUI

struct AccelerometerOverlay: View {
    var body: some View {
        ZStack {
            CameraView()
                .edgesIgnoringSafeArea(.all)
            AccelerometerView(viewModel: AccelerometerView.ViewModel())
                .padding()
        }
    }
}

struct AccelerometerOverlay_Previews: PreviewProvider {
    static var previews: some View {
        AccelerometerOverlay()
    }
}
