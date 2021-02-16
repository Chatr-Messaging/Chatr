//
//  ReactionsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/5/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct ReactionsView: View {
    @Binding var interactionSelected: String
    @Binding var reactions: [String]
    @Binding var message: MessageStruct

    var body: some View {
        HStack(spacing: 12.5) {
            if message.messageState != .error {
                ForEach(reactions, id: \.self) { img in
                    VStack {
                        Image(img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: interactionSelected == img ? 65 : 40, height: interactionSelected == img ? 65 : 40, alignment: .center)
                            .padding(interactionSelected == img ? -25 : 0)
                            .padding(.horizontal, interactionSelected == img ? 10 : 0)
                            .offset(y: interactionSelected == img ? -35 : 0)
                            .shadow(color: Color.black.opacity(0.15), radius: interactionSelected == img ? 10 : 5, x: 0, y: interactionSelected == img ? 8 : 4)
                        
                        if interactionSelected == img {
                            Text(img)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .offset(y: -5)
                        }
                    }
                }.padding(.vertical, 7.5)
            } else {
                Text("try again")
                    .foregroundColor(.red)
                    .fontWeight(.medium)
                    .frame(height: 50)
                    .scaleEffect(interactionSelected == "try again" ? 1.2 : 1.0)
                    .padding(.horizontal, interactionSelected == "try again" ? 15 : 10)
            }
        }.padding(.horizontal, 15)
        .background(BlurView(style: .systemThinMaterial).clipShape(RoundedRectangle(cornerRadius: 20)).shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2).background(interactionSelected == "try again" ? Color("bgColor") : Color.clear).cornerRadius(20))
        .onChange(of: self.interactionSelected) { _ in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
