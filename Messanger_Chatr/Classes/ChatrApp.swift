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

struct ChatrApp {
    ///Users Service
    static let users = Users()

    ///Auth & other Service
    static let auth = AuthModel()
}

extension ChatrApp {
    /// Connect to chat / Login if needed / Dialogs updates & more...
    static func connect() {
        if let user = self.auth.profile.results.first {
            print("\(Thread.current.isMainThread) logged in with: \(user.fullName)")
            Chat.instance.addDelegate(ChatrApp.auth)
            Purchases.shared.identify("\(user.id)") { (_, _) in }
            if Session.current.tokenHasExpired {
                users.login(completion: {
                    print("done re-logging in.")
                    if self.auth.visitContactProfile == false {
                        self.chatInstanceConnect(id: UInt(user.id))
                    }
                })
            } else {
                if self.auth.visitContactProfile == false {
                    self.chatInstanceConnect(id: UInt(user.id))
                }
            }
        }
    }
    
    static func chatInstanceConnect(id: UInt) {
        guard !Chat.instance.isConnected && !Chat.instance.isConnecting else { return }
        
        print("the session token is: \(Session.current.tokenHasExpired) &&&& \(Session.current.sessionDetails?.token ?? "")")
        Chat.instance.connect(withUserID: id, password: Session.current.sessionDetails?.token ?? "") { (error) in
            if error != nil {
                print("there is a error connecting to session! \(String(describing: error?.localizedDescription)) user id: \(id)")
                users.login(completion: {
                    changeContactsRealmData.shared.observeQuickSnaps()
                    changeProfileRealmDate.shared.observeFirebaseUser(with: Int(id))
                })
            } else {
                print("\(Thread.current.isMainThread) Success joining session! the current user: \(String(describing: Session.current.currentUser?.fullName)) && expirationSate: \(String(describing: Session.current.sessionDetails?.token))")

                changeDialogRealmData.shared.fetchDialogs(completion: { worked in
                    if worked {
                        changeContactsRealmData.shared.observeQuickSnaps()
                        changeProfileRealmDate.shared.observeFirebaseUser(with: Int(id))
                        self.auth.initIAPurchase()
                    }
                })
            }
        }
    }
}
