//
//  RingtoneView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

// MARK: Ringtone Section
struct ringtoneView: View {
    var body: some View {
        VStack {
            VStack(alignment: .center) {
                VStack {
                    HStack(alignment: .center) {
                        Text("no contact requests...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .fontWeight(.regular)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.padding(.horizontal)
                }.padding(.vertical, 15)
            }.background(Color("buttonColor"))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
            .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            .padding(.horizontal)
            .padding(.bottom, 25)
            .padding(.top, 120)
            
            Spacer()
        }
    }
}
