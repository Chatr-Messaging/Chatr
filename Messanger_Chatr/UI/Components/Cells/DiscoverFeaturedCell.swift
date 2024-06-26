//
//  DiscoverFeaturedCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import SDWebImageSwiftUI

struct DiscoverFeaturedCell: View, Identifiable {
    @EnvironmentObject var auth: AuthModel
    let id = UUID()
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @Binding var openNewDialogID: Int
    @State var dialogModel: PublicDialogModel = PublicDialogModel()
    @State private var actionState: Bool = false
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var isMember: Bool = false
    @State var isMoreOpen: Bool = false
    @State var shareGroup: Bool = false
    @State var selectedContact: [Int] = []
    @State var newDialogID: String = ""

    var body: some View {
        ZStack {
            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all), isActive: self.$actionState, label: {
                EmptyView()
            })
            
            NavigationLink(destination: ShareProfileView(dimissView: self.$dismissView, contactID: 0, dialogID: self.dialogModel.id ?? "", contactFullName: self.dialogModel.name ?? "", contactAvatar: self.dialogModel.avatar ?? "", isPublicDialog: true, totalMembers: self.dialogModel.memberCount ?? 0).environmentObject(self.auth), isActive: self.$shareGroup, label: {
                EmptyView()
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.actionState.toggle()
            }) {
                ZStack(alignment: .top) {
                    WebImage(url: URL(string: self.dialogModel.coverPhoto ?? ""))
                        .resizable()
                        .placeholder{ Image(systemName: "photo.on.rectangle.angled").resizable().frame(width: 30, height: 27, alignment: .center).scaledToFill().offset(y: -18) }
                        .indicator(.activity)
                        .frame(width: Constants.screenWidth * 0.68 - 30, height: 140)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12.5)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)

                    VStack(alignment: .center, spacing: 0) {
                        WebImage(url: URL(string: self.dialogModel.avatar ?? ""))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 80, height: 80, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .background(Color("buttonColor"))
                            .cornerRadius(58 / 4)
                            .padding(.bottom, 5)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(self.dialogModel.name ?? "")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(self.dialogModel.memberCount ?? 0 > 1 ? "\(self.dialogModel.memberCount ?? 0) members" : "become the first member!")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .multilineTextAlignment(.center)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            
                            Text(self.dialogModel.description ?? "")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .frame(height: 60)
                            
                            Spacer()
                            if !self.isMember {
                                Button(action: {
                                    Request.subscribeToPublicDialog(withID: self.dialogModel.id ?? "", successBlock: { dialogz in
                                        self.auth.dialogs.toggleFirebaseMemberCount(dialogId: dialogz.id ?? "", isJoining: true, totalCount: Int(dialogz.occupantsCount), onSuccess: { _ in
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            withAnimation {
                                                self.isMember = true
                                            }
                                            self.auth.dialogs.insertDialogs([dialogz], completion: {
                                                self.auth.dialogs.updateDialogDelete(isDelete: false, dialogID: dialogz.id ?? "")
                                                self.auth.sendPushNoti(userIDs: [NSNumber(value: dialogz.userID)], title: "\(self.auth.profile.results.first?.fullName ?? "New Member") joined \(dialogz.name ?? "your dialog")", message: "\(self.auth.profile.results.first?.fullName ?? "New Member") has joined your channel \(dialogz.name ?? "no name")")
                                            })
                                        }, onError: { _ in
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                            self.isMember = false
                                        })
                                    }) { (error) in
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        self.isMember = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18, alignment: .center)
                                            .foregroundColor(.white)
                                        
                                        Text("Join Group")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.white)
                                    }.frame(width: Constants.screenWidth * 0.60 - 50, height: 36, alignment: .center)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                }.buttonStyle(ClickButtonStyle())
                                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2.5)
                                .padding(.bottom, 4)
                            } else {
                                HStack(spacing: 5) {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.shareGroup.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: "paperplane.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 16, height: 16, alignment: .center)
                                                .foregroundColor(.blue)
                                            
                                            Text("Share Channel")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Color.blue)
                                        }.frame(width: Constants.screenWidth * 0.60 - 86, height: 36, alignment: .center)
                                        .background(Color("buttonColor_darker"))
                                        .cornerRadius(8)
                                    }.buttonStyle(ClickButtonStyle())
                                    .padding(.bottom, 4)

                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.isMoreOpen.toggle()
                                    }) {
                                        ZStack {
                                            Image(systemName: "ellipsis")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 16, height: 16, alignment: .center)
                                                .foregroundColor(.primary)
                                        }.frame(width: 36, height: 36, alignment: .center)
                                        .background(Color("buttonColor_darker"))
                                        .cornerRadius(8)
                                    }.buttonStyle(ClickButtonStyle())
                                    .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .padding(.top, 75)
                    .padding()
                }
                .background(Color("buttonColor"))
                .frame(minHeight: 340, maxHeight: 360)
                .cornerRadius(20)
                .padding(.horizontal, 15)
            }.buttonStyle(ClickMiniButtonStyle())
            .actionSheet(isPresented: $isMoreOpen) {
                ActionSheet(title: Text("\(self.dialogModel.name ?? "no name")'s Options:"), message: nil, buttons: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? [
                        .default(Text("View Details")) {
                            self.actionState.toggle()
                        },
                        .cancel()
                    ] : [
                        .default(Text("View Details")) {
                            self.actionState.toggle()
                        },
                        .destructive(Text(self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? "Destroy Channel" : "Leave Channel")) {
                            self.isMember = false
                    self.auth.dialogs.unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id ?? "", isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID"))
                        },
                        .cancel()
                    ])
            }
            .onAppear() {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: self.dialogModel.id ?? ""), !foundDialog.isDeleted {
                        self.isMember = true
                    }
                } catch { }
            }
        }
    }
    
    func dialogDetails() -> some View {
        VisitGroupChannelView(dismissView: self.$dismissView, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, viewState: .fromDiscover, dialogRelationship: self.isMember ? .subscribed : .notSubscribed, publicDialogModel: self.dialogModel)
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
