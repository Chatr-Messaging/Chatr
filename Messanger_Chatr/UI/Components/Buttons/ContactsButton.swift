//
//  ContactsButton.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

// MARK: Contacts Button
struct ContactsBtn: View {
    @EnvironmentObject var auth: AuthModel
    @State var size : CGFloat = Constants.btnSize
    @Binding var showContacts : Bool
    @State var alertNum = 0
    var icon : String
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            self.showContacts.toggle()
        }) {
            ZStack {
                ZStack {
                    //BlurView(style: .systemMaterial)
                    RoundedRectangle(cornerRadius: size / 4)
                        .foregroundColor(Color("buttonColor"))

                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.25)
                        .foregroundColor(.primary)
                }
                .frame(width: size, height: size)
                //.background(Color.white)
                //.clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
                .shadow(color: Color("buttonShadow_Deeper"), radius: 10, x: 0, y: 8)

                ZStack(alignment: .center) {
                    HStack {
                        Text(String(self.alertNum))
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .font(.footnote)
                            .padding(.horizontal, 5)
                    }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 5, x: 0, y: 5))
                }.offset(x: size * 0.45, y: -(size * 0.5))
                .opacity(self.alertNum > 0 ? 1 : 0)
                //.animation(.default)
            }
        }.buttonStyle(ClickButtonStyle())

    }
}
