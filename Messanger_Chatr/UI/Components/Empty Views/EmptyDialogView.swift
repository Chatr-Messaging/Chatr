//
//  EmptyDialogView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 11/16/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct EmptyDialogView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var showNewChat: Bool
    @Binding var isDiscoverOpen: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Image("EmptyDialog")
                .resizable()
                .scaledToFit()
                .frame(minWidth: Constants.screenWidth - 20, maxWidth: Constants.screenWidth)
                .frame(height: Constants.screenWidth < 375 ? 100 : 80)
                .padding(.top)
                .padding(.bottom, 10)

            Text(self.auth.isFirstTimeUser ? "Lets Get Started!" : "No Messages Found")
                .foregroundColor(.primary)
                .font(.title)
                .fontWeight(.semibold)
                .frame(alignment: .center)
            
            Text("Start a new conversation or \ndiscover an existing channel!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .padding(.horizontal)
            
            HStack(spacing: 10) {
                Button(action: {
                    self.showNewChat.toggle()
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }) {
                    HStack(alignment: .center, spacing: 10) {
                        Image("ComposeIcon_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22, alignment: .center)

                        Text("New Chat")
                            .font(.headline)
                            .foregroundColor(.white)
                    }.padding(.horizontal, 10)
                }.buttonStyle(MainButtonStyle())
                .frame(maxWidth: 230)
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.isDiscoverOpen.toggle()
                }) {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "safari")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22, alignment: .center)

                        Text("Discover")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }.padding(.horizontal, 10)
                    .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 55, maxHeight: 55)
                    .background(Color("buttonColor"))
                    .cornerRadius(15)
                    .frame(maxWidth: 230)
                }
                .buttonStyle(ClickButtonStyle())
            }
            .padding(.horizontal, 15)
            .padding(.bottom)
        }
        .frame(maxWidth: Constants.screenWidth - 50)
        .background(RoundedRectangle(cornerRadius: 25).frame(maxWidth: Constants.screenWidth - 30).foregroundColor(Color("bgColor_secondary")))
        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
    }
}

