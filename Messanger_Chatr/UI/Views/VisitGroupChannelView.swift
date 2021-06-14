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
    @State var fromDialogCell: Bool = false
    @State var showMoreMembers: Bool = false
    @State var showMoreAdmins: Bool = false
    @State var showProfile: Bool = false
    @State var viewState: visitPublicDialogState = .unknown
    @State var dialogRelationship: visitDialogRelationship = .unknown
    @State var dialogModel: DialogStruct = DialogStruct()
    @State var publicDialogModel: PublicDialogModel = PublicDialogModel()
    @State var dialogModelMemebers: [Int] = []
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
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    //MARK: Top Profile
                    topGroupHeaderView(dialogModel: self.$dialogModel, groupOccUserAvatar: self.$groupOccUserAvatar, isProfileImgOpen: self.$isProfileImgOpen, isEditGroupOpen: self.$isEditGroupOpen, publicTags: self.$publicTags)
                        .environmentObject(self.auth)
                        .padding(.top, 40)
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
                        PublicActionSection(dialogRelationship: self.$dialogRelationship, dialogModel: self.$dialogModel, currentUserIsPowerful: self.$currentUserIsPowerful, dismissView: self.$dismissView)
                            .environmentObject(self.auth)
                    }
                    
                    //MARK: Pinned Section
                    if self.dialogModel.pinMessages.count > 0 {
                        PinnedSectionView(showPinDetails: self.$showPinDetails, dialog: self.dialogModel)
                            .environmentObject(self.auth)
                    }

                    //MARK: Admin List Section
                    HStack(alignment: .bottom) {
                        Text("ADMINS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        ForEach(self.dialogModelAdmins, id: \.self) { id in
                            DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, showProfile: self.$showProfile, contactID: Int(id), isAdmin: self.dialogModel.adminID.contains(Int(id)) ? true : false, isOwner: self.dialogModel.owner == id ? true : false, currentUserIsPowerful: self.$currentUserIsPowerful, isLast: self.dialogModelAdmins.last == id, isRemoving: self.$isRemoving)
                                .environmentObject(self.auth)

                            if self.dialogModelAdmins.last != id {
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 40)
                            } else if self.dialogModelAdmins.count > 4 {
                                NavigationLink(destination: self.moreMembers(), isActive: $showMoreAdmins) {
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
                                            
                                            Text("more admins...")
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
                    .padding(.bottom, 15)

                    //MARK: Memebrs List Section
                    if self.dialogModel.occupentsID.count > 0 {
                        HStack(alignment: .bottom) {
                            Text("\(self.dialogModel.occupentsID.count) TOTAL " + (self.dialogModel.dialogType == "public" ? "MEMBERS:" : "GROUP:"))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .offset(y: 2)
                            Spacer()
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        ForEach(self.dialogModelMemebers.indices, id: \.self) { id in
                            VStack(alignment: .trailing, spacing: 0) {
                                if id == 0 {
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
                                            .padding(.vertical, 12.5)
                                            .contentShape(Rectangle())
                                            
                                            Divider()
                                                .frame(width: Constants.screenWidth - 80)
                                                .offset(x: 20)
                                        }
                                    }.buttonStyle(changeBGButtonStyle())
                                    .sheet(isPresented: self.$showAddMembers, onDismiss: {
                                        if self.selectedNewMembers.count > 0 {
                                            let updateParameters = UpdateChatDialogParameters()
                                            var occu: [NSNumber] = []
                                            for i in self.selectedNewMembers {
                                                occu.append(NSNumber(value: i))
                                                if !self.dialogModel.occupentsID.contains(i) {
                                                    self.dialogModelMemebers.append(i)
                                                }
                                            }
                                            print("adding new user to group!: \(occu.count)")
                                            updateParameters.occupantsIDsToAdd = occu
                                            
                                            Request.updateDialog(withID: self.dialogModel.id, update: updateParameters, successBlock: { (updatedDialog) in
                                                changeDialogRealmData.shared.insertDialogs([updatedDialog]) { }
                                                occu.removeAll()
                                                self.addNewMemberID = ""
                                                self.selectedNewMembers.removeAll()
                                                self.notiType = "success"
                                                self.notiText = occu.count == 0 ? "Successfully added a new member" : "Successfully added new members."
                                                self.showAlert = true
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            }) { (error) in
                                                self.notiType = "error"
                                                self.notiText = "One or more of the selected contacts are already in the chat."
                                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                self.selectedNewMembers.removeAll()
                                                self.showAlert = true
                                                print("error adding members to dialog: \(error.localizedDescription)")
                                            }
                                        }
                                    }) {
                                        NewConversationView(usedAsNew: false, selectedContact: self.$selectedNewMembers, newDialogID: self.$addNewMemberID)
                                            .environmentObject(self.auth)
                                    }
                                }
                                
                                if id <= 3 {
                                    DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, showProfile: self.$showProfile, contactID: Int(self.dialogModelMemebers[id]), isAdmin: self.dialogModel.adminID.contains(self.dialogModelMemebers[id]), isOwner: self.dialogModel.owner == self.dialogModelMemebers[id], currentUserIsPowerful: self.$currentUserIsPowerful, isLast: id == 3, isRemoving: self.$isRemoving)
                                        .environmentObject(self.auth)
                                }
                                
                                if self.dialogModelMemebers.count > 4 && id == 3 {
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
                                                
                                                Text("more members...")
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
                    .padding(.bottom, 15)
                    
                    //MARK: More Section
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

                                Text("More...")
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
                            .contentShape(Rectangle())
                        }.buttonStyle(changeBGButtonStyle())
                        .frame(minWidth: 100, maxWidth: Constants.screenWidth)
                        .actionSheet(isPresented: $showingMoreSheet) {
                            ActionSheet(title: Text(self.dialogModel.fullName), message: nil, buttons: [
                                            .default(Text(self.notificationsOn ? "Turn Notifications Off" : "Turn Notifications On"), action: {
                                                self.notificationsOn.toggle()
                                                Request.updateNotificationsSettings(forDialogID: self.dialogModel.id, enable: self.notificationsOn, successBlock: { result in
                                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                                    self.notificationsOn = result
                                                    self.notiType = "success"
                                                    self.notiText = "Successfully turned notifications settings \(result ? "on" : "off")."
                                                    self.showAlert.toggle()
                                                }, errorBlock: { error in
                                                    print("error setting notifications: \(error.localizedDescription)")
                                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                    self.notiType = "error"
                                                    self.notiText = "Error updating notification settings."
                                                    self.showAlert.toggle()
                                                })
                                            }), .destructive(Text(self.isOwner ? "Destroy Group" : "Leave Group"), action: {
                                                UserDefaults.standard.set(false, forKey: "localOpen")
                                                changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
                                                self.showingMoreSheet = false
                                                
                                                changeDialogRealmData.shared.deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.isOwner)
                                                print("done deleting dialog: \(self.dialogModel.id)")
                                            }), .cancel(Text("Done"))])
                        }.simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 60)
                                    
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
            if self.viewState == .fromDiscover {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: self.publicDialogModel.id ?? "") {
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
                            self.dialogModel = foundDialog

                            realm.add(foundDialog, update: .all)
                        })
                    } else {
                        self.dialogRelationship = .notSubscribed
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
                        
                        if let owner = self.publicDialogModel.owner {
                            dialog.owner = owner
                        }
                        self.dialogModel = dialog

                        try realm.safeWrite ({
                            realm.add(dialog, update: .all)
                        })
                    }
                } catch { self.dialogRelationship = .notSubscribed }
                
                if !self.dialogModelAdmins.contains(where: { $0 == self.dialogModel.owner }) && self.dialogModel.owner != 0 {
                    self.dialogModelAdmins.append(self.dialogModel.owner)
                }
            } else if self.viewState == .fromSearch {
                //not used
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
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                self.showAlert.toggle()
            }

//            let config = Realm.Configuration(schemaVersion: 1)
//            do {
//                let realm = try Realm(configuration: config)
//                if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: self.dialogModel.id) {
//                    //self.dialogRelationship = .subscribed
//                    //changeDialogRealmData.shared.observeFirebaseDialogReturn(dialogModel: foundDialog, completion: { _,_,_ in })
//                    self.dialogModel = foundDialog
////                    changeDialogRealmData.shared.observeFirebaseDialogReturn(dialogModel: self.dialogModel, completion: { (dialog, coverPhotoUrlz) in
////                        if let dia = dialog {
////                            self.coverPhotoUrl = coverPhotoUrlz ?? ""
////                            self.dialogModel = dia
////                        }
////                    })
//                    print("Foundd thisss: \(self.dialogModel.fullName)")
//                } else {
//                    print("did not find shitttt")
////                    changeDialogRealmData.shared.observeFirebaseDialogReturn(dialogModel: self.dialogModel, completion: { dialogz, _, _ in
////                        if let dia = dialogz {
////                            self.dialogModel = dia
////                        }
////
////                    })
//                }
//            } catch { }

            print("welcomeee...: \(self.dialogModel.fullName) && \(self.dialogModel.id)")
            self.isOwner = self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false
            self.isAdmin = self.dialogModel.adminID.contains(UserDefaults.standard.integer(forKey: "currentUserID")) ? true : false
            self.canEditGroup = self.isOwner || self.isAdmin
            self.currentUserIsPowerful = self.isOwner || self.isAdmin ? true : false
            self.dialogModelMemebers = self.dialogModel.occupentsID.filter { $0 != 0 }
            self.observePinnedMessages(dialogId: self.dialogModel.id)

//            for i in self.dialogModel.adminID {
//                if !self.dialogModelAdmins.contains(where: { $0 == i }) {
//                    self.dialogModelAdmins.append(i)
//                }
//            }
            
            if self.dialogModel.dialogType == "public" && self.dialogModel.id != "" {
                self.observeFirebase()
            }
////
//            if self.dialogModel.dialogType == "public" {
//                self.observePublicDetails()
//            }
            
            if self.dialogRelationship == .subscribed {
                self.loadNotifications()
            }
        }
    }
    
    func observeFirebase() {
        let user = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogModel.id)")
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
                            
                            if let owner = dict["owner"] as? Int, foundDialog.owner != owner {
                                foundDialog.owner = owner
                            }
                            
                            if let owner = dict["owner"] as? Int, !self.dialogModelAdmins.contains(where: { $0 == owner }) && owner != 0 {
                                self.dialogModelAdmins.append(owner)
                            }
                            
                            for childSnapshot in snapshot.children {
                                let childSnap = childSnapshot as! DataSnapshot
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
                            }

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
                        
                        if let owner = dict["owner"] as? Int {
                            dialog.owner = owner
                            if !self.dialogModelAdmins.contains(where: { $0 == owner }) && owner != 0 {
                                self.dialogModelAdmins.append(owner)
                            }
                        }
                        
                        //self.dialogModel.canMembersType = dict["canMembersType"] as? Bool ?? false
                        for childSnapshot in snapshot.children {
                            let childSnap = childSnapshot as! DataSnapshot
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
    
    func loadNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Request.notificationsSettings(forDialogID: self.dialogModel.id, successBlock: { notiResult in
                self.notificationsOn = notiResult
            })
        }
    }
    
    func addMore() -> some View {
        MoreContactsView(dismissView: self.$dismissView,
                         dialogModelMemebers: self.$dialogModelMemebers,
                         openNewDialogID: self.$openNewDialogID,
                         dialogModel: self.$dialogModel,
                         currentUserIsPowerful: self.$currentUserIsPowerful,
                         showProfile: self.$showProfile)
            .environmentObject(self.auth)
    }
    
    func moreMembers() -> some View {
        MoreContactsView(dismissView: self.$dismissView,
                         dialogModelMemebers: self.$dialogModelAdmins,
                         openNewDialogID: self.$openNewDialogID,
                         dialogModel: self.$dialogModel,
                         currentUserIsPowerful: self.$currentUserIsPowerful,
                         showProfile: self.$showProfile)
            .environmentObject(self.auth)
    }

    func observePinnedMessages(dialogId: String) {
        let msg = Database.database().reference().child("Dialogs").child(dialogId).child("pinned")

        msg.observe(.childAdded, with: { snapAdded in
            changeDialogRealmData.shared.addDialogPin(messageId: snapAdded.key, dialogID: self.dialogModel.id)
        })

        msg.observe(.childRemoved, with: { snapRemoved in
            changeDialogRealmData.shared.removeDialogPin(messageId: snapRemoved.key, dialogID: self.dialogModel.id)
        })

        print("the count of pinned messages are: \(self.dialogModel.pinMessages.count) for: \(dialogId)")
    }
    
    func observePublicDetails() {
        changeDialogRealmData.shared.observeFirebaseDialogReturn(dialogModel: self.dialogModel, completion: { (dialog, coverPhotoUrlz) in
            if let dia = dialog {
                print("the returned dialog is nowww: \(dia.fullName) the dialog is pulled in and had the right data: \(dia)")
                self.dialogModel = dia
//                self.dialogModel.id = dia.id
//                self.dialogModel.coverPhoto = dia.coverPhoto
//                self.dialogModel.canMembersType = dia.canMembersType
//                self.dialogModel.publicTags.removeAll()
//                for tag in dia.publicTags {
//                    self.dialogModel.publicTags.append(tag)
//                }

                for tag in dia.publicTags {
                    if !self.publicTags.contains(tag) {
                        self.publicTags.append(tag)
                    }
                }

                if dia.dialogType == "group" {
                    self.dialogRelationship = .group
                }
                
                Request.updateDialog(withID: self.dialogModel.id, update: UpdateChatDialogParameters(), successBlock: { dialog in
                    print("fetched remote dialog")
                    self.dialogModel.fullName = dialog.name ?? "No Dialog Name"
                    self.dialogModel.lastMessage = dialog.lastMessageText ?? "no messages sent"
                    self.dialogModel.lastMessageDate = dialog.lastMessageDate ?? Date.init(timeIntervalSinceReferenceDate: 86400)
                    self.dialogModel.notificationCount = Int(dialog.unreadMessagesCount)
                    self.dialogModel.createdAt = dialog.createdAt ?? Date()
                    self.dialogModel.owner = Int(dialog.userID)
                    
                    for occu in dialog.occupantIDs ?? [] {
                        self.dialogModel.occupentsID.append(Int(truncating: occu))
                    }

                    if dialog.type == .private { self.dialogModel.dialogType = "private" }
                    else if dialog.type == .group {
                        self.dialogModel.dialogType = "group"
                        self.dialogRelationship = .group
                    }
                    else if dialog.type == .broadcast { self.dialogModel.dialogType = "broadcast" }
                    else if dialog.type == .public { self.dialogModel.dialogType = "public" }

                    if dialog.type == .group || dialog.type == .public {
                        for admin in dialog.adminsIDs ?? [] {
                            self.dialogModel.adminID.append(Int(truncating: admin))
                        }

                        if let publicUrl = Blob.publicUrl(forFileUID: dialog.photo ?? "") {
                            self.dialogModel.avatar = publicUrl
                        }

                        self.dialogModel.bio = dialog.dialogDescription ?? ""
                    }

                    if self.dialogModel.id == UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" && UserDefaults.standard.bool(forKey: "localOpen") {
                        self.dialogModel.isOpen = true
                    }
                })
            } else {
                print("the dialog is already saved and just updated it...should refresh")
                if self.currentUserIsPowerful || self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") {
                    self.dialogRelationship = .subscribed
                } else {
                    self.dialogRelationship = .subscribed
                }
                
                //self.coverPhotoUrl = coverPhotoUrlz ?? ""
            }
        })
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
    @State private var isProfileBioOpen: Bool = false
    @State private var moreBioAction = false
    
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
                        
                        Text("\(self.dialogModel.occupentsID.count) " + (self.dialogModel.dialogType == "public" ? "members" : "people"))
                            .font(.subheadline)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .offset(y: -2.5)

                        HStack(alignment: .center, spacing: 10) {
                            ForEach(self.publicTags, id: \.self) { tag in
                                Button(action: {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }, label: {
                                    Text("#" + "\(tag)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 10)
                                        .foregroundColor(Color("disabledButton"))
                                        .background(RoundedRectangle(cornerRadius: 7).stroke(Color("interactions_selected"), lineWidth: 2.5).background(Color("interactions_selected").opacity(0.3)).cornerRadius(7))
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
                                    .clipShape(Circle())
                                    .frame(width: self.groupOccUserAvatar.count > 2 ? 50 : self.groupOccUserAvatar.count > 1 ? 70 : 100, height: self.groupOccUserAvatar.count > 2 ? 50 : self.groupOccUserAvatar.count > 1 ? 70 : 100, alignment: .center)
                                    
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
