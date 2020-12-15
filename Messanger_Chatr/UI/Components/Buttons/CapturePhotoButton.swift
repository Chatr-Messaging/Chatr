//
//  CapturePhotoButton.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/29/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct CapturePhotoButton: View {
    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterialLight)
                .frame(width: 70, height: 70, alignment: .center)
                .clipShape(Circle())
            
            Image(systemName: "camera").font(.title)
                .padding(15)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 0)
                .overlay(
                    Circle()
                        .strokeBorder(Constants.quickSnapGradient, lineWidth: 2.5)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 0)
                        .scaleEffect(x: 1.5, y: 1.5, anchor: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                )
        }
    }
}
