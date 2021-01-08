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
    @State var alertNum = 0
    @Binding var showNewChat : Bool
    @Binding var selectedContacts: [Int]

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            self.showNewChat.toggle()
        }) {
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.menuBtnSize / 4)
                        .foregroundColor(Color("buttonColor"))
                    
                    Image("ComposeIcon")
                        .resizable()
                        .scaledToFit()
                        .padding(.bottom, 2)
                        .padding(.leading, 2)
                        .padding(Constants.menuBtnSize * 0.22)
                        .foregroundColor(.primary)
                }.frame(width: Constants.menuBtnSize, height: Constants.menuBtnSize)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 10, x: 0, y: 8)
                
                ZStack(alignment: .center) {
                 Circle()
                    .frame(width: Constants.menuBtnSize * 0.5, height: Constants.menuBtnSize * 0.5)
                    .foregroundColor(Color("alertRed"))
                    .shadow(color: Color("alertRed"), radius: 5, x: 0, y: 3)
                    
                    Text(String(alertNum))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .font(.system(size: 12))
                }.offset(x: Constants.menuBtnSize * 0.45, y: -(Constants.menuBtnSize * 0.5))
                .opacity(self.alertNum > 0 ? 1 : 0)
            }
        }.buttonStyle(ClickButtonStyle())
    }
}
