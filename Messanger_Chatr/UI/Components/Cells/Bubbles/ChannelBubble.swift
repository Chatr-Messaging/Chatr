//
//  ChannelBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/20/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Firebase
import RealmSwift
import SDWebImageSwiftUI
import ConnectyCube

struct ChannelBubble: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    @Binding var openDialogId: String
    @Binding var isHomeDialogOpen: Bool
    var dialogId: String
    var hasPrior: Bool = false
    @State var dialogModel: DialogStruct = DialogStruct()
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var isMember: Bool = false
    @State var showChannel: Bool = false
    @State var shareGroup: Bool = false
    @State var showPinDetails: String = ""
    @State var openNewDialogID: Int = 0
    @State var groupOccUserAvatar: [String] = []

    var body: some View {
        ZStack() {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.showChannel.toggle()
            }) {
                ZStack(alignment: .top) {
                    WebImage(url: URL(string: self.dialogModel.coverPhoto))
                        .resizable()
                        .placeholder{ Image(systemName: "photo.on.rectangle.angled").resizable().frame(width: 30, height: 27, alignment: .center).scaledToFill().offset(y: -18) }
                        .indicator(.activity)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                        //.transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                        //.cornerRadius(12.5)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)

                    VStack(alignment: .center, spacing: 2) {
                        HStack(alignment: .bottom, spacing: 5) {
                            WebImage(url: URL(string: self.dialogModel.avatar))
                                .resizable()
                                .placeholder{ Image("empty-profile").resizable().frame(width: 70, height: 70, alignment: .center).scaledToFill() }
                                .indicator(.activity)
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .background(Color("buttonColor"))
                                .cornerRadius(58 / 4)
                                .padding(.leading)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 6)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(self.dialogModel.fullName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .foregroundColor(Color.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(self.dialogModel.publicMemberCount > 1 ? "\(self.dialogModel.publicMemberCount) members" : "become the first member!")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.secondary)
                                    .multilineTextAlignment(.leading)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        
                        HStack(alignment: .center) {
                            Text(self.dialogModel.bio)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 5)
                                .padding(.leading)
                                .padding(.horizontal, 5)
                                .lineLimit(2)
                                
                                Spacer()
                        }
                        
                        Spacer()
                        if !self.isMember {
                            Button(action: {
                                Request.subscribeToPublicDialog(withID: self.dialogModel.id, successBlock: { dialogz in
                                    changeDialogRealmData.shared.toggleFirebaseMemberCount(dialogId: dialogz.id ?? "", isJoining: true, totalCount: Int(dialogz.occupantsCount), onSuccess: { _ in
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        withAnimation {
                                            self.isMember = true
                                        }
                                        changeDialogRealmData.shared.insertDialogs([dialogz], completion: {
                                            changeDialogRealmData.shared.updateDialogDelete(isDelete: false, dialogID: dialogz.id ?? "")
                                            self.auth.sendPushNoti(userIDs: [NSNumber(value: dialogz.userID)], title: "New Member joined \(dialogz.name ?? "no name")", message: "\(self.auth.profile.results.first?.fullName ?? "No Name") joined your public chat \(dialogz.name ?? "no name")")
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
                                    
                                    Text("Join Channel")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color.white)
                                }.frame(width: Constants.screenWidth * 0.60 - 50, height: 36, alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }.buttonStyle(ClickButtonStyle())
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2.5)
                            .padding(.bottom, 8)
                        } else {
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
                                }.frame(width: Constants.screenWidth * 0.60 - 50, height: 36, alignment: .center)
                                .background(Color("buttonColor_darker"))
                                .cornerRadius(8)
                            }.buttonStyle(ClickButtonStyle())
                            .padding(.bottom, 8)
                        }
                    }
                    .padding(.top, 70)
                    .sheet(isPresented: self.$shareGroup, onDismiss: {
                        print("printz dismiss share dia")
                    }) {
                        NavigationView() {
                            ShareProfileView(dimissView: self.$shareGroup, contactID: 0, dialogID: dialogId, contactFullName: self.dialogModel.fullName, contactAvatar: self.dialogModel.avatar, isPublicDialog: true, totalMembers: self.dialogModel.publicMemberCount).environmentObject(self.auth)
                                .navigationTitle("Share Channel")
                                .navigationBarItems(leading:
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                withAnimation {
                                                    self.shareGroup.toggle()
                                                }
                                            }) {
                                                Text("Done")
                                                    .foregroundColor(.primary)
                                                    .fontWeight(.medium)
                                            })
                        }
                    }
                }
                .frame(minHeight: 220, maxHeight: 245)
                .frame(width: Constants.screenWidth * 0.75)
            }
            .padding(.bottom, self.hasPrior ? 0 : 4)
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 14)
            .buttonStyle(highlightedButtonStyle())
            .sheet(isPresented: self.$showChannel, onDismiss: {
                   print("need to open Chat view!!3333")
                
                if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), diaId != "" {
                    self.loadPublicDialog(diaId: diaId)
                    print("come omnnnnoww: \(diaId)")
                } else if let diaId2 = UserDefaults.standard.string(forKey: "openingDialogId"), diaId2 != "" {
                    self.loadPublicDialog(diaId: diaId2)
                    print("come omnnnnoww22: \(diaId2)")
                } else {
                    self.loadSelectedDialog()
                }
            }) {
                NavigationView {
                    VisitGroupChannelView(dismissView: self.$showChannel, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, groupOccUserAvatar: self.groupOccUserAvatar, viewState: .fromDialogCell, dialogRelationship: self.isMember ? .subscribed : .notSubscribed, dialogModel: self.dialogModel)
                        .environmentObject(self.auth)
                        .edgesIgnoringSafeArea(.all)
                        .navigationBarItems(leading:
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                                        UserDefaults.standard.set("", forKey: "openingDialogId")
                                        withAnimation {
                                            self.showChannel.toggle()
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
        }.onAppear() {
            DispatchQueue.main.async {
                self.observeFirebaseChannel()
                
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: self.dialogId), !foundDialog.isDeleted {
                        self.isMember = true
                    }
                } catch { }
            }
        }
    }
    
    func observeFirebaseChannel() {
        let user = Database.database().reference().child("Marketplace").child("public_dialogs").child(dialogId)
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                //self.coverPhotoUrl = dict["cover_photo"] as? String ?? ""
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                        try realm.safeWrite({
                            if let name = dict["name"] as? String, foundDialog.fullName != name {
                                foundDialog.fullName = name
                            }

                            if let description = dict["description"] as? String, foundDialog.bio != description {
                                foundDialog.bio = description
                            }
                            
                            if let avatar = dict["avatar"] as? String, foundDialog.avatar != avatar {
                                foundDialog.avatar = avatar
                            }
                            
                            if let coverPhoto = dict["cover_photo"] as? String, foundDialog.coverPhoto != coverPhoto {
                                foundDialog.coverPhoto = coverPhoto
                            }
                            
                            if let owner = dict["owner"] as? Int, foundDialog.owner != owner {
                                foundDialog.owner = owner
                            }
                            
                            if let canType = dict["canMembersType"] as? Bool, foundDialog.canMembersType != canType {
                                foundDialog.canMembersType = canType
                            }
                            
                            for childSnapshot in snapshot.children {
                                let childSnap = childSnapshot as! DataSnapshot
                                if childSnap.key == "tags" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        for tag in dict2 {
                                            if !foundDialog.publicTags.contains(tag.key) {
                                                foundDialog.publicTags.append(tag.key)
                                            }
                                        }
                                    }
                                } else if childSnap.key == "adminIds" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        foundDialog.adminID.removeAll()

                                        for admin in dict2 {
                                            if let key = Int(admin.key), Int(admin.key) != foundDialog.owner, !foundDialog.adminID.contains(key) {
                                                foundDialog.adminID.append(key)
                                            }
                                        }
                                    }
                                } else if childSnap.key == "members" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        foundDialog.occupentsID.removeAll()

                                        for admin in dict2 {
                                            if let key = Int(admin.key), Int(admin.key) != foundDialog.owner, !foundDialog.occupentsID.contains(key) {
                                                foundDialog.occupentsID.append(key)
                                            }
                                        }
                                    }
                                }
                            }

                            self.dialogModel = foundDialog

                            realm.add(foundDialog, update: .all)
                        })
                    } else {
                        let dialog = DialogStruct()

                        dialog.id = self.dialogId
                        dialog.dialogType = "public"
                        dialog.isDeleted = true
                        
                        dialog.fullName = dict["name"] as? String ?? "no name"
                        dialog.bio = dict["description"] as? String ?? ""
                        dialog.avatar = dict["avatar"] as? String ?? ""
                        dialog.coverPhoto = dict["cover_photo"] as? String ?? ""
                        dialog.owner = dict["owner"] as? Int ?? 0
                        dialog.canMembersType = dict["canMembersType"] as? Bool ?? false
                        
                        for childSnapshot in snapshot.children {
                            let childSnap = childSnapshot as! DataSnapshot
                            if childSnap.key == "tags" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    for tag in dict2 {
                                        if !dialog.publicTags.contains(tag.key) {
                                            dialog.publicTags.append(tag.key)
                                        }
                                    }
                                }
                            } else if childSnap.key == "adminIds" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    dialog.adminID.removeAll()

                                    for admin in dict2 {
                                        if let key = Int(admin.key), Int(admin.key) != dialog.owner, !dialog.adminID.contains(key) {
                                            dialog.adminID.append(key)
                                        }
                                    }
                                }
                            } else if childSnap.key == "members" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    dialog.occupentsID.removeAll()

                                    for admin in dict2 {
                                        
                                        if let key = Int(admin.key), Int(admin.key) != dialog.owner, !dialog.occupentsID.contains(key) {
                                            dialog.occupentsID.append(key)
                                        }
                                    }
                                }
                            }
                        }

                        self.dialogModel = dialog

                        try realm.safeWrite ({
                            realm.add(dialog, update: .all)
                        })
                    }
                } catch {
                    
                }
            }
        })
    }
    
    func loadPublicDialog(diaId: String) {
        print("laoding pub dia: \(diaId) ** \(UserDefaults.standard.string(forKey: "selectedDialogID") ?? "") && \(self.dialogId)")
        guard diaId != UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", diaId != "" else {
            print("laoding pub dia faileddd")
            return
        }

        UserDefaults.standard.set(false, forKey: "localOpen")
        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
        print("going onto selected dia: \(UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")")
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.openDialogId = diaId
            UserDefaults.standard.set(diaId, forKey: "selectedDialogID")
            UserDefaults.standard.set(true, forKey: "localOpen")
            changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: diaId)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            //UserDefaults.standard.set("", forKey: "openingDialogId")
        }
    }
    
    func loadSelectedDialog() {
        guard self.openNewDialogID != 0 else { return }

        for dia in self.auth.dialogs.results.filter({ $0.isDeleted != true }) {
            for occu in dia.occupentsID {
                if occu == self.openNewDialogID && dia.dialogType == "private" {
                    //Success Finding local dialog
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.isHomeDialogOpen = false
                        UserDefaults.standard.set(false, forKey: "localOpen")
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? self.auth.selectedConnectyDialog?.id ?? "")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                            print("the current one is: \(self.dialogModel.id) and now the new one: \(dia.id)")
                            self.openDialogId = dia.id
                            UserDefaults.standard.set(dia.id, forKey: "selectedDialogID")
                            self.openNewDialogID = 0
                            self.isHomeDialogOpen = true
                            changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: dia.id)
                            UserDefaults.standard.set(true, forKey: "localOpen")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    self.isHomeDialogOpen = false
                    UserDefaults.standard.set(false, forKey: "localOpen")
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? self.auth.selectedConnectyDialog?.id ?? "")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                        print("the current one is: \(self.dialogModel.id) and now the new one:")
                        self.openDialogId = dialog.id ?? ""
                        UserDefaults.standard.set(dialog.id ?? "", forKey: "selectedDialogID")
                        self.openNewDialogID = 0
                        self.isHomeDialogOpen = true
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: dialog.id ?? "")
                        UserDefaults.standard.set(true, forKey: "localOpen")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
