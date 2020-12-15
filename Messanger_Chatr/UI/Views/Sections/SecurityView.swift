//
//  SecurityView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import FirebaseDatabase
import RealmSwift
import LocalAuthentication

struct securityView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isLocalAuthOn: Bool
    @Binding var isPremium: Bool
    @Binding var isInfoPrivate: Bool
    @Binding var isMessaging: Bool
    @State var openMenbership: Bool = false
    @State var lockedOutText: String = String()

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    
                    //MARK: Personal Privacy Section
                    HStack {
                        Text("PERSONAL PRIVACY:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        VStack(alignment: .trailing, spacing: 0) {
                            Toggle("Private Info", isOn: self.$isInfoPrivate)
                                .onReceive([self.isInfoPrivate].publisher.first()) { (value) in
                                    print("New value is: \(value)")
                                    Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isInfoPrivate" : value])
                                }.padding(.horizontal)
                                .padding(.vertical, 12.5)
                            
                            Divider()
                                .frame(width: Constants.screenWidth - 80)
                            
                            Toggle("Private Messaging", isOn: self.$isMessaging)
                                .padding(.horizontal)
                                .padding(.vertical, 12.5)
                                .onReceive([self.isMessaging].publisher.first()) { (value) in
                                    Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isMessagingPrivate" : value])
                                }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    HStack(alignment: .center) {
                        Text("-private info: rejects public users from viewing your phone, email, & website\n-private messaging: denies public users messaging")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }.padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    //MARK: Personal Privacy Section
                    HStack {
                        Text("2-AUTH SECURITY:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        VStack {
                            if self.auth.subscriptionStatus == .subscribed {
                                Toggle("\(self.lockedOutText)", isOn: self.$isLocalAuthOn)
                                    .padding(.horizontal)
                                    .onReceive([self.isLocalAuthOn].publisher.first()) { (value) in
                                        print("New value is: \(value)")
                                        Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["faceID" : value])
                                    }
                            } else {
                                HStack {
                                    Text("Enable \(self.lockedOutText)")
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 20, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.contentShape(Rectangle())
                                .padding(.horizontal)
                                .onTapGesture {
                                    if self.auth.subscriptionStatus == .notSubscribed {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        self.openMenbership.toggle()
                                    }
                                }
                            }
                        }.padding(.vertical, 12.5)
                        .sheet(isPresented: self.$openMenbership, content: {
                            MembershipView()
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                                .navigationBarTitle("")
                        })
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    HStack(alignment: .center) {
                        Text("add an extra layer of security when you leave the app")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }.padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .onAppear() {
                        switch(LAContext().biometryType) {
                        case .none:
                            self.lockedOutText = "Face ID"
                        case .touchID:
                            self.lockedOutText = "Touch ID"
                        case .faceID:
                            self.lockedOutText = "Face ID"
                        @unknown default:
                            print("Face ID")
                        }
                    }
                    
                    Spacer()
                    FooterInformation()
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle("Privacy", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
