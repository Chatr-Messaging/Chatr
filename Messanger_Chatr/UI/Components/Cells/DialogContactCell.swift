//
//  DialogContactCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/18/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct DialogContactCell: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var showAlert: Bool
    @Binding var notiType: String
    @Binding var notiText: String
    @Binding var dismissView: Bool
    @Binding var openNewDialogID: Int
    @State var contactID: Int
    @State private var actionState: Int? = 0
    @State private var openActionSheet: Bool = false
    @State var contact: ContactStruct = ContactStruct()
    @State var contactRelationship: visitContactRelationship = .unknown
    @State var connectyContact: User = User()
    @State var isAdmin: Bool = false
    @State var isOwner: Bool = false
    @Binding var currentUserIsPowerful: Bool
    @State var isLast: Bool = false
    @Binding var isRemoving: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            NavigationLink(destination: VisitContactView(newMessage: self.$openNewDialogID, dismissView: self.$dismissView, viewState: .fromSearch, contactRelationship: self.contactRelationship, contact: self.contact, connectyContact: self.connectyContact).edgesIgnoringSafeArea(.all).environmentObject(self.auth), tag: 1, selection: self.$actionState) {
                EmptyView()
            }
            Button(action: {
                if self.currentUserIsPowerful && !self.isOwner {
                    self.openActionSheet.toggle()
                } else {
                    self.actionState = 1
                }
            }) {
                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        ZStack() {
                            if let avitarURL = contact.avatar {
                                WebImage(url: URL(string: avitarURL))
                                    .resizable()
                                    .placeholder{ Image("empty-profile").resizable().frame(width: 40, height: 40, alignment: .center).scaledToFill() }
                                    .indicator(.activity)
                                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 5)
                            } else {
                                ZStack(alignment: .center) {
                                    Circle()
                                        .frame(width: 40, height: 40, alignment: .center)
                                        .foregroundColor(Color("bgColor"))
                                    
                                    Text("".firstLeters(text: contact.fullName))
                                        .font(.system(size: 14))
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if self.contact.quickSnaps.count > 0 {
                                Circle()
                                    .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.clear)
                            }
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 10, height: 10)
                                .foregroundColor(.green)
                                .opacity(contact.isOnline ? 1 : 0)
                                .offset(x: 12, y: 15)
                        }
                        
                        VStack(alignment: .leading) {
                            HStack(spacing: 5) {
                                if contact.isPremium {
                                    Image(systemName: "checkmark.seal")
                                        .resizable()
                                        .scaledToFit()
                                        .font(Font.title.weight(.medium))
                                        .frame(width: 16, height: 16, alignment: .center)
                                        .foregroundColor(Color("main_blue"))
                                }
                                                                                            
                                Text(contact.fullName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }.offset(y: contact.isPremium ? 3 : 0)
                            
                            Text(contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .offset(y: contact.isPremium ? -3 : 0)
                        }
                        
                        Spacer()
                        
                        Text(self.isOwner ? "Owner" : self.isAdmin ? "Admin" : self.currentUserIsPowerful ? "Add Admin" : "")
                            .font(.subheadline)
                            .foregroundColor((self.isOwner || self.isAdmin) ? .secondary : .blue)
                        
                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.bold))
                            .scaledToFit()
                            .frame(width: 7, height: 15, alignment: .center)
                            .foregroundColor(.secondary)
                    }.padding(.horizontal)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    
                    Divider()
                        .frame(width: Constants.screenWidth - 80)
                        .offset(x: 40)
                        .opacity(!self.isLast ? 1 : 0)
                }
            }.buttonStyle(changeBGButtonStyle())
            .actionSheet(isPresented: self.$openActionSheet) {
                ActionSheet(title: Text("\(self.contact.fullName)'s options:"), message: nil, buttons: [
                    .default(Text("View Profile")) {
                        self.actionState = 1
                    },
                    .default(Text(self.isAdmin ? "Remove Admin" : "Add Admin")) {
                        if !self.isAdmin {
                            Request.addAdminsToDialog(withID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", adminsUserIDs: [NSNumber(value: self.contact.id)], successBlock: { (updatedDialog) in
                                changeDialogRealmData().insertDialogs([updatedDialog]) {
                                    self.isAdmin = true
                                    self.isOwner = false
                                    print("Success adding contact as admin!")
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.notiType = "success"
                                    self.notiText = "Successfully added \(self.contact.fullName) as admin."
                                    self.showAlert.toggle()
                                    self.auth.sendPushNoti(userIDs: [NSNumber(value: self.contact.id)], title: "Added Admin", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") added you as an admin 🥳")
                                }
                            }) { (error) in
                                print("Error adding contact as admin: \(error.localizedDescription) && \(UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")")
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                self.notiType = "error"
                                self.notiText = "Error adding \(self.contact.fullName) as admin."
                                self.showAlert.toggle()
                            }
                        } else {
                            Request.removeAdminsFromDialog(withID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", adminsUserIDs: [NSNumber(value: self.contact.id)], successBlock: { (updatedDialog) in
                                changeDialogRealmData().insertDialogs([updatedDialog]) {
                                    self.isAdmin = false
                                    self.isOwner = false
                                    print("Success removing contact as admin!")
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.notiType = "success"
                                    self.notiText = "Successfully removed \(self.contact.fullName) as admin."
                                    self.showAlert.toggle()
                                    self.auth.sendPushNoti(userIDs: [NSNumber(value: self.contact.id)], title: "Removed Admin", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") removed you as an admin")
                                }
                            }) { (error) in
                                print("Error removing contact as admin: \(error.localizedDescription)")
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                self.notiType = "error"
                                self.notiText = "Error removing \(self.contact.fullName) as admin."
                                self.showAlert.toggle()
                            }
                        }
                    },
                    .destructive(Text("Remove From Group"), action: {
                        let updateParameters = UpdateChatDialogParameters()
                        updateParameters.occupantsIDsToRemove = [NSNumber(value: self.contact.id)]
                        Request.updateDialog(withID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", update: updateParameters, successBlock: { (updatedDialog) in
                            changeDialogRealmData().insertDialogs([updatedDialog]) {
                                print("Success removing contact from dialog")
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                self.notiType = "success"
                                self.notiText = "Successfully removed \(self.contact.fullName) from group chat."
                                self.showAlert.toggle()
                                self.auth.sendPushNoti(userIDs: [NSNumber(value: self.contact.id)], title: "Removed from Group", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") removed you from the group chat")
                            }
                        }) { (error) in
                            print("Error removing contact from dialog: \(error.localizedDescription)")
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            self.notiType = "error"
                            self.notiText = "Error removing \(self.contact.fullName) from group chat."
                            self.showAlert.toggle()
                        }
                    }),
                    .cancel()
                ])
            }
  
        }.simultaneousGesture(TapGesture()
                                .onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                })
        .onAppear() {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.contactID) {
                    self.contact = foundContact
                    self.connectyContact.id = UInt(foundContact.id)
                    print("DialogContact Cellid:\(self.contactID) - found contact: \(foundContact.fullName) & \(foundContact.avatar)")
                }
                
                if self.contact.id == 0 || self.contact.avatar == "" {
                    print("not found in contact realm \(self.contactID)")
                    Request.users(withIDs: [NSNumber(value: self.contactID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                        changeContactsRealmData().observeFirebaseContactReturn(contactID: Int(users.first?.id ?? 0), completion: { contact in
                            if let firstUser = users.first {
                                let newContact = ContactStruct()
                                newContact.id = Int(firstUser.id)
                                newContact.fullName = firstUser.fullName ?? ""
                                newContact.phoneNumber = firstUser.phone ?? "empty phone number"
                                newContact.lastOnline = firstUser.lastRequestAt ?? Date()
                                newContact.createdAccount = firstUser.createdAt ?? Date()
                                newContact.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: firstUser) ?? ""
                                newContact.bio = contact.bio
                                newContact.facebook = contact.facebook
                                newContact.twitter = contact.twitter
                                newContact.instagramAccessToken = contact.instagramAccessToken
                                newContact.instagramId = contact.instagramId
                                newContact.isPremium = contact.isPremium
                                newContact.emailAddress = firstUser.email ?? "empty email address"
                                newContact.website = firstUser.website ?? "empty website"

                                self.contact = newContact
                                self.connectyContact.id = firstUser.id
                            }
                        })
                    }) { (error) in

                    }
                }
            } catch {
                
            }
        }
    }
}
