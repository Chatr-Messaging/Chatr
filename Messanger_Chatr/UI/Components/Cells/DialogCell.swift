//
//  File.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 4/5/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI
import SDWebImageSwiftUI
import RealmSwift
import ConnectyCube

struct DialogCell: View {
    @EnvironmentObject var auth: AuthModel
    @State var dialogModel: DialogStruct = DialogStruct()
    @State var privateDialogContact: ContactStruct = ContactStruct()
    @State var connectyContact: User = User()
    @State var groupOccUserAvatar: [String] = []
    @State private var openActionSheet: Bool = false
    @State private var openContactProfile: Bool = false
    @State private var openGroupProfile: Bool = false
    @State var openNewDialogID: Int = 0
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @Binding var isOpen: Bool
    @Binding var activeView: CGSize
    @Binding var selectedDialogID: String
    @Binding var showPinDetails: String

    var body: some View {
        //MARK: Main Dialog Cell
        HStack {
            ZStack(alignment: .center) {
                if self.privateDialogContact.quickSnaps.count > 0 {
                    Circle()
                        .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 63, height: 63)
                        .offset(x: -5)
                        .foregroundColor(.clear)
                }

                if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "public" || self.dialogModel.dialogType == "broadcast" {
                    ZStack {
                        WebImage(url: URL(string: self.dialogModel.dialogType == "public" ? (self.dialogModel.avatar) : (self.privateDialogContact.id != 0 ? self.privateDialogContact.avatar : PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact)) ?? ""))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 55, height: 55, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .scaledToFill()
                            .frame(width: 55, height: 55, alignment: .center)
                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                            .cornerRadius(self.dialogModel.dialogType == "public" ? 12.5 : 27.5)
                            .offset(x: self.dialogModel.dialogType == "public" ? -7.5 : -5)
                            .shadow(color: Color.black.opacity(0.23), radius: 7, x: 0, y: 5)
                            .onTapGesture {
                                if isOpen {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    if self.dialogModel.dialogType == "private" {
                                        self.openContactProfile.toggle()
                                    } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                                        self.openGroupProfile.toggle()
                                    }
                                } else {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isOpen = true
                                    self.selectedDialogID = self.dialogModel.id
                                    UserDefaults.standard.set(true, forKey: "localOpen")
                                    UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                                    changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                                }
                            }
                        
                        AlertIndicator(dialogModel: self.dialogModel)
                            .offset(x: -36, y: -27.5)
                            .opacity(self.isOpen ? 0 : 1)
                    }
                } else if self.dialogModel.dialogType == "group" {
                    ZStack {
                        Circle()
                            .frame(width: 55, height: 1, alignment: .center)
                            .foregroundColor(.clear)

                        ForEach(self.groupOccUserAvatar.indices, id: \.self) { id in
                            if id < 3 {
                                ZStack {
                                    WebImage(url: URL(string: self.groupOccUserAvatar[id]))
                                        .resizable()
                                        .placeholder{ Image("empty-profile").resizable().frame(width: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, height: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, alignment: .center).scaledToFill() }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, height: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, alignment: .center)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                    
                                    if id == 2 && self.dialogModel.occupentsID.count >= 5 {
                                        Circle()
                                            .frame(width: 31, height: 31)
                                            .foregroundColor(.black)
                                            .opacity(0.4)
                                        
                                        Text("+\(self.dialogModel.occupentsID.count - 2)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                }.offset(x: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? 0 : (id == 1 ? -12 : (id == 2 ? 12 : 0))) : self.groupOccUserAvatar.count == 1 ? 0 : (id == 0 ? -12 : 10), y: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? -12 : (id == 1 ? 12 : (id == 2 ? 12 : 0))) : self.groupOccUserAvatar.count == 2 ? (id == 0 ? -8 : 8) : 0)
                                .offset(x: self.groupOccUserAvatar.count == 1 ? -5 : 0)
                                .padding(.trailing, self.groupOccUserAvatar.count == 1 ? 0 : 15)
                                .padding(.leading, self.groupOccUserAvatar.count == 1 ? 0 : 10)
                                .onTapGesture {
                                    if isOpen {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        if self.dialogModel.dialogType == "private" {
                                            self.openContactProfile.toggle()
                                        } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                                            self.openGroupProfile.toggle()
                                        }
                                    } else {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        withAnimation(Animation.easeOut(duration: 0.6)) {
                                            self.isOpen = true
                                        }
                                        UserDefaults.standard.set(true, forKey: "localOpen")
                                        UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")

                                        self.selectedDialogID = self.dialogModel.id
                                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                                    }
                                }
                            }
                        }

                        AlertIndicator(dialogModel: self.dialogModel)
                            .offset(x: self.groupOccUserAvatar.count == 2 ? -37 : -34, y: -25)
                            .opacity(self.isOpen ? 0 : 1)
                    }.padding(.vertical, self.groupOccUserAvatar.count == 2 ? 11 : 12)
                }
            }
            
            VStack(alignment: .leading) {
                HStack {
                    HStack(spacing: 5) {
                        if privateDialogContact.isPremium {
                            Image(systemName: "checkmark.seal")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.medium))
                                .frame(width: 16, height: 16, alignment: .center)
                                .foregroundColor(Color("main_blue"))
                        }
                        
                        Text(self.dialogModel.fullName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primary)
                            .lineLimit(1)
                    }.offset(y: 2)
                    
                    Spacer()
                    HStack {
                        let timeAgo = self.dialogModel.lastMessageDate.getElapsedInterval(lastMsg: "now")

                        Text(self.dialogModel.isOpen || timeAgo == "20 yrs" ? "" : "\(timeAgo)")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .opacity(dialogModel.isOpen ? 0 : 1)
                            
                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.bold))
                            .foregroundColor(.secondary)
                            .frame(width: self.dialogModel.isOpen ? 0 : 7, height: self.dialogModel.isOpen ? 0 : 10, alignment: .center)
                            .opacity(dialogModel.isOpen ? 0 : 1)
                    }
                }.offset(x: self.groupOccUserAvatar.count == 2 ? -4 : -2)

                HStack(spacing: 5) {
                    Text((self.dialogModel.isOpen ? (self.dialogModel.dialogType == "private" ? (self.privateDialogContact.isOnline ? "online now" : "last online \(self.privateDialogContact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago") : "\(self.dialogModel.occupentsID.count)" + (self.dialogModel.dialogType == "public" ? " members" : " people") + (self.dialogModel.onlineUserCount != 0 ? " " : "")) : dialogModel.lastMessage))
                        .font(self.dialogModel.isOpen ? .footnote : .subheadline)
                        .fontWeight(.regular)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .offset(x: -2, y: -4)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    if let dialog = self.auth.selectedConnectyDialog, self.isOpen && (self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public") {
                        Text(!dialog.isJoined() ? "joining convo..." : (self.dialogModel.onlineUserCount > 1 ? "\(self.dialogModel.onlineUserCount) online" : ""))
                            .font(.footnote)
                            .fontWeight(.regular)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                            .offset(x: -4, y: -4)
                            .foregroundColor(self.dialogModel.isOpen ? .gray : dialog.isJoined() && self.dialogModel.onlineUserCount > 0 ? .green : .gray)
                    }
                }
            }.onTapGesture {
                if isOpen {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    if self.dialogModel.dialogType == "private" {
                        self.openContactProfile.toggle()
                    } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                        self.openGroupProfile.toggle()
                    }
                } else {
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                    self.isOpen = true
                    self.selectedDialogID = self.dialogModel.id

                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    UserDefaults.standard.set(true, forKey: "localOpen")
                    UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                }
            }.sheet(isPresented: self.$openGroupProfile, content: {
                NavigationView {
                    VisitGroupChannelView(dismissView: self.$openGroupProfile, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, groupOccUserAvatar: self.groupOccUserAvatar, fromDialogCell: true, viewState: .fromContacts, dialogRelationship: .subscribed, dialogModel: self.dialogModel)
                        .environmentObject(self.auth)
                        .edgesIgnoringSafeArea(.all)
                        .navigationBarItems(leading:
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        withAnimation {
                                            self.openGroupProfile.toggle()
                                        }
                                    }) {
                                        Text("Done")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                    }, trailing:
                                        Button(action: {
                                            self.isEditGroupOpen.toggle()
                                        }) {
                                            Text("Edit")
                                                .foregroundColor(.blue)
                                                .opacity(self.canEditGroup ? 1 : 0)
                                        }.disabled(self.canEditGroup ? false : true))
                }
            })

            HStack() {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.openActionSheet.toggle()
                    UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                }, label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 25, alignment: .center)
                        .foregroundColor(.secondary)
                        .font(Font.title.weight(.light))
                }).padding(.horizontal, self.dialogModel.isOpen ? 5 : 0)
                .disabled(self.dialogModel.isOpen ? false : true)
                .opacity(self.dialogModel.isOpen ? 1 : 0)
                .sheet(isPresented: self.$openContactProfile, content: {
                    NavigationView {
                        VisitContactView(fromDialogCell: true, newMessage: self.$openNewDialogID, dismissView: self.$openContactProfile, viewState: .fromSearch, contact: self.privateDialogContact, connectyContact: self.connectyContact)
                            .environmentObject(self.auth)
                            .edgesIgnoringSafeArea(.all)
                    }
                })
                .actionSheet(isPresented: $openActionSheet) {
                    ActionSheet(title: Text("\(self.dialogModel.fullName)'s Options:"), message: nil, buttons: [
                        .default(Text(self.dialogModel.dialogType == "private" ? "View Profile" : "View Details")) {
                            if self.dialogModel.dialogType == "private" {
                                self.openContactProfile.toggle()
                            } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                                self.openGroupProfile.toggle()
                            }
                        },
                        .destructive(Text(self.dialogModel.dialogType == "private" ? "Delete Dialog" : (self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? "Destroy Group" : "Leave Group")), action: {
                            changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)

                            self.isOpen = false
                            self.openActionSheet = false
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "group" {
                                    changeDialogRealmData.shared.deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false)
                                } else if self.dialogModel.dialogType == "public" {
                                    changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id)
                                }
                            }
                        }),
                        .cancel()
                    ])
                }
                
                Button(action: {
                    self.isOpen = false
                    UserDefaults.standard.set(false, forKey: "localOpen")
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        changeDialogRealmData.shared.fetchDialogs(completion: { _ in })
                    }
                }, label: {
                    Image(systemName: "chevron.down.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25, alignment: .center)
                        .foregroundColor(.secondary)
                        .font(Font.title.weight(.light))
                }).disabled(self.dialogModel.isOpen ? false : true)
                .opacity(self.dialogModel.isOpen ? 1 : 0)
            }.frame(width: self.dialogModel.isOpen ? 20 : 0)
            .padding(.trailing, self.dialogModel.isOpen ? 20 : 0)
            .opacity(self.isOpen ? 1 : 0)
        }.padding(.trailing, self.dialogModel.isOpen ? 20 : 5)
        .padding(.leading)
        .padding(.vertical, self.privateDialogContact.quickSnaps.count > 0 ? 4 : 8)
        .background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.dialogModel.dialogType == "private" {
                    for occ in self.dialogModel.occupentsID {
                        if occ != UserDefaults.standard.integer(forKey: "currentUserID") {
                            self.privateDialogContact.id = occ
                            break
                        }
                    }

                    do {
                        let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.privateDialogContact.id) {
                            self.privateDialogContact = foundContact
                            self.connectyContact.id = UInt(foundContact.id)
                            if self.privateDialogContact.avatar == "" || self.privateDialogContact.id == 0 && !Session.current.tokenHasExpired {
                                self.pullPrivateAvatatr()
                            } else if Session.current.tokenHasExpired {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    self.pullPrivateAvatatr()
                                }
                            }
                        } else {
                            if !Session.current.tokenHasExpired {
                                self.pullPrivateAvatatr()
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    self.pullPrivateAvatatr()
                                }
                            }
                        }
                    } catch { }
                } else if self.dialogModel.dialogType == "group" && !Session.current.tokenHasExpired {
                    self.pullGroupAvatar()
                } else {
                    if self.dialogModel.dialogType == "group" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.pullGroupAvatar()
                        }
                    }
                }
            }
        }
    }
    
    func pullGroupAvatar() {
        self.groupOccUserAvatar.removeAll()

        for occ in self.dialogModel.occupentsID {
            guard self.groupOccUserAvatar.count < 3 else {
                return
            }
            
            if occ != UserDefaults.standard.integer(forKey: "currentUserID"){
                do {
                    let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: occ) {
                        if foundContact.avatar == "" {
                            Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                for i in users {
                                    self.groupOccUserAvatar.append(PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
                                    if self.groupOccUserAvatar.count >= 3 { return }
                                }
                            })
                        } else {
                            self.groupOccUserAvatar.append(foundContact.avatar)
                        }
                    } else {
                        Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            for i in users {
                                self.groupOccUserAvatar.append(PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
                                if self.groupOccUserAvatar.count >= 3 { return }
                            }
                        })
                    }
                } catch { }
            }
        }
    }
    
    func pullPrivateAvatatr() {
        Request.users(withIDs: [NSNumber(value: self.privateDialogContact.id)], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
            for user in users {
                if user.id == self.privateDialogContact.id {
                    self.connectyContact = user
                    changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: Int(user.id), completion: { firebaseContact in
                        let newContact = ContactStruct()
                        newContact.id = Int(self.connectyContact.id)
                        newContact.fullName = self.connectyContact.fullName ?? ""
                        newContact.phoneNumber = self.connectyContact.phone ?? ""
                        newContact.lastOnline = self.connectyContact.lastRequestAt ?? Date()
                        newContact.createdAccount = self.connectyContact.createdAt ?? Date()
                        newContact.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact) ?? ""
                        newContact.bio = firebaseContact.bio
                        newContact.facebook = firebaseContact.facebook
                        newContact.twitter = firebaseContact.twitter
                        newContact.instagramAccessToken = firebaseContact.instagramAccessToken
                        newContact.instagramId = firebaseContact.instagramId
                        newContact.isPremium = firebaseContact.isPremium
                        newContact.emailAddress = self.connectyContact.email ?? "empty email address"
                        newContact.website = self.connectyContact.website ?? "empty website"
                        newContact.isInfoPrivate = firebaseContact.isInfoPrivate
                        newContact.isMessagingPrivate = firebaseContact.isMessagingPrivate
                        
                        self.privateDialogContact = newContact
                    })
                    return
                }
            }
        })
    }
}

