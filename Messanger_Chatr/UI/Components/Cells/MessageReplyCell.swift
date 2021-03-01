//
//  MessageReplyCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct messageReplyStruct {
    var id: String
    var fromId: String
    var text: String
    var date: String
}

struct MessageReplyCell: View {
    @Binding var reply: messageReplyStruct
    @State var avatar: String = ""
    @State var fullName: String = ""

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .frame(width: 28, height: 28, alignment: .center)
                    .foregroundColor(Color("bgColor"))
                
                WebImage(url: URL(string: self.avatar))
                    .resizable()
                    .placeholder{ Image("empty-profile").resizable().frame(width: 28, height: 28, alignment: .center).scaledToFill() }
                    .indicator(.activity)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 28, height: 28, alignment: .center)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
            }
            Spacer()
        }
    }
}
