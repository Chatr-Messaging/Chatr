//
//  RingtoneView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import SDWebImageSwiftUI

// MARK: Ringtone Section
struct contactRequestView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var selectedNewDialog: Int
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: true) {
                //MARK: Requests Section
                if self.auth.profile.results.first?.contactRequests.count != 0 {
                    HStack {
                        Text("CONTACT REQUESTS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                            .padding(.top, 120)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    LazyVStack(spacing: 0) {
                        ForEach(self.auth.profile.results.first!.contactRequests.indices, id: \.self) { contactRequestID in
                            ContactRequestCell(dismissView: self.$dismissView, selectedNewDialog: self.$selectedNewDialog, contactID: Int(self.auth.profile.results.first!.contactRequests[contactRequestID]), contactRelationship: .pendingRequestForYou)
                                .environmentObject(self.auth)
                            
                            if self.auth.profile.results.first?.contactRequests.last != contactRequestID {
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 40)
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, Chat.instance.contactList?.pendingApproval.count != 0 ? 25 : 70)
                    .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                }
                
                //MARK: EMPTY Requests Section
                if self.auth.profile.results.first?.contactRequests.count == 0 && Chat.instance.contactList?.pendingApproval.count == 0 {
                    VStack(alignment: .center) {
                        VStack {
                            HStack(alignment: .center) {
                                Text("no contact requests...")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.regular)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }.padding(.horizontal)
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 25)
                    .padding(.top, 120)
                }
                
                if Chat.instance.contactList?.pendingApproval.count != 0 {
                    HStack {
                        Text("PENDING REQUESTS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.top, (self.auth.profile.results.first?.contactRequests.count ?? 0) > 0 ? 0 : 120)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    LazyVStack(spacing: 0) {
                        ForEach(Chat.instance.contactList?.pendingApproval ?? [], id: \.self) { contactRequest in
                            ContactRequestCell(dismissView: self.$dismissView, selectedNewDialog: self.$selectedNewDialog, contactID: Int(contactRequest.userID), contactRelationship: .pendingRequest)
                                .environmentObject(self.auth)
                            
                            if Chat.instance.contactList?.pendingApproval.last != contactRequest {
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 40)
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 70)
                    .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                }
                
                FooterInformation()
            }
        }.navigationBarTitle("Requests")
        .background(Color("bgColor"))
        .edgesIgnoringSafeArea(.all)
    }
}
