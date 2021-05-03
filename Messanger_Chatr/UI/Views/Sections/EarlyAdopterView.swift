//
//  EarlyAdopterView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/8/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConfettiSwiftUI

struct EarlyAdopterView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var counter: Int
    @State var userOverallCount: Int = 0
    @State var hasClaimed: Bool = false


    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 5) {
                Text("Congradulations! 🎉")
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .offset(y: -20)
                
                Text("Early Adopter!")
                    .font(.system(size: 34))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .offset(y: -10)
                
                Text("You are Chatr user #\(self.userOverallCount)!")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .offset(y: -5)
                    .onAppear() {
                        self.auth.fetchTotalUserCount(completion: { count in
                            self.userOverallCount = count
                        })
                    }

                Text("We understand this is a early version and the best is yet to come. We apreciate all feedback. \nEnjoy this free Icon!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                
                Image("AppIcon-Original-Dark")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .cornerRadius(20)
                    .padding(.vertical)
                
                Button(action: {
                    if self.hasClaimed {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    self.counter += 1
                    self.hasClaimed = true
                    UserDefaults.standard.set("AppIcon-Original-Dark", forKey: "selectedAppIcon")
                    self.auth.changeHomeIconTo(name: "AppIcon-Original-Dark")
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: self.hasClaimed ? "lock.open.fill" : "lock.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22, alignment: .center)
                        
                        Text(self.hasClaimed ? "Claimed Gift" : "Claim Gift")
                            .fontWeight(.semibold)
                    }
                    
                }.buttonStyle(MainButtonStyle())
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
            }
        }
    }
}
