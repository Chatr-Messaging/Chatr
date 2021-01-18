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
    @State private var currentPosition: CGSize = .zero
    @State private var newPosition: CGSize = .zero
    @State private var privateUserID: Int = 0
    @State var groupOccUserAvatar: [String] = []
    @State private var openActionSheet: Bool = false
    @State private var openContactProfile: Bool = false
    @State private var openGroupProfile: Bool = false
    @State var openNewDialogID: Int = 0
    @State private var isAdmin: Bool = false
    @Binding var isOpen: Bool
    @Binding var activeView: CGSize
    @Binding var selectedDialogID: String

    var body: some View {
        //MARK: Main Dialog Cell
        HStack {
            //ZStack {
            if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "public" {
                ZStack {
                    WebImage(url: URL(string: (self.privateDialogContact.id != 0 ? self.privateDialogContact.avatar : PersistenceManager().getCubeProfileImage(usersID: self.connectyContact)) ?? ""))
                        .resizable()
                        .placeholder{ Image("empty-profile").resizable().frame(width: 55, height: 55, alignment: .center).scaledToFill() }
                        .indicator(.activity)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 55, height: 55, alignment: .center)
                        .offset(x: -5)
                        .shadow(color: Color.black.opacity(0.23), radius: 7, x: 0, y: 5)
                        .onTapGesture {
                            if isOpen {
                                if self.dialogModel.dialogType == "private" {
                                    self.openContactProfile.toggle()
                                } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                                    self.openGroupProfile.toggle()
                                }
                                if let connDia = self.auth.selectedConnectyDialog {
                                    connDia.sendUserStoppedTyping()
                                }
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.isOpen = true
                                self.selectedDialogID = self.dialogModel.id
                                UserDefaults.standard.set(true, forKey: "localOpen")
                                UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                                changeDialogRealmData().updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                            }
                        }
                    
                    if self.privateDialogContact.quickSnaps.count > 0 {
                        Circle()
                            .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 63, height: 63)
                            .offset(x: -5)
                            .foregroundColor(.clear)
                    }
                    
                    AlertIndicator(dialogModel: self.dialogModel)
                        .offset(x: -36, y: -27.5)
                        .opacity(self.isOpen ? 0 : 1)
                }
            } else if self.dialogModel.dialogType == "group" {
                ZStack {
                    ForEach(self.groupOccUserAvatar.indices, id: \.self) { id in
                        if id < 3 {
                            ZStack {
                                Circle()
                                    .frame(width: self.groupOccUserAvatar.count > 2 ? 31 : self.groupOccUserAvatar.count > 1 ? 34 : 55, height: self.groupOccUserAvatar.count > 2 ? 31 : self.groupOccUserAvatar.count > 1 ? 34 : 55, alignment: .center)
                                    .foregroundColor(Color("buttonColor"))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                
                                WebImage(url: URL(string: self.groupOccUserAvatar[id]))
                                    .resizable()
                                    .placeholder{ Image("empty-profile").resizable().frame(width: self.groupOccUserAvatar.count >= 3 ? 28 : self.groupOccUserAvatar.count == 2 ? 31 : 55, height: self.groupOccUserAvatar.count >= 3 ? 28 : self.groupOccUserAvatar.count == 2 ? 31 : 55, alignment: .center).scaledToFill() }
                                    .indicator(.activity)
                                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: self.groupOccUserAvatar.count >= 3 ? 28 : self.groupOccUserAvatar.count == 2 ? 31 : 55, height: self.groupOccUserAvatar.count >= 3 ? 28 : self.groupOccUserAvatar.count == 2 ? 31 : 55, alignment: .center)
                                
                                if id == 2 && self.dialogModel.occupentsID.count >= 5 {
                                    Circle()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(.black)
                                        .opacity(0.6)
                                    
                                    Text("+\(self.dialogModel.occupentsID.count - 2)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }.offset(x: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? -0 : (id == 1 ? -12 : (id == 2 ? 12 : 0))) : self.groupOccUserAvatar.count == 1 ? 0 : (id == 0 ? -12 : 10), y: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? -12 : (id == 1 ? 12 : (id == 2 ? 12 : 0))) : self.groupOccUserAvatar.count == 2 ? (id == 0 ? -8 : 8) : 0)
                            .offset(x: self.groupOccUserAvatar.count == 1 ? -5 : 0)
                            .padding(.trailing, self.groupOccUserAvatar.count == 1 ? 0 : 15)
                            .padding(.leading, self.groupOccUserAvatar.count == 1 ? 0 : 10)
                            .onTapGesture {
                                if isOpen {
                                    self.openGroupProfile.toggle()
                                    if let connDia = self.auth.selectedConnectyDialog {
                                        connDia.sendUserStoppedTyping()
                                    }
                                } else {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isOpen = true
                                    self.selectedDialogID = self.dialogModel.id
                                    UserDefaults.standard.set(true, forKey: "localOpen")
                                    UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                                    changeDialogRealmData().updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                                }
                            }.sheet(isPresented: self.$openGroupProfile, content: {
                                NavigationView {
                                    VisitGroupChannelView(dismissView: self.$openGroupProfile, openNewDialogID: self.$openNewDialogID, groupOccUserAvatar: self.groupOccUserAvatar, fromDialogCell: true, viewState: .fromContacts, dialogRelationship: .subscribed, dialogModel: self.dialogModel)
                                        .environmentObject(self.auth)
                                        .edgesIgnoringSafeArea(.all)
                                }
                            })
                        }
                    }
                    
                    AlertIndicator(dialogModel: self.dialogModel)
                        .offset(x: self.groupOccUserAvatar.count == 2 ? -37 : -34, y: -25)
                        .opacity(self.isOpen ? 0 : 1)
                }.padding(.vertical, self.groupOccUserAvatar.count == 2 ? 11 : 11.5)
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
                            .frame(width: .infinity)
                    }.offset(y: 2)
                    
                    
                    Spacer()
                    
                    HStack {
                        Text(self.dialogModel.isOpen ? "" : "\(self.dialogModel.lastMessageDate.getElapsedInterval(lastMsg: "now"))")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .opacity(dialogModel.isOpen ? 0 : 1)
                            
                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.bold))
                            .foregroundColor(.secondary)
                            .frame(width: self.dialogModel.isOpen ? 0 : 7, height: 10, alignment: .center)
                            .rotationEffect(.degrees(dialogModel.isOpen ? 90 : 0))
                            .opacity(dialogModel.isOpen ? 0 : 1)
                    }
                }.frame(height: 25)
                .offset(x: self.groupOccUserAvatar.count == 2 ? -4 : -2)
                
                HStack(spacing: 5) {
                    Text((self.dialogModel.isOpen ? self.dialogModel.dialogType == "private" ? (self.privateDialogContact.isOnline ? "online now" : "last online \(self.privateDialogContact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago") : "\(self.dialogModel.occupentsID.count) members \(self.auth.onlineCount != 0 ? "•" : "")" : dialogModel.lastMessage))
                        .font(self.dialogModel.isOpen ? .footnote : .subheadline)
                        .fontWeight(.regular)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .offset(x: -2, y: -6)
                        .frame(width: .infinity)
                        .foregroundColor(Color.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(self.auth.onlineCount != 0 && self.isOpen && (self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public") ? "\(self.auth.onlineCount) online" : "")
                        .font(.footnote)
                        .fontWeight(.regular)
                        .lineLimit(1)
                        .frame(width: .infinity)
                        .multilineTextAlignment(.leading)
                        .offset(x: -4, y: -6)
                        .foregroundColor(Color.green)
                }
            }.onTapGesture {
                if isOpen {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    if self.dialogModel.dialogType == "private" {
                        self.openContactProfile.toggle()
                    } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                        self.openGroupProfile.toggle()
                    }
                    if let connDia = self.auth.selectedConnectyDialog {
                        connDia.sendUserStoppedTyping()
                    }
                } else {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.isOpen = true
                    self.selectedDialogID = self.dialogModel.id
                    UserDefaults.standard.set(true, forKey: "localOpen")
                    UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                    changeDialogRealmData().updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                }
            }

            HStack() {
                Button(action: {
                    self.openActionSheet.toggle()
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
                            self.isOpen = false
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
                            self.openActionSheet = false

                            if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "group" {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                                    changeDialogRealmData().deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false)
                                    print("done deleting dialog: \(self.dialogModel.id)")
                                }
                            } else if self.dialogModel.dialogType == "public" {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
                                    changeDialogRealmData().unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id)
                                    print("done deleting PUBLIC dialog: \(self.dialogModel.id)")
                                }
                            }
                        }),
                        .cancel()
                    ])
                }
                
                Button(action: {
                    self.isOpen = false
                    UserDefaults.standard.set(false, forKey: "localOpen")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
                        changeDialogRealmData().fetchDialogs(completion: { _ in })
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
            
        }.contentShape(Rectangle())
        .padding(.trailing, self.dialogModel.isOpen ? 20 : 5)
        .padding(.leading)
        .padding(.vertical, self.privateDialogContact.quickSnaps.count > 0 ? 4 : 8)
        .background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .onAppear() {
            if self.dialogModel.dialogType == "private" {
                for occ in self.dialogModel.occupentsID {
                    if occ != UserDefaults.standard.integer(forKey: "currentUserID") {
                        self.privateUserID = occ
                        break
                    }
                }
                
                do {
                    let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.privateUserID) {
                        //MARK: COME BACK TO THIS** Crashes below
                        //changeContactsRealmData().observeFirebaseContact(contactID: foundContact.id)
                        self.privateDialogContact = foundContact
                        self.connectyContact.id = UInt(foundContact.id)
                        if self.privateDialogContact.avatar == "" || self.privateDialogContact.id == 0 && !Session.current.tokenHasExpired {
                            self.pullPrivateAvatatr()
                        } else if Session.current.tokenHasExpired {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                                self.pullPrivateAvatatr()
                            }
                        }
                    } else {
                        if !Session.current.tokenHasExpired {
                            self.pullPrivateAvatatr()
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                                self.pullPrivateAvatatr()
                            }
                        }
                    }
                } catch { }
            } else if self.dialogModel.dialogType == "group" && !Session.current.tokenHasExpired {
                self.pullGroupAvatar()
            } else {
                print("Chat dialog can not load bcause token has expired!")
                if self.dialogModel.dialogType == "group" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.pullGroupAvatar()
                    }
                }
            }
        }
    }
    
    func pullGroupAvatar() {
        for admin in self.dialogModel.adminID {
            if admin == UserDefaults.standard.integer(forKey: "currentUserID") {
                self.isAdmin = true
                break
            }
        }
        
        self.groupOccUserAvatar.removeAll()
        print("the occ count for diaog: \(self.dialogModel.fullName) is: \(self.dialogModel.occupentsID.count)")
        for occ in self.dialogModel.occupentsID {
            if self.groupOccUserAvatar.count != 3 {
                if occ != UserDefaults.standard.integer(forKey: "currentUserID") {
                    do {
                        let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: occ) {
                            if foundContact.avatar == "" {
                                Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                    for i in users {
                                        self.groupOccUserAvatar.append(PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
                                        print("found group connecty countactttt: \(String(describing: PersistenceManager().getCubeProfileImage(usersID: i) ?? ""))")
                                        if self.groupOccUserAvatar.count >= 3 { break }
                                    }
                                })
                            } else {
                                self.groupOccUserAvatar.append(foundContact.avatar)
                                print("group occ user av #: \(self.groupOccUserAvatar.count) and now: \(foundContact.avatar)")
                                if self.groupOccUserAvatar.count >= 3 { break }
                            }
                        } else {
                            Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                for i in users {
                                    self.groupOccUserAvatar.append(PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
                                    print("found group connecty countact: \(String(describing: PersistenceManager().getCubeProfileImage(usersID: i) ?? ""))")
                                    if self.groupOccUserAvatar.count >= 3 { break }
                                }
                            })
                        }
                    } catch { }
                }
            } else { break }
        }
        print("group occ count: \(self.groupOccUserAvatar.count)")
    }
    
    func pullPrivateAvatatr() {
        print("contact not in Realm... view did load")
        Request.users(withIDs: [NSNumber(value: self.privateUserID)], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
            for user in users {
                if user.id == self.privateUserID {
                    self.connectyContact = user
                    changeContactsRealmData().observeFirebaseContactReturn(contactID: Int(user.id), completion: { firebaseContact in
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

