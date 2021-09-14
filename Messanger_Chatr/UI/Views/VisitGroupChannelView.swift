//
//  VisitGroupChannelView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/17/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift
import Firebase
import PopupView

struct messagePinStruct: Identifiable, RealmSwift.RealmCollectionValue {
    var id = UUID()
    var messageId: String = ""
    var date: Date = Date()
}

struct VisitGroupChannelView: View {
    @EnvironmentObject var auth: AuthModel
    //@Environment(\.presentationMode) var presentationMode
    @Binding var dismissView: Bool
    @Binding var isEditGroupOpen: Bool
    @Binding var canEditGroup: Bool
    @Binding var openNewDialogID: Int
    @Binding var showPinDetails: String
    @State var groupOccUserAvatar: [String] = []
    @State var fromSharedPublicDialog: String = ""
    @State var showMoreMembers: Bool = false
    @State var showMoreAdmins: Bool = false
    @State var showProfile: Bool = false
    @State var viewState: visitPublicDialogState = .unknown
    @State var dialogRelationship: visitDialogRelationship = .unknown
    @State var dialogModel: DialogStruct = DialogStruct()
    @State var publicDialogModel: PublicDialogModel = PublicDialogModel()
    @State var dialogModelMembers: [Int] = []
    @State var dialogModelAdmins: [Int] = []
    @State var selectedNewMembers: [Int] = []
    @State var publicTags: [String] = []
    @State var addNewMemberID: String = ""
    @State var currentUserIsPowerful: Bool = false
    @State var isProfileImgOpen: Bool = false
    @State private var showingMoreSheet = false
    @State private var notificationsOn = true
    @State private var profileViewSize = CGSize.zero
    @State var showAlert = false
    @State var notiText: String = ""
    @State var notiType: String = ""
    @State var showAddMembers: Bool = false
    @State var isRemoving: Bool = false
    @State var isAdmin: Bool = false
    @State var isOwner: Bool = false
    @State var scrollOffset: CGFloat = CGFloat.zero

    var body: some View {
        ZStack {
            NavigationLink(destination: self.moreMembers(), isActive: self.$showMoreAdmins) {
                EmptyView()
            }

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    //MARK: Top Profile
                    topGroupHeaderView(dialogModel: self.$dialogModel, groupOccUserAvatar: self.$groupOccUserAvatar, isProfileImgOpen: self.$isProfileImgOpen, isEditGroupOpen: self.$isEditGroupOpen, publicTags: self.$publicTags, showMoreAdmins: self.$showMoreAdmins, reportCount: self.publicDialogModel.reportCount ?? 0)
                        .environmentObject(self.auth)
                        .padding(.top, self.dialogModel.dialogType == "public" ? Constants.screenHeight * 0.15 : 40)
                        .padding(.bottom, self.dialogModel.dialogType == "public" ? 5 : 15)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewOffsetKey.self,
                                value: -$0.frame(in: .named("visitGroup-scroll")).origin.y)
                        })
                        .onPreferenceChange(ViewOffsetKey.self) {
                            self.scrollOffset = $0
                        }

                    //MARK: Action Buttons
                    if self.dialogModel.dialogType == "public" {
                        PublicActionSection(dialogRelationship: self.$dialogRelationship, dialogModel: self.$dialogModel, currentUserIsPowerful: self.$currentUserIsPowerful, dismissView: self.$dismissView, notiType: self.$notiType, notiText: self.$notiText, showAlert: self.$showAlert, notificationsOn: self.$notificationsOn, dialogModelAdmins: self.$dialogModelAdmins, openNewDialogID: self.$openNewDialogID)
                            .environmentObject(self.auth)
                            .padding(.vertical, 5)
                            .padding(.bottom)
                    }
                    
                    //MARK: Pinned Section
                    if !self.dialogModel.pinMessages.isEmpty && !self.dialogModel.messages.isEmpty {
                        PinnedSectionView(showPinDetails: self.$showPinDetails, dialog: self.dialogModel)
                            .environmentObject(self.auth)
                    }
                    
                    //MARK: Share Action Section
                    if self.dialogModel.dialogType == "public" {
                        PublicShareSection(dismissView: self.$dismissView, newDialogID: self.$showPinDetails, notiType: self.$notiType, notiText: self.$notiText, showAlert: self.$showAlert, dialogModel: self.dialogModel)
                            .environmentObject(self.auth)
                    }

                    //MARK: Admin List Section
                    HStack(alignment: .bottom) {
                        Text(self.dialogModel.dialogType == "public" ? "MEMBERS:" : "ADMINS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                            .offset(y: 2)
                        Spacer()
                    }.opacity(self.dialogModelAdmins.isEmpty ? 0 : 1)
                    
                    VStack(alignment: .center, spacing: 0) {
                        ForEach(self.dialogModelAdmins, id: \.self) { id in
                            DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, showProfile: self.$showProfile, contactID: Int(id), isAdmin: self.dialogModel.adminID.contains(Int(id)) ? true : false, isOwner: self.dialogModel.owner == id ? true : false, currentUserIsPowerful: self.$currentUserIsPowerful, isLast: self.dialogModelAdmins.last == id, isRemoving: self.$isRemoving, isPublic: self.dialogModel.dialogType == "public")
                                .environmentObject(self.auth)

                            if self.dialogModelAdmins.last != id {
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 40)
                            } else if self.dialogModelAdmins.count > 4 {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.showMoreAdmins.toggle()
                                }) {
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 80)
                                            .offset(x: 20)
                                        
                                        HStack {
                                            Image(systemName: "ellipsis.circle")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 20, height: 20, alignment: .center)
                                                .foregroundColor(Color("SoftTextColor"))
                                                .padding(.leading, 10)
                                            
                                            Text(self.dialogModel.dialogType == "public" ? "more members..." : "more admins...")
                                                .font(.subheadline)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal)
                                            
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .resizable()
                                                .font(Font.title.weight(.bold))
                                                .scaledToFit()
                                                .frame(width: 7, height: 15, alignment: .center)
                                                .foregroundColor(.secondary)
                                        }.padding(.horizontal)
                                        .padding(.top, 10)
                                        .padding(.bottom, 15)
                                        .contentShape(Rectangle())
                                    }
                                }.buttonStyle(changeBGButtonStyle())
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, !self.dialogModelAdmins.isEmpty ? 15 : 0)

                    //MARK: Memebrs / Admins List Section
                    HStack(alignment: .bottom) {
                        Text(self.dialogModel.dialogType == "public" ? "ADMINS:" : "\(self.dialogModel.occupentsID.count) CONTACTS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: self.dialogModel.dialogType == "public" ? -4 : 2)
                        Spacer()
                    }.opacity((self.dialogModel.dialogType == "group") || !self.dialogModelMembers.isEmpty ||  (self.dialogModel.dialogType == "public") && self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? 1 : 0)
                    
                    VStack(alignment: .center, spacing: 0) {
                        if (self.dialogModel.dialogType == "group") {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.showAddMembers.toggle()
                            }) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 42, height: 20, alignment: .center)
                                            .foregroundColor(Color("SoftTextColor"))
                                        
                                        Text("Add Members")
                                            .font(.subheadline)
                                            .foregroundColor(Color.blue)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .padding(.vertical, self.dialogModelMembers.isEmpty ? 17.5 : 12.5)
                                    .contentShape(Rectangle())
                                    
                                    Divider()
                                        .frame(width: Constants.screenWidth - 80)
                                        .offset(x: 20)
                                        .opacity(!self.dialogModelMembers.isEmpty ? 1 : 0)
                                }
                            }.buttonStyle(changeBGButtonStyle())
                            .sheet(isPresented: self.$showAddMembers, onDismiss: {
                                self.addMembersDismiss()
                            }) {
                                NewConversationView(usedAsNew: false, selectedContact: self.$selectedNewMembers, newDialogID: self.$addNewMemberID)
                                    .environmentObject(self.auth)
                            }
                        }

                        ForEach(self.dialogModelMembers.sorted(by: { $0 > $1 }).indices, id: \.self) { id in
                            VStack(alignment: .trailing, spacing: 0) {
                                if id <= 3 {
                                    DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, showProfile: self.$showProfile, contactID: Int(self.dialogModelMembers[id]), isAdmin: self.dialogModel.adminID.contains(self.dialogModelMembers[id]), isOwner: self.dialogModel.owner == self.dialogModelMembers[id], currentUserIsPowerful: self.$currentUserIsPowerful, isLast: id == 3 || self.dialogModelMembers.last == self.dialogModelMembers[id] , isRemoving: self.$isRemoving, isPublic: self.dialogModel.dialogType == "public")
                                        .environmentObject(self.auth)
                                }
                                
                                if self.dialogModelMembers.count > 4 && id == 3 {
                                    NavigationLink(destination: self.addMore(), isActive: $showMoreMembers) {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            Divider()
                                                .frame(width: Constants.screenWidth - 80)
                                                .offset(x: 20)
                                            
                                            HStack {
                                                Image(systemName: "ellipsis.circle")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20, alignment: .center)
                                                    .foregroundColor(Color("SoftTextColor"))
                                                    .padding(.leading, 10)
                                                
                                                Text("more...")
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal)
                                                
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .resizable()
                                                    .font(Font.title.weight(.bold))
                                                    .scaledToFit()
                                                    .frame(width: 7, height: 15, alignment: .center)
                                                    .foregroundColor(.secondary)
                                            }.padding(.horizontal)
                                            .padding(.top, 10)
                                            .padding(.bottom, 15)
                                            .contentShape(Rectangle())
                                        }
                                    }.buttonStyle(changeBGButtonStyle())
                                }
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, (self.dialogModel.dialogType == "group") || !self.dialogModelMembers.isEmpty || (self.dialogModel.dialogType == "public") && self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? 15 : 0)
                    
                    //MARK: More Section
                    self.moreSectionBuilder()
                                    
                    //MARK: Footer Section
                    FooterInformation(middleText: "Created: \(self.dialogModel.createdAt.getFullElapsedInterval())")
                        .padding(.vertical)
                        .padding(.bottom)
                }.coordinateSpace(name: "visitGroup-scroll")
                .navigationBarTitle(self.scrollOffset > (self.dialogModel.dialogType == "public" ? 190 : 135) || self.isEditGroupOpen || self.showMoreMembers || self.showMoreAdmins || self.showProfile ? self.dialogModel.fullName : "")
            }

            //MARK: Other Views - See profile image
            ZStack {
                BlurView(style: .systemUltraThinMaterial)
                    .opacity(self.isProfileImgOpen ? Double(150 - abs(self.profileViewSize.height)) / 150 : 0)
                    .animation(.linear(duration: 0.15))
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.isProfileImgOpen = false
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .foregroundColor(Color("bgColor"))
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15, alignment: .center)
                                    .foregroundColor(.primary)
                            }
                        }.buttonStyle(ClickButtonStyle())
                        .padding(.horizontal, 20)
                        .opacity(self.isProfileImgOpen ? Double(150 - self.profileViewSize.height) / 150 : 0)
                        .offset(y: self.profileViewSize.height / 3)
                        .offset(y: -50)
                    }
                    
                    WebImage(url: URL(string: self.dialogModel.avatar))
                        .resizable()
                        .placeholder{ Image(systemName: "person.fill") }
                        .indicator(.activity)
                        .aspectRatio(contentMode: .fill)
                        .transition(.fade(duration: 0.25))
                        .frame(width: Constants.screenWidth - 40, height: Constants.screenWidth - 40, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: self.isProfileImgOpen ? abs(self.profileViewSize.height) + 25 : 100))
                        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 15)
                        .opacity(self.isProfileImgOpen ? 1 : 0)
                        .offset(x: self.profileViewSize.width, y: self.profileViewSize.height)
                        .offset(y: -50)
                        .scaleEffect(self.isProfileImgOpen ? 1 - abs(self.profileViewSize.height) / 500 : 0, anchor: .topLeading)
                        .animation(.spring(response: 0.30, dampingFraction: 0.7, blendDuration: 0))
                        .gesture(DragGesture(minimumDistance: self.isProfileImgOpen ? 0 : Constants.screenHeight).onChanged { value in
                            guard value.translation.height < 175 else { return }
                            guard value.translation.height > -175 else { return }
                            print("height: \(value.translation.height)")
                            if self.isProfileImgOpen {
                                self.profileViewSize = value.translation
                            }
                        }.onEnded { value in
                            if self.profileViewSize.height > 100 {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.isProfileImgOpen = false
                            } else if self.profileViewSize.height < -100 {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.isProfileImgOpen = false
                            }

                        }.sequenced(before: TapGesture().onEnded({
                            if self.profileViewSize.height == 0 {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.isProfileImgOpen = false
                            } else {
                                self.profileViewSize = .zero
                            }
                        })))
                }
            }.popup(isPresented: self.$showAlert, type: .floater(), position: .bottom, animation: Animation.spring(), autohideIn: 4, closeOnTap: true) {
                self.auth.createTopFloater(alertType: self.notiType, message: self.notiText)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 8)
            }
        }.background(Color("bgColor"))
        .onAppear() {
            DispatchQueue.main.async {
                self.showProfile = false
                if self.viewState == .fromDiscover {
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: self.publicDialogModel.id ?? self.fromSharedPublicDialog) {
                            self.dialogRelationship = !foundDialog.isDeleted ? .subscribed : .notSubscribed

                            try realm.safeWrite ({
                                if let name = self.publicDialogModel.name {
                                    foundDialog.fullName = name
                                }
                                
                                if let description = self.publicDialogModel.description {
                                    foundDialog.bio = description
                                }
                                
                                if let avatar = self.publicDialogModel.avatar {
                                    foundDialog.avatar = avatar
                                }
                                
                                if let coverPhoto = self.publicDialogModel.coverPhoto {
                                    foundDialog.coverPhoto = coverPhoto
                                }
                                
                                if let owner = self.publicDialogModel.owner {
                                    foundDialog.owner = owner
                                }
                                
                                if let memCount = self.publicDialogModel.memberCount, memCount != 0 {
                                    foundDialog.publicMemberCount = memCount
                                }
                                self.dialogModel = foundDialog

                                realm.add(foundDialog, update: .all)
                                
                                print("ccomon nowww: founddd \(self.dialogModel.dialogType == "public") && \(self.dialogModel.id) && \(fromSharedPublicDialog)")
                            })
                        } else {
                            self.dialogRelationship = .notSubscribed
                            let dialog = DialogStruct()

                            dialog.id = self.publicDialogModel.id ?? self.fromSharedPublicDialog
                            dialog.dialogType = "public"
                            dialog.isDeleted = true
                            
                            if let name = self.publicDialogModel.name {
                                dialog.fullName = name
                            }
                            
                            if let description = self.publicDialogModel.description {
                                dialog.bio = description
                            }
                            
                            if let avatar = self.publicDialogModel.avatar {
                                dialog.avatar = avatar
                            }
                            
                            if let coverPhoto = self.publicDialogModel.coverPhoto {
                                dialog.coverPhoto = coverPhoto
                            }
                            
                            if let owner = self.publicDialogModel.owner {
                                dialog.owner = owner
                            }

                            if let memCount = self.publicDialogModel.memberCount {
                                dialog.publicMemberCount = memCount
                            }
                            self.dialogModel = dialog

                            try realm.safeWrite ({
                                realm.add(dialog, update: .all)
                            })
                        }
                    } catch { self.dialogRelationship = .notSubscribed }
                } else if self.viewState == .fromDialogCell {
                    //NEED to specify self.dialogRelationship state here, if used
                    if self.dialogModel.dialogType == "group" {
                        self.dialogRelationship = .group
                    }
                } else if self.viewState == .fromDynamicLink {
                    //NEED to specify self.dialogRelationship state here
                } else if self.viewState == .fromSharedMessage {
                    //not used
                    //NEED to specify self.dialogRelationship state here, if used
                } else if self.viewState == .unknown {
                    //not used
                    //NEED to specify self.dialogRelationship state here, if used
                }
                
                if self.dialogModel.dialogType == "public" {
                    if !self.dialogModelMembers.contains(where: { $0 == self.dialogModel.owner }) && self.dialogModel.owner != 0 {
                        self.dialogModelMembers.append(self.dialogModel.owner)
                    }

                    for i in self.dialogModel.adminID {
                        if !self.dialogModelMembers.contains(where: { $0 == i }) {
                            self.dialogModelMembers.append(i)
                        }
                    }
                    self.dialogModelAdmins = self.dialogModel.occupentsID.filter { $0 != 0 && $0 != self.dialogModel.owner }
                } else if self.dialogModel.dialogType == "group" {
                    if !self.dialogModelAdmins.contains(where: { $0 == self.dialogModel.owner }) && self.dialogModel.owner != 0 {
                        self.dialogModelAdmins.append(self.dialogModel.owner)
                    }

                    for i in self.dialogModel.adminID {
                        if !self.dialogModelAdmins.contains(where: { $0 == i }) {
                            self.dialogModelAdmins.append(i)
                        }
                    }
                    self.dialogModelMembers = self.dialogModel.occupentsID.filter { $0 != 0 }
                }
                
                self.isOwner = self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false
                self.isAdmin = self.dialogModel.adminID.contains(UserDefaults.standard.integer(forKey: "currentUserID")) ? true : false
                //UserDefaults.standard.set(self.dialogModel.id, forKey: "selectedDialogID")
                self.canEditGroup = self.isOwner || self.isAdmin
                self.currentUserIsPowerful = self.isOwner || self.isAdmin ? true : false
                
                if self.dialogModel.dialogType == "public" && self.dialogModel.id != "" {
                    self.observeFirebase()
                    self.observePublicDialogMembers()
                    self.observePinnedMessages(dialogId: self.dialogModel.id)
                } else if self.dialogModel.dialogType == "group" && self.dialogModel.id != "" {
                    self.observePinnedMessages(dialogId: self.dialogModel.id)
                }
                
                if self.dialogRelationship == .subscribed {
                    self.loadNotifications()
                }
                
                NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                    self.showAlert.toggle()
                }

                self.fromSharedPublicDialog = ""
            }
        }
    }
    
    func observeFirebase() {
        print("did we get to the observeFirebase? :\(dialogModel.id)")
        
        let user = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(self.dialogModel.id)")
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                //self.coverPhotoUrl = dict["cover_photo"] as? String ?? ""
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: snapshot.key) {
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
                            
                            if let canType = dict["canMembersType"] as? Bool, foundDialog.canMembersType != canType {
                                foundDialog.canMembersType = canType
                            }
                            
                            if let owner = dict["owner"] as? Int {
                                if foundDialog.owner != owner {
                                    foundDialog.owner = owner
                                }
                                
                                if self.dialogModel.dialogType == "public" {
                                    if !self.dialogModelMembers.contains(where: { $0 == owner }) && owner != 0 {
                                        self.dialogModelMembers.append(owner)
                                    }
                                } else if self.dialogModel.dialogType == "group" {
                                    if !self.dialogModelAdmins.contains(where: { $0 == owner }) && owner != 0 {
                                        self.dialogModelAdmins.append(owner)
                                    }
                                }
                            }
                            
                            for childSnapshot in snapshot.children {
                                let childSnap = childSnapshot as! DataSnapshot
                                if childSnap.key == "tags" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        for tag in dict2 {
                                            if !self.publicTags.contains(tag.key) {
                                                self.publicTags.append(tag.key)
                                            }
                                            
                                            if !foundDialog.publicTags.contains(tag.key) {
                                                foundDialog.publicTags.append(tag.key)
                                            }
                                        }
                                    }
                                } else if childSnap.key == "adminIds" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        foundDialog.adminID.removeAll()

                                        for admin in dict2 {
                                            if let key = Int(admin.key), Int(admin.key) != foundDialog.owner {
                                                if !self.dialogModelMembers.contains(key) {
                                                    self.dialogModelMembers.append(key)
                                                }
                                                
                                                if !foundDialog.adminID.contains(key) {
                                                    foundDialog.adminID.append(key)
                                                }
                                            }
                                        }
                                    }
                                } else if childSnap.key == "members" {
                                    if let dict2 = childSnap.value as? [String: Any] {
                                        foundDialog.occupentsID.removeAll()

                                        for admin in dict2 {
                                            if let key = Int(admin.key), Int(admin.key) != foundDialog.owner {
                                                if !self.dialogModelAdmins.contains(key) {
                                                    self.dialogModelAdmins.append(key)
                                                }
                                                
                                                if !foundDialog.occupentsID.contains(key) {
                                                    foundDialog.occupentsID.append(key)
                                                }
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

                        dialog.id = self.publicDialogModel.id ?? ""
                        dialog.dialogType = "public"
                        dialog.isDeleted = true
                        
                        if let name = self.publicDialogModel.name {
                            dialog.fullName = name
                        }
                        
                        if let description = self.publicDialogModel.description {
                            dialog.bio = description
                        }
                        
                        if let avatar = self.publicDialogModel.avatar {
                            dialog.avatar = avatar
                        }
                        
                        if let coverPhoto = self.publicDialogModel.coverPhoto {
                            dialog.coverPhoto = coverPhoto
                        }
                        
                        if let canType = self.publicDialogModel.canMembersType {
                            dialog.canMembersType = canType
                        }
                        
                        if let owner = dict["owner"] as? Int {
                            dialog.owner = owner
                            
                            if self.dialogModel.dialogType == "public" {
                                if !self.dialogModelMembers.contains(where: { $0 == owner }) && owner != 0 {
                                    self.dialogModelMembers.append(owner)
                                }
                            } else if self.dialogModel.dialogType == "group" {
                                if !self.dialogModelAdmins.contains(where: { $0 == owner }) && owner != 0 {
                                    self.dialogModelAdmins.append(owner)
                                }
                            }
                        }
                        
                        //self.dialogModel.canMembersType = dict["canMembersType"] as? Bool ?? false
                        for childSnapshot in snapshot.children {
                            let childSnap = childSnapshot as! DataSnapshot
                            if childSnap.key == "tags" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    for tag in dict2 {
                                        if !self.publicTags.contains(tag.key) {
                                            self.publicTags.append(tag.key)
                                        }
                                        
                                        if !dialog.publicTags.contains(tag.key) {
                                            dialog.publicTags.append(tag.key)
                                        }
                                    }
                                }
                            } else if childSnap.key == "adminIds" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    dialog.adminID.removeAll()

                                    for admin in dict2 {
                                        if let key = Int(admin.key), Int(admin.key) != dialog.owner {
                                            if !self.dialogModelMembers.contains(key) {
                                                self.dialogModelMembers.append(key)
                                            }
                                            
                                            if !dialog.adminID.contains(key) {
                                                dialog.adminID.append(key)
                                            }
                                        }
                                    }
                                }
                            } else if childSnap.key == "members" {
                                if let dict2 = childSnap.value as? [String: Any] {
                                    dialog.occupentsID.removeAll()

                                    for admin in dict2 {
                                        
                                        if let key = Int(admin.key), Int(admin.key) != dialog.owner {
                                            if !self.dialogModelAdmins.contains(key) {
                                                self.dialogModelAdmins.append(key)
                                            }
                                            
                                            if !dialog.occupentsID.contains(key) {
                                                dialog.occupentsID.append(key)
                                            }
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

    func observePublicDialogMembers() {
        Request.occupants(forPublicDialogID: self.dialogModel.id, paginator: Paginator.limit(6, skip: 0), successBlock: { (users, pagin) in
            print("successfully pulled memebers for pagin: \(pagin)")
            changeDialogRealmData.shared.insertPublicDialogMembers(dialogId: self.dialogModel.id, users: users, completion: {
                self.insertLocalAdmins()
            })
        }, errorBlock: { err in
            print("error pulling public dialog members: \(err)")
            self.insertLocalAdmins()
        })
    }
    
    func insertLocalAdmins() {
        for id in self.dialogModel.occupentsID {
            if !self.dialogModelAdmins.contains(where: { $0 == id }) && id != 0 && id != self.dialogModel.owner {
                self.dialogModelAdmins.append(id)
                
                if self.dialogModelAdmins.count > 4 { break }
            }
        }
    }
    
    func loadNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Request.notificationsSettings(forDialogID: self.dialogModel.id, successBlock: { notiResult in
                self.notificationsOn = notiResult
            })
        }
    }
    
    func addMore() -> some View {
        MoreContactsView(dismissView: self.$dismissView,
                         dialogModelMembers: self.$dialogModelMembers,
                         openNewDialogID: self.$openNewDialogID,
                         dialogModel: self.$dialogModel,
                         currentUserIsPowerful: self.$currentUserIsPowerful,
                         showProfile: self.$showProfile)
            .environmentObject(self.auth)
    }
    
    func moreMembers() -> some View {
        MoreContactsView(dismissView: self.$dismissView,
                         dialogModelMembers: self.$dialogModelAdmins,
                         openNewDialogID: self.$openNewDialogID,
                         dialogModel: self.$dialogModel,
                         currentUserIsPowerful: self.$currentUserIsPowerful,
                         showProfile: self.$showProfile)
            .environmentObject(self.auth)
    }

    func observePinnedMessages(dialogId: String) {
        print("the observePinnedMessages isss: \(dialogId)")

        let msg = Database.database().reference().child("Dialogs").child(dialogId).child("pinned")

        msg.observe(.childAdded, with: { snapAdded in
            changeDialogRealmData.shared.addDialogPin(messageId: snapAdded.key, dialogID: self.dialogModel.id)
        })

        msg.observe(.childRemoved, with: { snapRemoved in
            changeDialogRealmData.shared.removeDialogPin(messageId: snapRemoved.key, dialogID: self.dialogModel.id)
        })

        print("the count of pinned messages are: \(self.dialogModel.pinMessages.count) for: \(dialogId)")
    }
    
    func toggleNotifications() {
        self.notificationsOn.toggle()
        Request.updateNotificationsSettings(forDialogID: self.dialogModel.id, enable: self.notificationsOn, successBlock: { result in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.notificationsOn = result
            self.notiType = result ? "notiOn" : "notiOff"
            self.notiText = "Successfully turned notifications \(result ? "on" : "off")"
            self.showAlert.toggle()
        }, errorBlock: { error in
            print("error setting notifications: \(error.localizedDescription)")
            self.notificationsOn.toggle()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.notiType = "error"
            let errMsg = error.localizedDescription == "Request failed: forbidden (403)" ? "Not enough permission to update notification settings" : "Error updating notification settings: \(error.localizedDescription)"
            self.notiText = errMsg
            self.showAlert.toggle()
        })
    }
    
    func destroyLeaveGroup() {
        UserDefaults.standard.set(false, forKey: "localOpen")
        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
        
        if self.dialogModel.dialogType == "public" && !self.isOwner {
            if let index = self.dialogModelAdmins.firstIndex(of: UserDefaults.standard.integer(forKey: "currentUserID")) {
                self.dialogModelAdmins.remove(at: index)
            }
            self.dialogRelationship = .notSubscribed
            self.showingMoreSheet = false
            changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID"))
        } else {
            changeDialogRealmData.shared.deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.isOwner)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        print("done deleting dialog: \(self.dialogModel.id)")
    }
    
    func reportPublicDialog() {
        changeDialogRealmData.shared.reportFirebasePublicDialog(dialogId: self.dialogModel.id, onSuccess: { _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.auth.sendPushNoti(userIDs: [NSNumber(value: self.dialogModel.owner)], title: "\(self.dialogModel.fullName) Reported", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") reported your channel \(self.dialogModel.fullName)")
            self.notiType = "report"
            self.notiText = "Successfully reported \(self.dialogModel.fullName)"
            self.showAlert.toggle()
        }, onError: { err in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.notiType = "error"
            self.notiText = "Error reporting channel: \(String(describing: err))"
            self.showAlert.toggle()
        })
    }
    
    func addMembersDismiss() {
        guard self.selectedNewMembers.count > 0 else { return }

        var occu: [NSNumber] = []
        for i in self.selectedNewMembers {
            occu.append(NSNumber(value: i))
        }
        
        if self.dialogModel.dialogType == "public" {
            Request.addAdminsToDialog(withID: self.dialogModel.id, adminsUserIDs: occu, successBlock: { (updatedDialog) in
                changeDialogRealmData.shared.addFirebaseAdmins(dialogId: updatedDialog.id ?? "", adminIds: updatedDialog.adminsIDs ?? [], onSuccess: { _ in
                    changeDialogRealmData.shared.insertDialogs([updatedDialog]) {
                        print("Success adding contact as admin!")
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        for i in self.selectedNewMembers {
                            if !self.dialogModel.occupentsID.contains(i) {
                                self.dialogModelMembers.append(i)
                                self.auth.sendPushNoti(userIDs: [NSNumber(value: i)], title: "Added Admin", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") added you as an admin to \(self.dialogModel.fullName) 🥳")
                            }
                        }
                        
                        self.addNewMemberID = ""
                        self.selectedNewMembers.removeAll()
                        self.notiType = "success"
                        self.notiText = occu.count == 0 ? "Successfully added a new admin" : "Successfully added new admins"
                        occu.removeAll()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.showAlert = true
                        }
                    }
                }, onError: { _ in })
            }) { (error) in
                let notiTextConfig = self.selectedNewMembers.count == 1 ? "The selected contact is " : "One or more of the selected contacts are "
                self.notiType = "error"
                self.notiText = notiTextConfig + "already an admin"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self.selectedNewMembers.removeAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.showAlert = true
                }
                print("error adding members to dialog: \(error.localizedDescription)")
            }
        } else {
            let updateParameters = UpdateChatDialogParameters()
            print("adding new user to group!: \(occu.count)")
            updateParameters.occupantsIDsToAdd = occu
            
            Request.updateDialog(withID: self.dialogModel.id, update: updateParameters, successBlock: { (updatedDialog) in
                changeDialogRealmData.shared.insertDialogs([updatedDialog]) { }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                for i in self.selectedNewMembers {
                    if !self.dialogModel.occupentsID.contains(i) {
                        self.dialogModelMembers.append(i)
                        self.auth.sendPushNoti(userIDs: [NSNumber(value: i)], title: "Added To Group", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") added you to \(self.dialogModel.fullName).")
                    }
                }
                
                self.addNewMemberID = ""
                self.selectedNewMembers.removeAll()
                self.notiType = "success"
                self.notiText = occu.count == 0 ? "Successfully added a new member" : "Successfully added new members."
                occu.removeAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.showAlert = true
                }
            }) { (error) in
                let notiTextConfig = self.selectedNewMembers.count == 1 ? "The selected contact is already " : "One or more of the selected contacts are already "
                self.notiType = "error"
                self.notiText = notiTextConfig + "in the chat"
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self.selectedNewMembers.removeAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.showAlert = true
                }
                print("error adding members to dialog: \(error.localizedDescription)")
            }
        }
    }
    
    func moreSectionBuilder() -> some View {
        VStack {
            HStack {
                Text("MORE:")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .offset(y: 2)
                Spacer()
            }
            
            VStack(alignment: .center) {
                Button(action: {
                    self.showingMoreSheet.toggle()
                }) {
                    HStack {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.primary)
                            .opacity(0.75)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)

                        Text("more...")
                            .font(.none)
                            .fontWeight(.none)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.bold))
                            .scaledToFit()
                            .frame(width: 7, height: 15, alignment: .center)
                            .foregroundColor(.secondary)
                    }.padding(.all)
                    .padding(.vertical, 1.5)
                    .contentShape(Rectangle())
                }.buttonStyle(changeBGButtonStyle())
                .frame(minWidth: 100, maxWidth: Constants.screenWidth)
                .actionSheet(isPresented: $showingMoreSheet) {
                    ActionSheet(title: Text(self.dialogModel.fullName + "'s Options"), message: nil, buttons: !self.isOwner && self.dialogModel.dialogType == "public" ? [
                                    .default(Text(self.notificationsOn ? "Turn Notifications Off" : "Turn Notifications On"), action: {
                                        self.toggleNotifications()
                                    }), .destructive(Text("Report Channel"), action: {
                                        self.reportPublicDialog()
                                    }), .destructive(Text(self.isOwner ? "Destroy Channel" : "Leave Channel"), action: {
                                        withAnimation {
                                            self.destroyLeaveGroup()
                                        }
                                    }), .cancel(Text("Done"))] : [
                                    .default(Text(self.isOwner ? "Edit Details" : (self.notificationsOn ? "Turn Notifications Off" : "Turn Notifications On")), action: {
                                        if self.isOwner {
                                            self.isEditGroupOpen.toggle()
                                        } else {
                                            self.toggleNotifications()
                                        }
                                    }), .destructive(Text((self.isOwner ? "Destroy " : "Leave ") + (self.dialogModel.dialogType == "public" ? "Channel" : "Group")), action: {
                                        withAnimation {
                                            self.destroyLeaveGroup()
                                        }
                                    }), .cancel(Text("Done"))])
                }.simultaneousGesture(TapGesture()
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    })
            }.background(Color("buttonColor"))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .circular))
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            .padding(.horizontal)
            .padding(.bottom, 60)
        }
    }
}

//MARK: Top Header View
struct topGroupHeaderView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dialogModel: DialogStruct
    @Binding var groupOccUserAvatar: [String]
    @Binding var isProfileImgOpen: Bool
    @Binding var isEditGroupOpen: Bool
    @Binding var publicTags: [String]
    @Binding var showMoreAdmins: Bool
    @State var reportCount: Int
    @State private var isProfileBioOpen: Bool = false
    @State private var moreBioAction = false
    @State var tagSelection: Int? = -1

    var body: some View {
        ZStack(alignment: .top) {
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
            
            //MARK: Sticky Header
            if self.dialogModel.dialogType == "public" {
                stickyHeaderSection(dialogModel: self.$dialogModel)
            }

            VStack(alignment: .center) {
                NavigationLink(destination: EditGroupDialogView(dialogModel: self.$dialogModel).environmentObject(self.auth), isActive: $isEditGroupOpen) {
                    EmptyView()
                }

                VStack(alignment: .center) {
                    VStack(alignment: .center, spacing: 2.5) {
                        Text(self.dialogModel.fullName)
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.showMoreAdmins.toggle()
                        }, label: {
                            Text(self.dialogModel.dialogType == "public" ? ("\(self.dialogModel.publicMemberCount) member") + (self.dialogModel.publicMemberCount == 1 ? "" : "s") : ("\(self.dialogModel.occupentsID.count) contact") + (self.dialogModel.occupentsID.count == 1 ? "" : "s"))
                                .font(.subheadline)
                                .fontWeight(.none)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .offset(y: -2.5)
                        }).buttonStyle(ClickMiniButtonStyle())
                        
                        if self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") && self.reportCount > 0 {
                            Text("\(self.reportCount) " + (self.reportCount == 1 ? "report" : "reports"))
                                .font(.subheadline)
                                .fontWeight(.none)
                                .foregroundColor(self.reportCount <= 2 ? .orange : .red)
                                .multilineTextAlignment(.center)
                                .offset(y: -2)
                        }
                        
                        HStack(alignment: .center, spacing: 10) {
                            ForEach(self.publicTags.indices, id: \.self) { tag in
//                                NavigationLink(destination: self.moreDetails(tagId: self.publicTags[tag], viewState: .tags).edgesIgnoringSafeArea(.all), tag: Int(tag), selection: self.$tagSelection) {
//                                    EmptyView()
//                                }

                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.tagSelection = Int(tag)
                                }, label: {
                                    Text("#" + "\(self.publicTags[tag])")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 10)
                                        .foregroundColor(Color("bgColor_opposite"))
                                        .background(RoundedRectangle(cornerRadius: 7).stroke(Color("interactions_selected").opacity(0.5), lineWidth: 2.5).background(Color("interactions_selected").opacity(0.3)).cornerRadius(7))
                                        .lineLimit(1)
                                        .fixedSize()
                                }).buttonStyle(ClickButtonStyle())
                            }
                        }.opacity(self.dialogModel.dialogType == "public" ? 1 : 0)
                    }.padding(.top, 10)
                    .padding(.bottom, self.dialogModel.bio == "" ? 15 : 0 )

                    //MARK: Bio Section
                    if self.dialogModel.bio != "" {
                        VStack(alignment: .trailing) {
                            Text(self.dialogModel.bio)
                                .font(.subheadline)
                                .fontWeight(.none)
                                .multilineTextAlignment(.center)
                                .lineLimit(self.isProfileBioOpen ? 20 : 4)
                                .padding(.bottom, self.moreBioAction ? 0 : 10)
                                .padding(.horizontal)
                                .onTapGesture {
                                    if moreBioAction {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            self.isProfileBioOpen.toggle()
                                        }
                                    }
                                }
                                .readSize(onChange: { size in
                                    self.moreBioAction = size.height > 70
                                })

                            if self.moreBioAction {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        self.isProfileBioOpen.toggle()
                                    }
                                }, label: {
                                    Text(self.isProfileBioOpen ? "less..." : "more...")
                                        .font(.subheadline)
                                        .fontWeight(.none)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing)
                                }).buttonStyle(ClickButtonStyle())
                                .offset(y: 2.5)
                                .padding(.bottom, 8)
                            }
                        }.padding(.top, 2.5)
                    }
                }.padding(.top, 45)
                .padding(.bottom, 5)
            }.frame(width: Constants.screenWidth - 40)
            .background(
                ZStack {
                    if self.dialogModel.dialogType == "public" {
                        BlurView(style: .systemUltraThinMaterial)
                    } else {
                        Color("buttonColor")
                    }
                }
            )
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 5)
            .padding(.all)
            .padding(.top, self.dialogModel.dialogType == "public" ? 120 : 50)
            
            if self.dialogModel.dialogType == "public" {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.isProfileImgOpen.toggle()
                }) {
                    WebImage(url: URL(string: self.dialogModel.avatar))
                        .resizable()
                        .placeholder{ Image("empty-profile").resizable().frame(width: 110, height: 110, alignment: .center).scaledToFill().cornerRadius(20) }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.15))
                        .scaledToFill()
                        .clipped()
                        .background(Color("buttonColor"))
                        .frame(width: 110, height: 110, alignment: .center)
                        .cornerRadius(20)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                }.buttonStyle(ClickButtonStyle())
                .offset(y: 75)
            } else if self.dialogModel.dialogType == "group" {
                ZStack {
                    ForEach(self.groupOccUserAvatar.indices, id: \.self) { id in
                        if id < 3 {
                            ZStack {
                                Circle()
                                    .frame(width: self.groupOccUserAvatar.count > 2 ? 54 : self.groupOccUserAvatar.count > 1 ? 74 : 104, height: self.groupOccUserAvatar.count > 2 ? 54 : self.groupOccUserAvatar.count > 1 ? 74 : 104, alignment: .center)
                                    .foregroundColor(Color("buttonColor"))
                                    .opacity(self.groupOccUserAvatar.count == 1 ? 0 : 1)
                                    .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 8)
                                
                                WebImage(url: URL(string: self.groupOccUserAvatar[id]))
                                    .resizable()
                                    .placeholder{ Image(systemName: "person.fill") }
                                    .indicator(.activity)
                                    .transition(.fade(duration: 0.15))
                                    .scaledToFill()
                                    .frame(width: self.groupOccUserAvatar.count > 2 ? 50 : self.groupOccUserAvatar.count > 1 ? 70 : 100, height: self.groupOccUserAvatar.count > 2 ? 50 : self.groupOccUserAvatar.count > 1 ? 70 : 100, alignment: .center)
                                    .clipShape(Circle())
                                    
                            }.offset(x: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? 0 : (id == 1 ? -23 : (id == 2 ? 23 : 0))) : self.groupOccUserAvatar.count == 1 ? 0 : (id == 0 ? -23 : 20), y: self.groupOccUserAvatar.count >= 3 ? (id == 0 ? -15 : (id == 1 ? 23 : (id == 2 ? 23 : 0))) : 0)
                            .zIndex(id == 0 ? 1 : 0)
                            .padding(.horizontal, self.groupOccUserAvatar.count == 1 ? 0 : 15)
                        }
                    }
                }.padding(.vertical, self.groupOccUserAvatar.count != 1 ? 20 : 0)
                .offset(y: 10)
            }
        }
    }
}
