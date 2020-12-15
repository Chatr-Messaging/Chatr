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
    //main connection point for users, dialogs, & messages services
    
    ///Users Service
    static let users = Users()
    ///Dialogs Service
    static let dialogs = Dialogs()
    ///Message Service
    static let messages = MessagesObject()
    
    static let auth = AuthModel()
}

extension ChatrApp {
    //main connection function here

    /// Connect to chat / Login if needed / Dialogs updates
    static func connect() {
        do {
            if let user = ProfileRealmModel(results: try Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first {
                
                print("logged in with: \(user.fullName)")
                Chat.instance.addDelegate(ChatrApp.auth)
                Purchases.shared.identify("\(user.id)") { (_, _) in }
                if Session.current.tokenHasExpired {
                    users.login(completion: {
                        print("done re-logging in.")
                        Chat.instance.connect(withUserID: UInt(user.id), password: Session.current.sessionDetails?.token ?? "") { (error) in
                            if error != nil {
                                print("Error joining session from expired token: \(String(describing: error?.localizedDescription))")
                            } else {
                                print("Success joining session from expired token!")
                            }
                            self.auth.initIAPurchase()
                            changeDialogRealmData().fetchDialogs(completion: { _ in })
                            changeContactsRealmData().observeQuickSnaps()
                        }
                    })
                } else {
                    Chat.instance.connect(withUserID: UInt(user.id), password: Session.current.sessionDetails?.token ?? "") { (error) in
                        if error != nil {
                            print("there is a error connecting to session! \(String(describing: error?.localizedDescription)) user id: \(user.id)")
                        } else {
                            print("Success joining session! the current user: \(String(describing: Session.current.currentUser)) && expirationSate: \(String(describing: Session.current.sessionDetails?.token))")
                        }
                        Chat.instance.addDelegate(ChatrApp.auth)
                        Purchases.shared.identify("\(user.id)") { (_, _) in }
                        self.auth.initIAPurchase()
                        changeDialogRealmData().fetchDialogs(completion: { _ in })
                        changeContactsRealmData().observeQuickSnaps()
                    }
                }

                
      

    //            Chat.instance.connect(withUserID: UInt(user.id), password: Session.current.sessionDetails?.token ?? "") { (error) in
    //                if error != nil {
    //                    print("there is a error connecting to session! \(String(describing: error))")
    //                } else {
    //                    print("Success joining session! \(Session.current.sessionDetails?.token ?? "session has no token") and the current user: \(String(describing: Session.current.currentUser))")
    //                }
    //                if error != nil {
    //                    print("there is a error connecting to session! \(String(describing: error)) \(Session.current.sessionDetails?.token ?? "session has no token")")
    //                    if let token = UserDefaults.standard.string(forKey: "tokenID") {
    //                        Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: token, successBlock: { (user) in
    //                            print("had to relogin the connectycube user & here is the newly logged in user: \(user)")
    //                        })
    //                    } else {
    //                        print("error getting the tokenID")
    //                    }
    //                } else {
    //                    print("Success joining session! \(Session.current.sessionDetails?.token ?? "session has no token") and the current user: \(String(describing: Session.current.currentUser))")
    //                    if let currentUser = Session.current.currentUser {
    //                        PersistenceManager.shared.setCubeProfile(currentUser)
    //                    }
    //                }
                //}
            } else {
                print("user current profile is not there...")
            }
        } catch {
            
        }
    }
}
