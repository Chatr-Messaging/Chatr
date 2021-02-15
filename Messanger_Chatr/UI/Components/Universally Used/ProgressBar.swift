//
//  ProgressBar.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/1/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var value: Int
     
     var body: some View {
         GeometryReader { geometry in
             VStack(alignment: .trailing) {
                 ZStack(alignment: .leading) {
                     Rectangle()
                        .foregroundColor(Color.primary)
                        .opacity(0.25)
                        .shadow(color: Color("buttonShadow_white"), radius: 8, x: -2, y: -2)
                        .shadow(color: Color("buttonShadow_Deeper"), radius: 8, x: 2, y: 2)
                    
                     Rectangle()
                         .frame(minWidth: 0, idealWidth:self.getProgressBarWidth(geometry: geometry),
                                maxWidth: self.getProgressBarWidth(geometry: geometry))
                        .foregroundColor(Color.white)
                         .cornerRadius(4)
                         .animation(.default)
                         .shadow(color: Color("buttonShadow_Deeper"), radius: 5, x: 5, y: 0)
                 }.frame(height:7)
                .cornerRadius(4)
             }.frame(height:7)
        }
     }
     
     func getProgressBarWidth(geometry:GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: .global)
        return frame.size.width * CGFloat(value) * 0.33
     }
     
     func getPercentage(_ value:CGFloat) -> String {
         let intValue = Int(ceil(value * 100))
         return "\(intValue) %"
     }
}
