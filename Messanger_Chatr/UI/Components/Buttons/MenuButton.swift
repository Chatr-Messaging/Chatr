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
            self.showNewChat.toggle()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }) {
            ZStack {
                Image("ComposeIcon")
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 2)
                    .padding(.leading, 2)
                    .padding(Constants.menuBtnSize * 0.22)
                    .foregroundColor(.primary)
                
                ZStack(alignment: .center) {
                    HStack {
                        Text(String(self.alertNum))
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .font(.footnote)
                            .padding(.horizontal, 5)
                    }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 5, x: 0, y: 5))
                }.offset(x: Constants.menuBtnSize * 0.45, y: -(Constants.menuBtnSize * 0.5))
                .opacity(self.alertNum > 0 ? 1 : 0)
            }
        }.buttonStyle(HomeButtonStyle())
    }
}
