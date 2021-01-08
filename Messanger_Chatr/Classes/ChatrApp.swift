//
//  ChatrApp.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/3/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Combine
import ConnectyCube
import UserNotifications
import RealmSwift
import Purchases
import Contacts

struct ChatrApp {
    ///Users Service
    static let users = Users()
    ///Dialogs Service
    static let dialogs = Dialogs()
    ///Message Service
    static let messages = MessagesObject()
    ///Auth & other Service
    static let auth = AuthModel()
}

extension ChatrApp {
    /// Connect to chat / Login if needed / Dialogs updates & more...
    static func connect() {
        if let user = self.auth.profile.results.first {
            print("logged in with: \(user.fullName)")
            Chat.instance.addDelegate(ChatrApp.auth)
            Purchases.shared.identify("\(user.id)") { (_, _) in }
            if Session.current.tokenHasExpired {
                users.login(completion: {
                    print("done re-logging in.")
                    self.chatInstanceConnect(id: UInt(user.id))
                })
            } else {
                self.chatInstanceConnect(id: UInt(user.id))
            }
        } else {
            print("user current profile is not there...")
        }
    }
    
    static func chatInstanceConnect(id: UInt) {
        Chat.instance.connect(withUserID: id, password: Session.current.sessionDetails?.token ?? "") { (error) in
            if error != nil {
                print("there is a error connecting to session! \(String(describing: error?.localizedDescription)) user id: \(id)")
                changeContactsRealmData().observeQuickSnaps()
            } else {
                print("Success joining session! the current user: \(String(describing: Session.current.currentUser)) && expirationSate: \(String(describing: Session.current.sessionDetails?.token))")

                changeDialogRealmData().fetchDialogs(completion: { _ in
                    changeContactsRealmData().observeQuickSnaps()
                    self.auth.initIAPurchase()
                })
            }
        }
    }
}

//Permissions
extension ChatrApp {
    static func checkContactsPermission(completion: @escaping (Bool) -> ()) {
       if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            print("Contacts are notDetermined")
            completion(false)
       } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            print("Contacts are authorized")
            completion(true)
       }
    }
    
    static func requestContacts(completion: @escaping (Bool) -> ()) {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts){succeeded, err in
                guard err == nil && succeeded else {
                    completion(false)
                    return
                }
                if succeeded {
                    completion(true)
                }
            }
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            print("Contacts are authorized")
            completion(true)

        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            completion(false)
        }
    }
}
