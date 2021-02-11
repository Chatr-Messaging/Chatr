//
//  MessagesViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/17/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import ConnectyCube
import RealmSwift
import Firebase
import MobileCoreServices

class MessagesViewModel: ObservableObject {
    
    func likeMessage(message: MessageStruct, userIdToLike: Int, completion: @escaping (Bool) -> Void) {
        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("likes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(userIdToLike)").exists() {
                msg.child("\(userIdToLike)").removeValue()
                
                completion(false)
            } else {
                msg.updateChildValues(["\(userIdToLike)" : "\(Date())"])

                completion(true)
            }
        })
    }
    
//    func dislikeMessage(dialogId: String, messageId: String, userIdToDisike: Int) {
//        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id).child("dislikes")
//
//        msg.observeSingleEvent(of: .value, with: { snapshot in
//            if snapshot.childSnapshot(forPath: "\(self.auth.profile.results.first?.id ?? 0)").exists() {
//                self.hasUserDisliked = false
//                msg.child("\(self.auth.profile.results.first?.id ?? 0)").removeValue()
//            } else {
//                self.hasUserDisliked = false
//                msg.updateChildValues(["\(self.auth.profile.results.first?.id ?? 0)" : "\(Date())"])
//            }
//        })
//    }
//
//    func copyMessage() {
//        UINotificationFeedbackGenerator().notificationOccurred(.success)
//        UIPasteboard.general.setValue(self.message.text,
//                    forPasteboardType: kUTTypePlainText as String)
//        auth.notificationtext = "Successfully copied message"
//        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
//    }
//
//    func replyMessage() {
//        print("reply message")
//    }
//
//    func editMessage() {
//        print("edit message")
//    }
//
//    func trashMessage() {
//        self.auth.selectedConnectyDialog?.removeMessage(withID: self.message.id) { (error) in
//            if error != nil {
//                UINotificationFeedbackGenerator().notificationOccurred(.error)
//            } else {
//                changeMessageRealmData.updateMessageState(messageID: self.message.id, messageState: .deleted)
//                auth.notificationtext = "Deleted Message"
//                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
//            }
//        }
//    }
}
