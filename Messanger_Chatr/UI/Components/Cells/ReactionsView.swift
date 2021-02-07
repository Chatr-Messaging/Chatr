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
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(reactions, id: \.self) { img in
                Image(img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: interactionSelected == img ? 65 : 40, height: interactionSelected == img ? 65 : 40, alignment: .center)
                    .padding(interactionSelected == img ? -25 : 0)
                    .padding(.horizontal, interactionSelected == img ? 10 : 0)
                    .offset(y: interactionSelected == img ? -35 : 0)
            }.padding(.vertical, 8)
        }.padding(.horizontal, 15)
        .background(BlurView(style: .systemThinMaterial).clipShape(Capsule()).shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2))
        .onChange(of: self.interactionSelected) { _ in
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
}
