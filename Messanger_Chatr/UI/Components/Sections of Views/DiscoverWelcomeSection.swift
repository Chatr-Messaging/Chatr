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
                Image("WelcomeToDiscover")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.screenWidth)

                Text("Welcome to Discover!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                Text("What is a Channel?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 2)

                Text("Channels allow you to broadcast and connect to unlimited audience members.")
                    .font(.none)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding()
                
                DiscoverWelcomeRulesSection()

                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.isShowing.toggle()
                    }
                    UserDefaults.standard.set(true, forKey: "discoverAgree1")
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
                .padding(.vertical, 40)
                
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
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.secondary)
                
                Text("Channels are a safe place to connect and share conversations.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            
            //By Joining
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
                
                Text("By joining, you agree to promote an anti-harassing & bullying environment.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
            
            //Banning
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.secondary)
                
                Text("Any harmful behavior will result in an immediate ban.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.secondary)
            }
        }.padding()
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("progressSlider"), lineWidth: 2.5))
        .padding()
    }
}
