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
                
                WebImage(url: URL(string: self.contact.avatar))
                    .resizable()
                    .placeholder{ Image("empty-profile").resizable().frame(width: 45, height: 45, alignment: .center).scaledToFill() }
                    .indicator(.activity)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 45, height: 45, alignment: .center)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                
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
                
                Text(self.contact.phoneNumber.format(phoneNumber: String(self.contact.phoneNumber.dropFirst())))
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
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
