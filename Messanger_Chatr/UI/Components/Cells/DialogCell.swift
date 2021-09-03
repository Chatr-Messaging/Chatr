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
    @State var isJoining: Bool = true
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
                        if self.dialogModel.avatar != "" || self.privateDialogContact.avatar != "" {
                            WebImage(url: URL(string: self.dialogModel.dialogType == "public" ? (self.dialogModel.avatar) : (self.privateDialogContact.id != 0 ? self.privateDialogContact.avatar : self.connectyContact.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact)) ?? ""))
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
                                        UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                                        UserDefaults.standard.set(true, forKey: "localOpen")
                                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                                    }
                                }
                        
                        } else {
                            RoundedRectangle(cornerRadius: self.dialogModel.dialogType == "public" ? 12.5 : 27.5)
                                .frame(width: 55, height: 55, alignment: .center)
                                .foregroundColor(Color("bgColor"))
                                .shadow(color: Color.black.opacity(0.23), radius: 7, x: 0, y: 5)
                                .offset(x: self.dialogModel.dialogType == "public" ? -7.5 : -5)

                            Text("".firstLeters(text: self.dialogModel.dialogType == "public" ? self.dialogModel.fullName : self.privateDialogContact.id != 0 ? self.privateDialogContact.fullName : "??"))
                                .font(.system(size: 28))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .offset(x: self.dialogModel.dialogType == "public" ? -7.5 : -5)
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
                                        .frame(width: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, height: self.groupOccUserAvatar.count >= 3 ? 31 : self.groupOccUserAvatar.count == 2 ? 34 : 55, alignment: .center)
                                        .clipShape(Circle())
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
                                        UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                                        UserDefaults.standard.set(true, forKey: "localOpen")

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
                    Text((self.dialogModel.isOpen ? (self.dialogModel.dialogType == "private" ? (self.privateDialogContact.isOnline ? "online now" : "last online \(self.privateDialogContact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago") : (self.dialogModel.dialogType == "public" ? "\(self.dialogModel.publicMemberCount) members" : "\(self.dialogModel.occupentsID.count) contacts") + (self.dialogModel.onlineUserCount != 0 ? " " : "")) : dialogModel.lastMessage))
                        .font(self.dialogModel.isOpen ? .footnote : .subheadline)
                        .fontWeight(.regular)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .offset(x: -2, y: -4)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)

                    if let dialog = self.auth.selectedConnectyDialog, dialog.id != "", self.isOpen, (self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public"), Chat.instance.isConnected {
                        if self.isJoining {
                            Text("joining chat...")
                                .font(.footnote)
                                .fontWeight(.regular)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .offset(x: -4, y: -4)
                                .foregroundColor(.gray)
                        } else if self.dialogModel.onlineUserCount > 1 {
                            Text("\(self.dialogModel.onlineUserCount) online")
                                .font(.footnote)
                                .fontWeight(.regular)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .offset(x: -4, y: -4)
                                .foregroundColor(.green)
                        }

                        Text(" ")
                            .onAppear() {
                                self.isJoining = true
                                dialog.join(completionBlock: { val in
                                    print("done join dia logggg: \(val) && \(!dialog.isJoined())")
                                    self.isJoining = !dialog.isJoined()
                                })
                            }
                            .onChange(of: dialog.isJoined(), perform: { value in
                                self.isJoining = !value
                            })
                    }
                }
            }.onTapGesture {
                if isOpen {
                    DispatchQueue.main.async {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if self.dialogModel.dialogType == "private" {
                            self.openContactProfile.toggle()
                        } else if self.dialogModel.dialogType == "group" || self.dialogModel.dialogType == "public" {
                            self.openGroupProfile.toggle()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: self.dialogModel.id)
                        self.isOpen = true
                        self.selectedDialogID = self.dialogModel.id

                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                        UserDefaults.standard.set(true, forKey: "localOpen")
                    }
                }
            }.sheet(isPresented: self.$openGroupProfile, onDismiss: {
                guard let diaOpen = UserDefaults.standard.string(forKey: "openingDialogId"), diaOpen != self.dialogModel.id, diaOpen != "" else {
                    self.loadSelectedDialog()
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isOpen = false
                    UserDefaults.standard.set(false, forKey: "localOpen")
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                        print("the current one is: \(self.dialogModel.id) and now the new one: \(diaOpen)")
                        UserDefaults.standard.set(diaOpen, forKey: "selectedDialogID")
                        self.selectedDialogID = diaOpen
                        self.isOpen = true
                        UserDefaults.standard.set(true, forKey: "localOpen")
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: diaOpen)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        UserDefaults.standard.set("", forKey: "openingDialogId")
                    }
                }
            }) {
                NavigationView {
                    VisitGroupChannelView(dismissView: self.$openGroupProfile, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, groupOccUserAvatar: self.groupOccUserAvatar, viewState: .fromDialogCell, dialogRelationship: .subscribed, dialogModel: self.dialogModel)
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
            }

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
                        .destructive(Text(self.dialogModel.dialogType == "private" ? "Delete Dialog" : (self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? (self.dialogModel.dialogType == "public" ? "Destroy Channel" : "Destroy Group") : (self.dialogModel.dialogType == "public" ? (UserDefaults.standard.string(forKey: "visitingDialogId") != "" ? "Dismiss Channel" : "Leave Channel") : "Leave Group"))), action: {
                            changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)

                            self.isOpen = false
                            self.openActionSheet = false
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "group" {
                                    changeDialogRealmData.shared.deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false)
                                } else if self.dialogModel.dialogType == "public" {
                                    UserDefaults.standard.set("", forKey: "visitingDialogId")
                                    changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID"))
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
                    if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), diaId != "" {
                        changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: diaId, isOwner: false)
                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                    }
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
            
            if occ != UserDefaults.standard.integer(forKey: "currentUserID") {
                do {
                    let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: occ) {
                        if foundContact.avatar == "" {
                            Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                for i in users {
                                    self.groupOccUserAvatar.append(i.avatar ?? PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
                                    if self.groupOccUserAvatar.count >= 3 { return }
                                }
                            })
                        } else {
                            self.groupOccUserAvatar.append(foundContact.avatar)
                        }
                    } else {
                        Request.users(withIDs: [NSNumber(value: occ)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            for i in users {
                                self.groupOccUserAvatar.append(i.avatar ?? PersistenceManager().getCubeProfileImage(usersID: i) ?? "")
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
                        newContact.avatar = self.connectyContact.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact) ?? ""
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

    func loadSelectedDialog() {
        guard self.openNewDialogID != 0 else { return }

        for dia in self.auth.dialogs.results.filter({ $0.isDeleted != true }) {
            for occu in dia.occupentsID {
                if occu == self.openNewDialogID && dia.dialogType == "private" {
                    //Success Finding local dialog
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isOpen = false
                        UserDefaults.standard.set(false, forKey: "localOpen")
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                            print("the current one is: \(self.dialogModel.id) and now the new one: \(dia.id)")
                            self.selectedDialogID = dia.id
                            UserDefaults.standard.set(dia.id, forKey: "selectedDialogID")
                            self.openNewDialogID = 0
                            self.isOpen = true
                            UserDefaults.standard.set(true, forKey: "localOpen")
                            changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: dia.id)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UserDefaults.standard.set("", forKey: "openingDialogId")
                        }
                    }

                    return
                }
            }
            
            if self.openNewDialogID == 0 { return }
        }

        let dialog = ChatDialog(dialogID: nil, type: .private)
        dialog.occupantIDs = [NSNumber(value: self.openNewDialogID)]  // an ID of opponent

        Request.createDialog(dialog, successBlock: { (dialog) in
            changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isOpen = false
                    UserDefaults.standard.set(false, forKey: "localOpen")
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                        let newId = self.auth.dialogs.filterDia(text: "").filter { $0.isDeleted != true }.last?.id ?? ""
                        print("the current one is: \(self.dialogModel.id) and now the new one: \(newId)")
                        UserDefaults.standard.set(newId, forKey: "selectedDialogID")
                        self.selectedDialogID = newId
                        self.openNewDialogID = 0
                        self.isOpen = true
                        UserDefaults.standard.set(true, forKey: "localOpen")
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: newId)
                        self.openNewDialogID = 0
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        UserDefaults.standard.set("", forKey: "openingDialogId")
                    }
                }
            })
        }) { (error) in
            //occu.removeAll()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            print("error making dialog: \(error.localizedDescription)")
        }
    }
}

