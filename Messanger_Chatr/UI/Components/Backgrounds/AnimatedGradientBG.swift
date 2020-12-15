//
//  AnimatedGradientBG.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/16/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct AnimatedGradientGradientBG: View {
    @State var gradient = [Color("main_blue"), Color("main_pink")]
    @State var startPoint = UnitPoint(x: 0, y: 0)
    @State var endPoint = UnitPoint(x: 0, y: 2)
    
    var body: some View {
        Rectangle()
            .fill(LinearGradient(gradient: Gradient(colors: self.gradient), startPoint: self.startPoint, endPoint: self.endPoint))
            .frame(width: Constants.screenHeight, height: Constants.screenHeight)
            .onAppear() {
                withAnimation (Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)){
                    self.startPoint = UnitPoint(x: 1, y: -1)
                    self.endPoint = UnitPoint(x: 0, y: 1)
                }
            }
    }
}
