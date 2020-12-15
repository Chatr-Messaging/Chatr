//
//  BackgroundUI.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/8/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct BackgroundUI: View {
       @State var gradient1 = true
       @State var gradient2 = true
    
       var body: some View {
        ZStack {
            GeometryReader { geo in
                let negHeight = -geo.size.height / 2 + 200
                let posHeight = geo.size.height / 2 - 200
                let xPosition = geo.size.width / 2 + 75
                
                Circle()
                    .frame(width: gradient1 ? 950 : 550, height: gradient1 ? 950 : 550, alignment: .center)
                    .foregroundColor(Color("main_blue"))
                    .blur(radius: 75)
                    .opacity(0.45)
                    .offset(x: xPosition, y: gradient1 ? negHeight : posHeight)
                    .animation(Animation.easeInOut(duration: 18).repeatForever(autoreverses: true))
                    .onAppear() {
                        self.gradient1.toggle()
                    }

                Circle()
                    .frame(width: gradient2 ? 550 : 950, height: gradient2 ? 550 : 950, alignment: .center)
                    .foregroundColor(Color("main_pink"))
                    .blur(radius: 75)
                    .opacity(0.3)
                    .offset(x: -xPosition, y: gradient2 ? posHeight : negHeight)
                    .animation(Animation.easeInOut(duration: 18).repeatForever(autoreverses: true))
                    .onAppear() {
                        self.gradient2.toggle()
                     }
            }.background(Color("bgColor"))
        }
    }
}

struct BackgroundUI_Previews: PreviewProvider {
    static var previews: some View {
        BackgroundUI()
    }
}
