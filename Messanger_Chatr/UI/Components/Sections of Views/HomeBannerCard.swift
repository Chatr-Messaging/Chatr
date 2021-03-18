//
//  HomeBannerCard.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/17/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct HomeBannerCard: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isTopCardOpen: Bool
    @Binding var counter: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                print("discover more")
            }) {
                Image("banner")
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
            }.buttonStyle(ClickMiniButtonStyle())
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.counter += 1
                }
            }
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                withAnimation {
                    self.isTopCardOpen.toggle()
                }
            }) {
                Image("closeButton")
                    .resizable()
                    .frame(width: 30, height: 30, alignment: .center)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)

            }.padding(12.5)
        }.padding(.horizontal)
        .padding(.bottom)
        .offset(y: -10)
        .background(Color("bgColor"))
    }
}
