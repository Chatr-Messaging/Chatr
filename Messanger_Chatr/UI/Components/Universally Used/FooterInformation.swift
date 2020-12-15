//
//  FooterInformation.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/2/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct FooterInformation: View {
    @State var middleText: String = ""
    @State var topMiddleText: String = ""

    var body: some View {
        VStack(alignment: .center, spacing: 3) {
            HStack {
                Image("ChatBubble_dark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27, height: 18, alignment: .center)
                
                Text("Chatr")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .offset(x: -2)
            }.offset(y: self.topMiddleText != "" ? 5 : 0)
            
            //Only used for like count when visit user profile
            if self.topMiddleText != "" {
                HStack(alignment: .center) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.secondary)
                        .frame(width: 14, height: 14, alignment: .center)
                        .padding(.trailing, 5)
                    
                    Text(self.topMiddleText)
                        .font(.footnote)
                        .fontWeight(.none)
                        .foregroundColor(.secondary)
                }
            }
            
            if self.middleText != "" {
                Text(self.middleText)
                    .font(.caption)
                    .fontWeight(.none)
                    .foregroundColor(.secondary)
            }
            
            Text("version: " + Constants.projectVersion)
                .font(.caption)
                .fontWeight(.none)
                .italic()
                .foregroundColor(.secondary)
        }
    }
}
