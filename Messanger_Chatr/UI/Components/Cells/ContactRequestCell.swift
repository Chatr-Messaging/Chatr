//
//  ContactRequestCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/7/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct ContactRequestCell: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var selectedNewDialog: Int
    @State var contactID: Int
    @State var contact: ContactStruct = ContactStruct()
    @State var contactRelationship: visitContactRelationship = .unknown

    var body: some View {
        HStack {
            NavigationLink(destination: VisitContactView(newMessage: self.$selectedNewDialog, dismissView: self.$dismissView, viewState: .fromRequests, contactRelationship: self.contactRelationship, contact: self.contact).edgesIgnoringSafeArea(.all).environmentObject(self.auth)) {
                HStack {
                    WebImage(url: URL(string: self.contact.avatar))
                        .resizable()
                        .placeholder{ Image(systemName: "person.fill") }
                        .indicator(.activity)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 45, height: 45, alignment: .center)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 8)
                    
                    VStack(alignment: .leading) {
                        Text(self.contact.fullName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.primary)
                            .lineLimit(1)
                            .animation(nil)
                        
                        Text(self.contact.phoneNumber.format(phoneNumber: String(self.contact.phoneNumber.dropFirst())))
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .animation(nil)
                    }
                    Spacer()
                    
                    if self.contactRelationship == .pendingRequestForYou {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Chat.instance.rejectAddContactRequest(UInt(self.contact.id)) { (error) in
                                if error == nil {
                                    self.contactRelationship = .unknown
                                    self.auth.profile.removeContactRequest(userID: UInt(self.contact.id))
                                }
                            }
                        }) {
                            Image(systemName: "person.crop.circle.badge.xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 18, alignment: .center)
                                .foregroundColor(Color("alertRed"))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 6)
                                .background(Color("alertRed").opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("alertRed"), lineWidth: 1)
                                )
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                            Text("Accept")
                                .fontWeight(.medium)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                        }
                    }

                    Image(systemName: "chevron.right")
                        .resizable()
                        .font(Font.title.weight(.bold))
                        .foregroundColor(.secondary)
                        .frame(width: 7, height: 10, alignment: .center)
                }.contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
        }.onAppear() {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.contactID) {
                    self.contact = foundContact
                } else {
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
                                newContact.isPremium = contact.isPremium
                                newContact.emailAddress = firstUser.email ?? "empty email address"
                                newContact.website = firstUser.website ?? "empty website"

                                self.contact = newContact
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
