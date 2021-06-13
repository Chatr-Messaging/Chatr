//
//  PublicActionSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/18/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube

struct PublicActionSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dialogRelationship: visitDialogRelationship
    @Binding var dialogModel: DialogStruct
    @Binding var currentUserIsPowerful: Bool
    @Binding var dismissView: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.dismissView.toggle()
            }) {
                HStack {
                    Image("ChatBubble")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 26)

                    if self.dialogRelationship != .notSubscribed {
                        Text("Message")
                            .font(.none)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }.padding(.all, self.dialogRelationship != .notSubscribed ? 12 : 0)
                .padding(.horizontal, self.dialogRelationship != .notSubscribed ? 5 : 0)
                .background(RoundedRectangle(cornerRadius: 15, style: .circular).frame(minWidth: 54).frame(height: 54).foregroundColor(Constants.baseBlue).shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 6))
            }.buttonStyle(ClickButtonStyle())

            if self.dialogRelationship == .notSubscribed {
                Button(action: {
                    Request.subscribeToPublicDialog(withID: self.dialogModel.id, successBlock: { dialogz in
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        self.dialogRelationship = .subscribed
                        changeDialogRealmData.shared.insertDialogs([dialogz], completion: {
                            changeDialogRealmData.shared.observeFirebaseDialogReturn(dialogModel: self.dialogModel, completion: { _,_   in
                                self.auth.sendPushNoti(userIDs: [NSNumber(value: self.dialogModel.owner)], title: "\(self.dialogModel.fullName) Joined", message: "\(self.auth.profile.results.first?.fullName ?? "No Name") joined your public chat \(self.dialogModel.fullName)")
                            })
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.dialogRelationship = .error
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 24, alignment: .center)
                            .foregroundColor(.white)
                            .padding(2.5)
                        
                        Text("Join Group")
                            .font(.none)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }.padding(.all, 12)
                    .padding(.horizontal, 5)
                    .background(self.dialogRelationship == .error ? Color("alertRed") : Constants.baseBlue)
                    .cornerRadius(12.5)
                    .shadow(color: Color.blue.opacity(0.30), radius: 8, x: 0, y: 8)
                }.buttonStyle(ClickButtonStyle())
            }
            
            Menu {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }) {
                    Label("Noti is ON", systemImage: "square.and.arrow.down")
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }) {
                    Label("Share Group", systemImage: "square.and.arrow.down")
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }) {
                    Label("Report Group", systemImage: "square.and.arrow.down")
                        .foregroundColor(.red)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.primary)
                    .frame(width: 38, height: 26)
                    .background(RoundedRectangle(cornerRadius: 15, style: .circular).frame(width: 54, height: 54).foregroundColor(Color("buttonColor")).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6))
            }.buttonStyle(ClickButtonStyle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }.padding(.bottom)
    }
}
