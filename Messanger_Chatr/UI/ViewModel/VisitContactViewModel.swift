//
//  VisitContactViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/11/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import ConnectyCube
import RealmSwift

class VisitContactViewModel: ObservableObject {
    private let instagramApi = InstagramApi.shared
    private var cancellables = Set<AnyCancellable>()
    @Published var igMedia: [InstagramMedia] = []
    @Published var username: String = ""
    
    init() {
        instagramApi.$igMedia
            .assign(to: \.igMedia, on: self)
            .store(in: &cancellables)
        
        instagramApi.$username
            .assign(to: \.username, on: self)
            .store(in: &cancellables)
    }
    
    func loadInstagramImages(testUser: InstagramTestUser) {
        if testUser.user_id != 0 && testUser.access_token != "" {
            self.instagramApi.pullInstagramImages(testUser: testUser)
        }
    }
    
    func pullInstagramUser(testUser: InstagramTestUser, completion: @escaping (String) -> Void) {
        self.instagramApi.getInstagramUser(testUserData: testUser) { (user) in
            completion(user.username)
        }
    }
    
    func addContact(contactRelationship: visitContactRelationship, contactId: Int, completion: @escaping (visitContactRelationship) -> Void) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        Chat.instance.addUser(toContactListRequest: UInt(contactId)) { (error) in
            if error != nil {
                print("error adding user: \(String(describing: error?.localizedDescription))")
            } else {
                let event = Event()
                event.notificationType = .push
                event.usersIDs = [NSNumber(value: contactId)]
                event.type = .oneShot

                var pushParameters = [String : String]()
                pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") sent you a contact request."
                pushParameters["ios_sound"] = "app_sound.wav"

                if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
                    let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

                    event.message = jsonString

                    Request.createEvent(event, successBlock: { _ in
                    }, errorBlock: { (error) in
                    print("error in sending push noti: \(error.localizedDescription)")
                    })
                    completion(.pendingRequest)
                }
            }
        }
    }
    
    func openFacebookApp(screenName: String) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        let appURL = URL(string: "fb://profile/\(screenName)")!
        let application = UIApplication.shared

        if application.canOpenURL(appURL) {
            application.open(appURL)
        } else {
            let webURL = URL(string: "https://facebook.com/\(screenName)")!
            application.open(webURL)
        }
    }
    
    func openTwitterApp(screenName: String) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
        let webURL = NSURL(string: "https://twitter.com/\(screenName)")!
        let application = UIApplication.shared

        if application.canOpenURL(appURL as URL) {
             application.open(appURL as URL)
        } else {
             application.open(webURL as URL)
        }
    }
    
    func openInstagramApp() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        let instagramHooks = "instagram://user?username=\(self.username)"
        let instagramUrl = NSURL(string: instagramHooks)
        if UIApplication.shared.canOpenURL(instagramUrl! as URL) {
            UIApplication.shared.open(instagramUrl! as URL)
        } else {
            UIApplication.shared.open(NSURL(string: "http://instagram.com/\(self.username)")! as URL)
        }
    }
    
    func updateContactFavouriteStatus(userID: UInt, favourite: Bool) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: userID) {
                //Contact is in Realm...
                try realm.safeWrite ({
                    realmContact.isFavourite = favourite
                    realm.add(realmContact, update: .all)
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func trashContactRequest(visitContactRelationship: visitContactRelationship, userId: Int, completion: @escaping (visitContactRelationship) -> Void) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        Chat.instance.rejectAddContactRequest(UInt(userId)) { (error) in
            if error != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                self.removeContactRequest(userID: UInt(userId), completion: {
                    completion(.unknown)
                })
            }
        }
    }
    
    func removeContactRequest(userID: UInt, completion: @escaping () -> Void) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: UserDefaults.standard.integer(forKey: "currentUserID")) {
                try realm.safeWrite ({
                    if let index = oldData.contactRequests.firstIndex(of: Int(userID)) {
                        oldData.contactRequests.remove(at: index)
                        realm.add(oldData, update: .all)
                    }
                })
                completion()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func acceptContactRequest(contactRelationship: visitContactRelationship, contactId: Int, completion: @escaping (visitContactRelationship) -> Void) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        Chat.instance.confirmAddContactRequest(UInt(contactId)) { (error) in
            self.removeContactRequest(userID: UInt(contactId), completion: {
                let event = Event()
                event.notificationType = .push
                event.usersIDs = [NSNumber(value: contactId)]
                event.type = .oneShot

                var pushParameters = [String : String]()
                pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") accepted your contact request."
                pushParameters["ios_sound"] = "app_sound.wav"

                if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
                    let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)
                    event.message = jsonString

                    Request.createEvent(event, successBlock: { _ in }, errorBlock: {(error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        completion(.pendingRequestForYou)
                        print("error in sending push noti: \(error.localizedDescription)")
                    })
                    completion(.contact)
                }
            })
        }
    }
    
    func actionSheetMoreBtn(contactRelationship: visitContactRelationship, contactId: Int, completion: @escaping (visitContactRelationship) -> Void) {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        if contactRelationship == .contact {
            Chat.instance.removeUser(fromContactList: UInt(contactId)) { (error) in
                changeContactsRealmData().deleteContact(contactID: contactId, isMyContact: false, completion: { _ in
                    completion(.notContact)
                })
            }
        } else if contactRelationship == .notContact {
            Chat.instance.addUser(toContactListRequest: UInt(contactId)) { (error) in
                if error != nil {
                    print("error adding user: \(String(describing: error?.localizedDescription))")
                } else {
                    let event = Event()
                    event.notificationType = .push
                    event.usersIDs = [NSNumber(value: contactId)]
                    event.type = .oneShot

                    var pushParameters = [String : String]()
                    pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") sent you a contact request."
                    pushParameters["ios_sound"] = "app_sound.wav"

                    if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
                        let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

                        event.message = jsonString

                        Request.createEvent(event, successBlock: {(events) in
                        print("sent push notification to user \(contactId)")
                        }, errorBlock: {(error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        print("error in sending push noti: \(error.localizedDescription)")
                        })
                        completion(.pendingRequest)
                    }
                }
            }
        }
    }
    
    func drawMiniHeader(text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.horizontal)
                .offset(y: 2)
            Spacer()
        }
    }

    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center, spacing: 0) {
            content()
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
}
