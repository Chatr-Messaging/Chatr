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
    @Binding var chatContact: Int
    @State var showContact: Bool = false
    var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    var hasPrior: Bool = false
    @State var avatar: String = ""
    @State var contact: ContactStruct = ContactStruct()
    @State var contactRelationship: visitContactRelationship = .unknown
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
            if self.message.messageState == .deleted {
                ZStack {
                    Text("deleted")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(self.message.messageState != .deleted ? messagePosition == .right ? .white : .primary : .secondary)
                        .padding(.vertical, 8)
                        .lineLimit(nil)
                }.padding(.horizontal, 15)
                .background(self.messagePosition == .right && self.message.messageState != .deleted ? LinearGradient(
                    gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                    startPoint: .top, endPoint: .bottom) : LinearGradient(
                        gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: self.messagePosition == .right && self.message.messageState != .deleted ? Color.blue.opacity(0.2) : Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                
            }
            
            if self.message.messageState != .deleted {
                ZStack(alignment: .center) {
                    BlurView(style: .systemThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 14)
                    
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
                                        .placeholder{ Image("empty-profile").resizable().frame(width: 45, height: 45, alignment: .bottom).scaledToFill() }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 45, height: 45, alignment: .center)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(self.contact.fullName)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(self.contact.phoneNumber.format(phoneNumber: String(self.contact.phoneNumber.dropFirst())))
                                        .font(.subheadline)
                                        .fontWeight(.regular)
                                        .lineLimit(1)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                if self.contactRelationship == .pendingRequestForYou {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                            }.contentShape(Rectangle())
                            .padding(.horizontal)
                        }).buttonStyle(PlainButtonStyle())
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
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .contextMenu {
                            VStack {
                                if messagePosition == .right {
                                    if self.message.messageState != .deleted {
                                        Button(action: {
                                            self.auth.selectedConnectyDialog?.removeMessage(withID: self.message.id) { (error) in
                                                if error != nil {
                                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                } else {
                                                    changeMessageRealmData.updateMessageState(messageID: self.message.id, messageState: .deleted)
                                                }
                                            }
                                        }) { HStack {
                                            Image(systemName: "trash")
                                            Text("Delete")
                                                .foregroundColor(.red) }
                                        }
                                    }
                                    Button(action: {
                                        print("Edit Message")
                                    }) { HStack {
                                        Image(systemName: "pencil")
                                        Text("Edit") }
                                    }
                                }
                                Button(action: {
                                    print("Share Message")
                                }) { HStack {
                                    Image(systemName: "arrowshape.turn.up.left")
                                    Text("Share") }
                                }
                                Button(action: {
                                    print("Copy Message")
                                }) { HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy Text") }
                                }
        //                            Button(action: {
        //                                print("Like Message")
        //                            }) { HStack {
        //                                Image(systemName: "heart")
        //                                Text("Like") }
        //                            }
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
                }.frame(width: Constants.screenWidth * 0.7, height: 70)
                .padding(.bottom, self.hasPrior ? 0 : 15)
            }
            
            HStack {
                if messagePosition == .right { Spacer() }
                
                Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right))
                    .foregroundColor(self.message.messageState == .error ? .red : .gray)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .multilineTextAlignment(messagePosition == .right ? .trailing : .leading)
                    .opacity(self.hasPrior && self.message.messageState != .error ? 0 : 1)
                
                if messagePosition == .left { Spacer() }
            }
            
            WebImage(url: URL(string: self.avatar))
                .resizable()
                .placeholder{ Image("empty-profile").resizable().frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom).scaledToFill() }
                .indicator(.activity)
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom)
                .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2))
                .opacity(self.hasPrior ? 0 : 1)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
        }.onAppear() {
            if self.message.senderID == UserDefaults.standard.integer(forKey: "currentUserID") {
                //get profile image
                self.avatar = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.avatar ?? ""
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                        self.avatar = foundContact.avatar
                    } else {
                        Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            self.avatar = PersistenceManager().getCubeProfileImage(usersID: users.first!) ?? ""
                        })
                    }
                } catch {
                    
                }
            }
            
            
            
        }
    }
}
