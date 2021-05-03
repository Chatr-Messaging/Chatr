//
//  ChatrStats.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/13/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import FirebaseDatabase
import RealmSwift

struct ChatrStats: View {
    @EnvironmentObject var auth: AuthModel
    @State var userCount: Int = 0
    @State var quickSnapCount: Int = 0

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                //MARK: Overall Section
                HStack {
                    Text("OVERALL:")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .offset(y: 2)
                    Spacer()
                }.padding(.top, 10)
                
                VStack(alignment: .center) {
                    VStack(spacing: 0) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.auth.fetchTotalUserCount(completion: { count in
                                self.userCount = count
                            })
                        }) {
                            HStack(alignment: .center) {
                                Text("Users:")
                                    .foregroundColor(.primary)

                                Spacer()
                                if self.userCount != UserDefaults.standard.integer(forKey: "chatrUserStats") {
                                    Text("+\(UserDefaults.standard.integer(forKey: "chatrUserStats"))")
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                        .offset(x: 2)
                                }

                                Text("\(self.userCount)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .offset(x: 2)
                                
                                Text("total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .font(Font.title.weight(.bold))
                                    .scaledToFit()
                                    .frame(width: 7, height: 15, alignment: .center)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                            .padding(.vertical, 12.5)
                            
                            Divider()
                                .frame(width: Constants.screenWidth - 80)
                        }.buttonStyle(changeBGButtonStyle())
                        .onAppear() {
                            self.auth.fetchTotalUserCount(completion: { count in
                                self.userCount = count
                            })
                            UserDefaults.standard.set(true, forKey: "isEarlyAdopter")
                        }.onDisappear() {
                            if self.userCount != UserDefaults.standard.integer(forKey: "chatrUserStats") || self.quickSnapCount != UserDefaults.standard.integer(forKey: "chatrQuickSnapsStats") {
                                UserDefaults.standard.set(self.userCount, forKey: "chatrUserStats")
                                UserDefaults.standard.set(self.quickSnapCount, forKey: "chatrQuickSnapsStats")
                            }
                        }
                                                
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.auth.fetchTotalQuickSnapCount(completion: { count in
                                self.quickSnapCount = count
                            })
                        }) {
                            HStack(alignment: .center) {
                                Text("Quick Snaps:")
                                    .foregroundColor(.primary)

                                Spacer()
                                if self.quickSnapCount != UserDefaults.standard.integer(forKey: "chatrQuickSnapsStats") {
                                    Text("+\(UserDefaults.standard.integer(forKey: "chatrQuickSnapsStats"))")
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                        .offset(x: 2)
                                }
                                
                                Text("\(self.quickSnapCount)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .offset(x: 2)
                                
                                Text("total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .font(Font.title.weight(.bold))
                                    .scaledToFit()
                                    .frame(width: 7, height: 15, alignment: .center)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                            .padding(.vertical, 12.5)
                        }.buttonStyle(changeBGButtonStyle())
                    }
                }.background(Color("buttonColor"))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
                .padding(.bottom, 5)
                .onAppear() {
                    self.auth.fetchTotalQuickSnapCount(completion: { count in
                        self.quickSnapCount = count
                    })
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.auth.fetchTotalQuickSnapCount(completion: { count in
                        self.quickSnapCount = count
                    })
                    self.auth.fetchTotalUserCount(completion: { count in
                        self.userCount = count
                    })
                }) {
                    HStack {
                        Image(systemName: "arrow.2.circlepath")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24, alignment: .center)
                            .foregroundColor(.white)
                        
                        Text("Refresh")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }.buttonStyle(MainButtonStyle())
                .frame(height: 55)
                .frame(width: 185)
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
                .padding(.top, 30)
                .padding()
            }
        }
    }
}
