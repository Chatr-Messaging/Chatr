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
                    .frame(width: interactionSelected == img ? 80 : 38, height: interactionSelected == img ? 80 : 38, alignment: .center)
                    .padding(interactionSelected == img ? -30 : 0)
                    .offset(y: interactionSelected == img ? -50 : 0)
            }
        }.padding(.vertical, 5)
        .padding(.horizontal, 20)
        .background(Color.white.clipShape(Capsule()))
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: -5, y: 5)
    }
}
