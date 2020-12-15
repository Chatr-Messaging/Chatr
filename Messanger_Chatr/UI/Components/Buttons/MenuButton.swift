//
//  MenuButton.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import LocalAuthentication

// MARK: Menu Button
struct MenuBtn: View {
    @EnvironmentObject var auth: AuthModel
    var icon : String
    @State var size : CGFloat = Constants.btnSize
    @State var alertNum = 0
    @Binding var showNewChat : Bool
    @Binding var selectedContacts: [Int]


    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.showNewChat.toggle()
        }) {
            ZStack {
                ZStack {
                    //BlurView(style: .systemMaterial)
                    RoundedRectangle(cornerRadius: size / 4)
                        .foregroundColor(Color("buttonColor"))
                    
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .padding(.bottom, 2)
                        .padding(.leading, 2)
                        .padding(size * 0.22)
                        .foregroundColor(.primary)
                }
                .frame(width: size, height: size)
                //.background(Color.white)
                //.clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
                .shadow(color: Color("buttonShadow_Deeper"), radius: 10, x: 0, y: 8)
                
                ZStack(alignment: .center) {
                 Circle()
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundColor(Color("alertRed"))
                    .shadow(color: Color("alertRed"), radius: 5, x: 0, y: 3)
                    
                    Text(String(alertNum))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .font(.system(size: 12))
                }.offset(x: size * 0.45, y: -(size * 0.5))
                .opacity(self.alertNum > 0 ? 1 : 0)
                //.animation(.default)
            }
        }.buttonStyle(ClickButtonStyle())
    }
}
