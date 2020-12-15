//
//  HomeMessagesTitle.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

// MARK: Home Header Section
struct HomeMessagesTitle: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isLocalOpen: Bool
    @Binding var contacts: Bool
    @Binding var newChat: Bool
    @Binding var showUserProfile: Bool
    @Binding var selectedContacts: [Int]

    var body: some View {
            HStack {
                Text("Messages")
                    //.font(.largeTitle)
                    .font(.system(size: 38))
                    .fontWeight(.semibold)
                    //.frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.primary)
                
//                if self.auth.isUserAuthenticated == .signedIn {
//                    if let avitarURL = PersistenceManager.shared.fetchProfile(UserProfile.self).avatar {
//                        WebImage(url: URL(string: avitarURL))
//                            .resizable()
//                            .placeholder{ Image(systemName: "person.fill") }
//                            .indicator(.activity)
//                            .transition(.fade(duration: 0.25))
//                            .scaledToFill()
//                            .clipShape(Circle())
//                            .frame(width: 46, height: 46, alignment: .center)
//                            .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
//                            .onTapGesture {
//                                self.showUserProfile.toggle()
//                            }.sheet(isPresented: self.$showUserProfile, content: {
//                                NavigationView {
//                                    ProfileView(dimissView: self.$showUserProfile)
//                                        .environmentObject(self.auth)
//                                        .background(Color("bgColor"))
//                                }
//                            })
//                    }
//                }
//
//                VStack(alignment: .leading) {
//                    Text("Welcome Back,")
//                        .font(.system(size: 16))
//                        .foregroundColor(Color.secondary)
//                        .padding(.bottom, 2)
//
//                    Text(PersistenceManager.shared.getCubeProfile()?.fullName ?? "Chatr User")
//                        .font(.system(size: 18))
//                        .fontWeight(.medium)
//                        .foregroundColor(Color.primary)
//                        .lineLimit(1)
//                }.onTapGesture {
//                    self.showUserProfile.toggle()
//                }.sheet(isPresented: self.$showUserProfile, content: {
//                    NavigationView {
//                        ProfileView(dimissView: self.$showUserProfile)
//                            .environmentObject(self.auth)
//                            .background(Color("bgColor"))
//                    }
//                })
                
                Spacer()
                
                ContactsBtn(showContacts: self.$contacts, icon: "rectangle.stack.person.crop")
                    .environmentObject(self.auth)
                    .frame(width: Constants.btnSize, height: Constants.btnSize)
                    .offset(x: -5, y: -5)

                MenuBtn(icon: "ComposeIcon", showNewChat: self.$newChat, selectedContacts: self.$selectedContacts)
                    .environmentObject(self.auth)
                    .frame(width: Constants.btnSize, height: Constants.btnSize)
                    .offset(y: -5)
                    
        }.zIndex(self.isLocalOpen ? 0 : 2)
        .padding(.horizontal)
    }
}
