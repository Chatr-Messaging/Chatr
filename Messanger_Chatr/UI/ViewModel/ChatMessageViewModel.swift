//
//  ChatMessageViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/6/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import Firebase

class ChatMessageViewModel: ObservableObject {

    func getUserAvatar(senderId: Int, compleation: @escaping (String) -> Void) {
        if senderId == UserDefaults.standard.integer(forKey: "currentUserID") {
            compleation("self")
        } else {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: senderId) {
                    compleation(foundContact.avatar)
                } else {
                    Request.users(withIDs: [NSNumber(value: senderId)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                        if let firstUser = users.first {
                            compleation(PersistenceManager().getCubeProfileImage(usersID: firstUser) ?? "")
                        }
                    })
                }
            } catch { }
        }
    }

    func likeMessage(from userId: Int, messageId: String, dialogId: String, completion: @escaping (Bool) -> Void) {
        let msg = Database.database().reference().child("Dialogs").child(dialogId).child(messageId).child("likes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                msg.child("\(userId)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues(["\(userId)" : "\(Date())"])
                
                completion(true)
            }
        })
    }
    
    func dislikeMessage(from userId: Int, messageId: String, dialogId: String, completion: @escaping (Bool) -> Void) {
        let msg = Database.database().reference().child("Dialogs").child(dialogId).child(messageId).child("dislikes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                msg.child("\(userId)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues([userId : "\(Date())"])
                
                completion(true)
            }
        })
    }
        
    func replyMessage() {
        print("reply message")
    }
    
    func editMessage() {
        print("edit message")
    }
    
    func trashMessage(connectyDialog: ChatDialog, messageId: String, completion: @escaping () -> Void) {
        connectyDialog.removeMessage(withID: messageId) { (error) in
            if error != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                changeMessageRealmData.updateMessageState(messageID: messageId, messageState: .deleted)

                completion()
            }
        }
    }
}
