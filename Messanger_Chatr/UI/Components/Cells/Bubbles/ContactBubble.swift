//
//  ContactBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct ContactBubble: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var viewModel: ChatMessageViewModel
    @Binding var chatContact: Int
    @State var showContact: Bool = false
    var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = false
    @State var contact: ContactStruct = ContactStruct()
    @State var contactRelationship: visitContactRelationship = .unknown
    
    var body: some View {
        ZStack() {
            if self.message.messageState != .deleted {
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.showContact.toggle()
                    }, label: {
                        HStack {
                            ZStack(alignment: .center) {
                                Circle()
                                    .frame(width: 35, height: 35, alignment: .center)
                                    .foregroundColor(Color("bgColor"))
                                
                                WebImage(url: URL(string: self.contact.avatar))
                                    .resizable()
                                    .placeholder{ Image("empty-profile").resizable().frame(width: 50, height: 50, alignment: .bottom).scaledToFill() }
                                    .indicator(.activity)
                                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                    .scaledToFill()
                                    .clipShape(Circle())
                                    .frame(width: 50, height: 50, alignment: .center)
                                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)

                            }
                            
                            VStack(alignment: .leading) {
                                Text(self.contact.fullName)
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Text(contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            if self.contactRelationship == .pendingRequestForYou {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    Chat.instance.confirmAddContactRequest(UInt(self.contact.id)) { (error) in
                                        print("accepted new contact:")
                                        self.contactRelationship = .contact
                                        self.auth.profile.removeContactRequest(userID: UInt(self.contact.id))

                                        let event = Event()
                                        event.notificationType = .push
                                        event.usersIDs = [NSNumber(value: self.contact.id)]
                                        event.type = .oneShot

                                        var pushParameters = [String : String]()
                                        pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user")) accepted your contact request."
                                        pushParameters["ios_sound"] = "app_sound.wav"

                                        if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                                                    options: .prettyPrinted) {
                                          let jsonString = String(bytes: jsonData,
                                                                  encoding: String.Encoding.utf8)

                                          event.message = jsonString

                                          Request.createEvent(event, successBlock: {(events) in
                                            print("sent push notification to user")
                                          }, errorBlock: {(error) in
                                            print("error in sending push noti: \(error.localizedDescription)")
                                          })
                                        }
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 40, height: 40, alignment: .center)
                                            .foregroundColor(.clear)
                                            .background(Constants.blueGradient)
                                            .cornerRadius(10)
                                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                        
                                        Image(systemName: "person.crop.circle.badge.checkmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 20, alignment: .center)
                                            .foregroundColor(.white)
                                            .padding(3)
                                            .offset(x: -2)
                                    }
                                }
                                
                                Button(action: {
                                    print("reject")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    Chat.instance.rejectAddContactRequest(UInt(self.contact.id)) { (error) in
                                        if error != nil {
                                            print("error rejecting contact: \(String(describing: error?.localizedDescription))")
                                        } else {
                                            print("rejected contact")
                                            self.contactRelationship = .unknown
                                            self.auth.profile.removeContactRequest(userID: UInt(self.contact.id))
                                        }
                                    }
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: 40, height: 40, alignment: .center)
                                            .foregroundColor(.clear)
                                            .background(Color("alertRed"))
                                            .cornerRadius(10)
                                            .shadow(color: Color("alertRed").opacity(0.2), radius: 10, x: 0, y: 5)
                                        
                                        Image(systemName: "person.fill.xmark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 18, alignment: .center)
                                            .foregroundColor(.white)
                                            .padding(3)
                                    }
                                }
                            }

                            Image(systemName: "chevron.right")
                                .resizable()
                                .font(Font.title.weight(.bold))
                                .foregroundColor(.secondary)
                                .frame(width: 7, height: 10, alignment: .center)
                        }.frame(width: Constants.screenWidth * 0.6, height: 70)
                        .padding(.horizontal)
                        //.clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        //.contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    }).buttonStyle(highlightedButtonStyle())
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 14)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2.5))
                    .sheet(isPresented: self.$showContact, onDismiss: {
                        if self.chatContact != 0 && self.chatContact != self.message.senderID {
                           print("need to open Chat view!!")
                        }
                    }) {
                        NavigationView {
                            VisitContactView(fromDialogCell: true, newMessage: self.$chatContact, dismissView: self.$showContact, viewState: .fromRequests, contactRelationship: self.contactRelationship, contact: self.contact)
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                }.onAppear() {
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.contactID) {
                            self.contact = foundContact
                            self.contactRelationship = .contact
                        } else {
                            Request.users(withIDs: [NSNumber(value: self.message.contactID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
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
                                        self.contactRelationship = .notContact
                                        
                                        if ((self.auth.profile.results.first?.contactRequests.contains(self.contact.id)) != nil) {
                                            self.contactRelationship = .pendingRequest
                                        } else if Chat.instance.contactList?.pendingApproval.count ?? 0 > 0 {
                                            for con in Chat.instance.contactList?.pendingApproval ?? [] {
                                                if con.userID == UInt(self.contact.id) {
                                                    self.contactRelationship = .pendingRequest
                                                    break
                                                }
                                            }
                                        }
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
    }
}
