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

struct ContactCell: View {
    @State var user: User
    @Binding var selectedContact: [Int]

    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .center) {
                Circle()
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundColor(Color("bgColor"))
                
                if let avatarUrl = self.user.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: self.user), avatarUrl != "" {
                    WebImage(url: URL(string: avatarUrl))
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
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)

                    Text("".firstLeters(text: self.user.fullName ?? "No Name"))
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading) {
                Text(self.user.fullName ?? "No Name")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.primary)

                Text("last online \(self.user.lastRequestAt?.getElapsedInterval(lastMsg: "moments") ?? "recently") ago")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            
            if self.selectedContact.contains(Int(self.user.id)) {
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
        }.redacted(reason: user.phone == "" ? .placeholder : [])
    }
}
