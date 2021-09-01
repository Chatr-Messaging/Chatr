//
//  DiscoverWelcomeSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/23/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct DiscoverWelcomeSection: View {
    @Binding var isShowing: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack {
//                Image("WelcomeToDiscover")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: Constants.screenWidth)

//                Text("Terms")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.primary)
//                    .padding(.horizontal)

//                Text("What is a Channel?")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal)
//                    .padding(.top, 2)

//                Text("Channels allow you to broadcast and connect to unlimited audience members.")
//                    .font(.none)
//                    .fontWeight(.medium)
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.primary)
//                    .padding(.horizontal)
//                    .padding()
                
                DiscoverWelcomeRulesSection()

                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.isShowing.toggle()
                    }
                    UserDefaults.standard.set(true, forKey: "discoverAgree")
                }) {
                    HStack(alignment: .center, spacing: 15) {
                        Image(systemName: "checkmark.shield")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22, alignment: .center)
                            .offset(x: -2)
                            .foregroundColor(.white)

                        Text("Accept & Continue")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }.padding(.horizontal, 15)
                    .frame(minWidth: Constants.screenWidth - 100, maxWidth: Constants.screenWidth, minHeight: 55, maxHeight: 55)
                    .background(Color.blue)
                    .cornerRadius(15)
                    .frame(maxWidth: 230)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
                }.buttonStyle(ClickButtonStyle())
                .padding(.vertical)
                .padding(.bottom)
                
                FooterInformation()
                    .padding(.vertical, 25)
            }
        }
    }
}

struct DiscoverWelcomeRulesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            //Safe
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "exclamationmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.secondary)
                
                Text("Channels are a safe place to connect and share conversations.")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            
            //By Joining
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.secondary)
                
                Text("By joining, you agree to promote an anti-harassing & bullying environment.")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            
            //Banning
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.secondary)
                
                Text("Any harmful behavior will result in an immediate ban.")
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
        }.padding(.horizontal, 25)
        .padding(.vertical, 35)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color("progressSlider"), lineWidth: 2))
        .padding()
        .padding(.top, 50)
    }
}
