//
//  PublicDialogDiscoverCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct PublicDialogDiscoverCell: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @State var dialogData: PublicDialogModel
    @State var isLast: Bool = false
    @State private var actionState: Bool = false
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var openNewDialogID: Int = 0
    @State var isJoined: Bool = false
    @State var isMember: Bool = false
    var sendDia: DialogStruct = DialogStruct()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all), isActive: self.$actionState, label: {
                EmptyView()
            })

            Button(action: {
                print("pushing to the next: \(String(describing: self.dialogData.name)) && \(String(describing: self.dialogData.id))")
                self.actionState.toggle()
            }) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        
                        WebImage(url: URL(string: self.dialogData.avatar ?? ""))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 62, height: 62, alignment: .center).scaledToFill().cornerRadius(54 / 4) }
                            .indicator(.activity)
                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .scaledToFill()
                            .frame(width: 62, height: 62)
                            .background(Color("buttonColor"))
                            .cornerRadius(54 / 4)
                            .clipped()
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(self.dialogData.name ?? "no name")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(self.dialogData.memberCount ?? 0) members")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Text(self.dialogData.description ?? "")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .padding(.top, 4)
                        }

                        Spacer()
                        
                        if !self.isMember {
                            Button(action: {
                                Request.subscribeToPublicDialog(withID: self.dialogData.id ?? "", successBlock: { dialogz in
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.isJoined = true
                                    changeDialogRealmData.shared.insertDialogs([dialogz], completion: {
                                        self.auth.sendPushNoti(userIDs: [NSNumber(value: dialogz.userID)], title: "\(dialogz.name ?? "no name") Joined", message: "\(self.auth.profile.results.first?.fullName ?? "No Name") joined your public chat \(dialogz.name ?? "no name")")
                                    })
                                }) { (error) in
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }) {
                                Text(self.isJoined ? "JOINED" : "JOIN")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(self.isJoined ? Color.secondary : Color.blue)
                                    .frame(width: 55, height: 30, alignment: .center)
                                    .background(Color("buttonColor_darker"))
                            }.buttonStyle(ClickButtonStyle())
                            .cornerRadius(8)
                        }

                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.semibold))
                            .scaledToFit()
                            .frame(width: 7, height: 15, alignment: .center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    
                    Divider()
                        .frame(width: Constants.screenWidth - 80)
                        .offset(x: 45)
                        .opacity(!self.isLast ? 1 : 0)
                }
            }.buttonStyle(changeBGButtonStyle())
            .onAppear() {
                guard self.sendDia.id == "" else {
                    return
                }

                self.sendDia.id = self.dialogData.id ?? ""
                self.sendDia.dialogType = "public"
                self.sendDia.fullName = self.dialogData.name ?? ""
                self.sendDia.bio = self.dialogData.description ?? ""
                self.sendDia.avatar = self.dialogData.avatar ?? ""
                self.sendDia.coverPhoto = self.dialogData.coverPhoto ?? ""
                
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogData.id ?? ""), !foundDialog.isDeleted {
                        self.isMember = true
                    }
                } catch { }
            }
        }.simultaneousGesture(TapGesture()
                                .onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                })
    }
    
    func dialogDetails() -> some View {
        VisitGroupChannelView(dismissView: self.$dismissView, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, fromDialogCell: false, viewState: .fromDynamicLink, dialogRelationship: self.isMember || self.isJoined ? .subscribed : .notSubscribed, dialogModel: self.sendDia)
            .environmentObject(self.auth)
            .edgesIgnoringSafeArea(.all)
            .navigationBarItems(trailing:
                            Button(action: {
                                self.isEditGroupOpen.toggle()
                            }) {
                                Text("Edit")
                                    .foregroundColor(.blue)
                                    .opacity(self.canEditGroup ? 1 : 0)
                            }.disabled(self.canEditGroup ? false : true))
    }
}
