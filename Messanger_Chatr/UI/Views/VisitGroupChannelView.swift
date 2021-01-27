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
import PopupView

struct VisitGroupChannelView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var dismissView: Bool
    @Binding var openNewDialogID: Int
    @State var groupOccUserAvatar: [String] = []
    @State var fromDialogCell: Bool = false
    @State var viewState: visitUserState = .unknown
    @State var dialogRelationship: visitDialogRelationship = .unknown
    @State var dialogModel: DialogStruct = DialogStruct()
    @State var dialogModelMemebers: [Int] = []
    @State var dialogModelAdmins: [Int] = []
    @State var selectedNewMembers: [Int] = []
    @State var addNewMemberID: String = ""
    @State var currentUserIsPowerful: Bool = false
    @State private var isProfileImgOpen: Bool = false
    @State private var isProfileBioOpen: Bool = false
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

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    //MARK: Top Profile
                    VStack {
                        ZStack(alignment: .top) {
                            VStack(alignment: .center) {
                                if isOwner {
                                    NavigationLink(destination: self.addMore()) {
                                        HStack() {
                                            Spacer()

                                            Text("Edit Group")
                                                .font(.subheadline)
                                                .fontWeight(.none)
                                                .foregroundColor(.blue)

                                            Image(systemName: "chevron.right")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 7, height: 12)
                                                .foregroundColor(.blue)
                                        }.padding(.top, 15)
                                        .padding(.trailing)
                                    }
                                }

                                VStack(alignment: .center) {
                                    VStack(alignment: .center) {
                                        Text(self.dialogModel.fullName)
                                            .font(.system(size: 22))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text("\(self.dialogModel.occupentsID.count) total members")
                                            .font(.subheadline)
                                            .fontWeight(.none)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }.padding(.top, 10)
                                    .padding(.bottom, self.dialogModel.bio == "" ? 15 : 0 )
                                    
                                    //MARK: Bio Section
                                    if self.dialogModel.bio != "" {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {
                                                Text(self.dialogModel.bio)
                                                    .font(.subheadline)
                                                    .fontWeight(.none)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(self.isProfileBioOpen ? 20 : 5)
                                                    .padding(.top, 3)
                                                    .padding(.bottom, self.dialogModel.bio.count > 220 ? 10 : 5)
                                                
                                                if self.dialogModel.bio.count > 220 {
                                                    Button(action: {
                                                        print("more...")
                                                        self.isProfileBioOpen.toggle()
                                                    }, label: {
                                                        Text(self.isProfileBioOpen ? "less..." : "more...")
                                                            .font(.subheadline)
                                                            .fontWeight(.none)
                                                            .foregroundColor(.secondary)
                                                    }).buttonStyle(ClickButtonStyle())
                                                    .offset(y: -2)
                                                    .padding(.bottom, self.dialogModel.bio.count > 220 ? 0 : 8)
                                                }
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                                .padding(.top, isOwner ? 10 : 45)
                                .padding(.bottom, 5)
                            }.frame(width: Constants.screenWidth - 40)
                            .background(Color("buttonColor"))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 5)
                            .padding(.all)
                            .padding(.top, 50)
                            
                            if self.dialogModel.dialogType == "public" {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isProfileImgOpen.toggle()
                                }) {
                                    WebImage(url: URL(string: self.dialogModel.avatar))
                                        .resizable()
                                        .placeholder{ Image(systemName: "person.fill") }
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.15))
                                        .scaledToFill()
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .frame(width: 110, height: 110, alignment: .center)
                                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                                }.buttonStyle(ClickButtonStyle())
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
                    }.padding(.top, 40)
                    .padding(.bottom, 15)
                    
                    //MARK: Action Buttons
                    HStack(alignment: .center, spacing: self.dialogRelationship == .subscribed ? 40 : 20) {
                        if self.dialogRelationship == .notSubscribed && self.dialogModel.dialogType == "public" {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: 160, height: 45, alignment: .center)
                                        .foregroundColor(.clear)
                                        .background(Constants.blueGradient)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 5)
                                    
                                    HStack(alignment: .center) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 24, alignment: .center)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                            .padding(5)
                                        
                                        Text("Join")
                                            .font(.none)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 5)
                                    }
                                }
                            }.buttonStyle(ClickButtonStyle())
                        }
                    }
                    
                    //MARK: Action Section
//                    HStack {
//                        Text("ACTIONS:")
//                            .font(.caption)
//                            .fontWeight(.regular)
//                            .foregroundColor(.secondary)
//                            .padding(.horizontal)
//                            .padding(.horizontal)
//                            .offset(y: 2)
//                        Spacer()
//                    }
                    
//                    VStack(alignment: .center) {
//                        VStack(spacing: 0) {
//                            Text("hello")
//                            //QR Code button
//                            NavigationLink(destination:
//                                            ShareProfileView(dimissView: self.$dismissView,
//                                                             contactID: self.dialogModel.id,
//                                                             contactFullName: self.dialogModel.fullName,
//                                                             contactAvatar: self.dialogModel.avatar)
//                                            .environmentObject(self.auth)) {
//                                VStack(alignment: .trailing, spacing: 0) {
//                                    HStack {
//                                        Image(systemName: "qrcode")
//                                            .resizable()
//                                            .scaledToFit()
//                                            .foregroundColor(Color.primary)
//                                            .frame(width: 20, height: 20, alignment: .center)
//                                            .padding(.trailing, 5)
//
//                                        Text("Share Profile")
//                                            .font(.none)
//                                            .fontWeight(.none)
//                                            .foregroundColor(.primary)
//
//                                        Spacer()
//                                        Image(systemName: "chevron.right")
//                                            .resizable()
//                                            .font(Font.title.weight(.bold))
//                                            .scaledToFit()
//                                            .frame(width: 7, height: 15, alignment: .center)
//                                            .foregroundColor(.secondary)
//                                    }.padding(.horizontal)
//                                    .padding(.vertical, 12.5)
//
//                                    Divider()
//                                        .frame(width: Constants.screenWidth - 80)
//                                }
//                            }.buttonStyle(changeBGButtonStyle())
                            
//                            Button(action: {
//                                print("Forward Group Chat")
//                            }) {
//                                HStack {
//                                    Image(systemName: "arrowshape.turn.up.left")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .foregroundColor(.primary)
//                                        .frame(width: 20, height: 20, alignment: .center)
//                                        .padding(.trailing, 5)
//
//                                    Text("Forward Contact")
//                                        .font(.none)
//                                        .fontWeight(.none)
//                                        .foregroundColor(.primary)
//
//                                    Spacer()
//                                    Image(systemName: "chevron.right")
//                                        .resizable()
//                                        .font(Font.title.weight(.bold))
//                                        .scaledToFit()
//                                        .frame(width: 7, height: 15, alignment: .center)
//                                        .foregroundColor(.secondary)
//                                }.padding(.horizontal)
//                                .padding(.vertical, 12.5)
//                            }.buttonStyle(changeBGButtonStyle())
//                        }
//                    }.background(Color("buttonColor"))
//                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
//                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
//                    .padding(.horizontal)
//                    .padding(.bottom, 10)
                    
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
                            DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, contactID: Int(id), isAdmin: self.dialogModel.adminID.contains(Int(id)) ? true : false, isOwner: self.dialogModel.owner == id ? true : false, currentUserIsPowerful: self.$currentUserIsPowerful, isLast: self.dialogModelAdmins.last == id, isRemoving: self.$isRemoving)
                                .environmentObject(self.auth)

                            if self.dialogModelAdmins.last != id {
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 40)
                            } else if self.dialogModelAdmins.count > 4 {
                                NavigationLink(destination: Text("more")) {
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 80)
                                            .offset(x: 20)
                                        
                                        HStack {
                                            Text("more admins...")
                                                .font(.subheadline)
                                                .foregroundColor(Color.secondary)
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
                    HStack(alignment: .bottom) {
                        Text("\(self.dialogModel.occupentsID.count) TOTAL MEMBERS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        ForEach(self.dialogModelMemebers.indices, id: \.self) { id in
                            VStack(alignment: .trailing, spacing: 0) {
                                if id == 0 {
                                    Button(action: {
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
                                                changeDialogRealmData().insertDialogs([updatedDialog]) { }
                                                occu.removeAll()
                                                self.addNewMemberID = ""
                                                self.selectedNewMembers.removeAll()
                                                self.notiType = "success"
                                                self.notiText = occu.count == 0 ? "Successfully added a new member" : "Successfully added new members."
                                                self.showAlert = true
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
                                    DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, contactID: Int(self.dialogModelMemebers[id]), isAdmin: self.dialogModel.adminID.contains(self.dialogModelMemebers[id]), isOwner: self.dialogModel.owner == self.dialogModelMemebers[id], currentUserIsPowerful: self.$currentUserIsPowerful, isLast: id == 3, isRemoving: self.$isRemoving)
                                        .environmentObject(self.auth)
                                }
                                
                                if self.dialogModelMemebers.count > 4 && id == 3 {
                                    NavigationLink(destination: self.addMore()) {
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
                        .frame(minWidth: 100, maxWidth: .infinity)
                        .actionSheet(isPresented: $showingMoreSheet) {
                            ActionSheet(title: Text("More..."), message: nil, buttons: [
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
                                                changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
                                                self.showingMoreSheet = false
                                                
                                                changeDialogRealmData().deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.isOwner)
                                                print("done deleting dialog: \(self.dialogModel.id)")
                                            }), .cancel(Text("Done"))])
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                                    
                    //MARK: Footer Section
                    FooterInformation(middleText: "Created: \(self.dialogModel.createdAt.getFullElapsedInterval())")
                        .padding(.vertical)

                }.navigationBarItems(leading:
                                    Button(action: {
                                        print("Done btn tap \(self.fromDialogCell)")
                                        withAnimation {
                                            self.presentationMode.wrappedValue.dismiss()
                                        }
                                    }) {
                                        Text(self.fromDialogCell ? "Done" : "")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                    }.disabled(self.fromDialogCell ? false : true))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                Request.notificationsSettings(forDialogID: self.dialogModel.id, successBlock: { notiResult in
                    self.notificationsOn = notiResult
                })
            }
            self.dialogModelMemebers.removeAll()
            self.dialogModelAdmins.removeAll()
            self.isOwner = self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false
            self.isAdmin = self.dialogModel.adminID.contains(UserDefaults.standard.integer(forKey: "currentUserID")) ? true : false
            self.currentUserIsPowerful = self.isOwner || self.isAdmin ? true : false
            self.dialogModelMemebers = self.dialogModel.occupentsID.filter { $0 != UserDefaults.standard.integer(forKey: "currentUserID") }
            self.dialogModelAdmins = self.dialogModel.occupentsID.filter { $0 == self.dialogModel.owner || self.dialogModel.adminID.contains($0)}
        }
    }
    
    func addMore() -> some View {
        MoreContactsView(dismissView: self.$dismissView,
                         dialogModelMemebers: self.$dialogModelMemebers,
                         openNewDialogID: self.$openNewDialogID,
                         dialogModel: self.$dialogModel,
                         currentUserIsPowerful: self.$currentUserIsPowerful)
            .environmentObject(self.auth)
    }
}
