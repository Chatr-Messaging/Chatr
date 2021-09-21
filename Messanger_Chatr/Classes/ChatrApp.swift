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
import CryptoKit

struct ChatrApp {
    ///Users Service
    static let users = Users()

    ///Auth & other Service
    static let auth = AuthModel()
}

extension ChatrApp {
    /// Connect to chat / Login if needed / Dialogs updates & more...
    static func connect() {
        DispatchQueue.main.async {
            guard let user = auth.profile.results.first, !Chat.instance.isConnected && !Chat.instance.isConnecting else { return }

            print("\(Thread.current.isMainThread) logged in with: \(user.fullName) && \(user.id)")
            Chat.instance.addDelegate(ChatrApp.auth)
            Purchases.shared.identify("\(user.id)") { (_, _) in }
            if Session.current.tokenHasExpired {
                users.login(completion: {
                    print("done re-logging in.")
                    if auth.visitContactProfile == false {
                        chatInstanceConnect(id: UInt(user.id))
                    }
                })
            } else if auth.visitContactProfile == false {
                chatInstanceConnect(id: UInt(user.id))
            }
        }
    }
    
    static func chatInstanceConnect(id: UInt) {
        DispatchQueue.main.async {
            guard !Chat.instance.isConnected && !Chat.instance.isConnecting else { return }
            
            print("the session token is: \(Session.current.tokenHasExpired) &&&& \(Session.current.sessionDetails?.token ?? "")")
            Chat.instance.connect(withUserID: id, password: Session.current.sessionDetails?.token ?? "") { (error) in
                if error != nil {
                    print("there is an error connecting to session! \(String(describing: error?.localizedDescription)) user id: \(id)")
                    users.login(completion: {
                        changeContactsRealmData.shared.observeQuickSnaps()
                        changeProfileRealmDate.shared.observeFirebaseUser(with: Int(id))
                    })
                } else {
                    //print("\(Thread.current.isMainThread) Success joining session! the current user: \(String(describing: Session.current.currentUser?.fullName)) && expirationSate: \(String(describing: Session.current.sessionDetails?.createdAt))")
                    print("Success joining session! the created at: \(String(describing: Session.current.sessionDetails))")
                    
                    changeDialogRealmData.shared.fetchDialogs(completion: { _ in })
                    changeContactsRealmData.shared.observeQuickSnaps()
                    changeProfileRealmDate.shared.observeFirebaseUser(with: Int(id))
                    joinInitOpenDialog()
                    //auth.initIAPurchase()
                }
            }
        }
    }

    static func joinInitOpenDialog() {
        DispatchQueue.main.async {
            guard let openDialog = auth.dialogs.results.filter({ $0.isOpen == true }).first, openDialog.dialogType == "group" || openDialog.dialogType == "public", UserDefaults.standard.bool(forKey: "localOpen") else {
                return
            }

            Request.updateDialog(withID: openDialog.id, update: UpdateChatDialogParameters(), successBlock: { dialog in
                auth.selectedConnectyDialog = dialog
                dialog.join(completionBlock: { _ in })
            })
        }
    }
    
    static func getCryptoKey() -> String {
        guard let user = auth.profile.results.first else { return "" }

        return user.id.description.sha256()
    }
}

extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        let hash = Insecure.SHA1.hash(data: data)

        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)

        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
