//
//  NotificationSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/4/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct NotificationSection: View {
    @EnvironmentObject var auth: AuthModel

    var body: some View {
        ZStack(alignment: .top) {
            BlurView(style: .regular)
                .frame(width: Constants.screenWidth - 40, height: 75, alignment: .center)
                //.frame(minHeight: 65, maxHeight: 125)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                
            HStack(spacing: 10) {
                Image(systemName: "bell.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30, alignment: .center)
                    .foregroundColor(.blue)
                    .font(Font.title.weight(.regular))
                    .padding(.leading, 40)
                
                Text(self.auth.notificationtext)
                    .font(.none)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .padding(.trailing, 40)
                    .lineLimit(4)
                
                Spacer()
            }.padding(.vertical)            
        }
    }
}
