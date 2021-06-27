//
//  SelectableAddressBookContact.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/20/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import SDWebImageSwiftUI

struct ContactRealmCell: View {
    @Binding var selectedContact: [Int]
    var contact = ContactStruct()

    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .center) {
                Circle()
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundColor(Color("bgColor"))
                
                if let avitarURL = self.contact.avatar, avitarURL != "" {
                    WebImage(url: URL(string: avitarURL))
                        .resizable()
                        .placeholder{ Image("empty-profile").resizable().frame(width: 45, height: 45, alignment: .center).scaledToFill() }
                        .indicator(.activity)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .scaledToFill()
                        .frame(width: 45, height: 45, alignment: .center)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                } else {
                    Circle()
                        .frame(width: 45, height: 45, alignment: .center)
                        .foregroundColor(Color("bgColor"))

                    Text("".firstLeters(text: self.contact.fullName))
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.yellow)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(7.5)
                    .opacity(contact.isFavourite ? 1 : 0)
                    .offset(x: -18, y: 18)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                
                RoundedRectangle(cornerRadius: 5)
                    .frame(width: 10, height: 10)
                    .foregroundColor(.green)
                    .overlay(Circle().stroke(Color("bgColor"), lineWidth: 2))
                    .opacity(contact.isOnline ? 1 : 0)
                    .offset(x: 16, y: 16)
                
//                Text("".firstLeters(text: self.$user.name))
//                    .font(.system(size: 14))
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading) {
                Text(self.contact.fullName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                
                Text(contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .offset(y: contact.isPremium ? -3 : 0)
            }
            Spacer()
            
            if self.selectedContact.contains(self.contact.id) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20, alignment: .center)
                    .foregroundColor(.blue)
                
            } else {
                Image(systemName: "circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 20, height: 20, alignment: .center)
                    .foregroundColor(.secondary)
            }

        }
    }
}
