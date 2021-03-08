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
import SDWebImageSwiftUI

class ChatMessageViewModel: ObservableObject {
    @Published var isDetailOpen: Bool = false
    @Published var message: MessageStruct = MessageStruct()

    func loadDialog(auth: AuthModel, dialogId: String) {
        //DispatchQueue.global(qos: .utility).async {
            Request.updateDialog(withID: dialogId, update: UpdateChatDialogParameters(), successBlock: { dialog in
                auth.selectedConnectyDialog = dialog
                dialog.sendUserStoppedTyping()

                dialog.onUserIsTyping = { (userID: UInt) in
                    if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                        changeMessageRealmData.shared.addTypingMessage(userID: String(userID), dialogID: dialogId)
                    }
                }

                dialog.onUserStoppedTyping = { (userID: UInt) in
                    if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                        changeMessageRealmData.shared.removeTypingMessage(userID: String(userID), dialogID: dialogId)
                    }
                }

                if dialog.type == .group || dialog.type == .public {
                    dialog.requestOnlineUsers(completionBlock: { (online, error) in
                        print("The online count is!!: \(String(describing: online?.count))")
                        auth.onlineCount = online?.count ?? 0
                    })

                    dialog.onUpdateOccupant = { (userID: UInt) in
                        print("update occupant: \(userID)")
                        auth.setOnlineCount()
                    }

                    dialog.onJoinOccupant = { (userID: UInt) in
                        print("on join occupant: \(userID)")
                        auth.setOnlineCount()
                    }

                    dialog.onLeaveOccupant = { (userID: UInt) in
                        print("on leave occupant: \(userID)")
                        auth.setOnlineCount()
                    }

//                    if Chat.instance.isConnected || !Chat.instance.isConnecting {
//                        if !dialog.isJoined() {
//                            dialog.join(completionBlock: { error in
//                                print("we have joined the dialog!! \(String(describing: error))")
//                            })
//                        }
//                    } else {
//                        DispatchQueue.main.async {
//                            ChatrApp.connect()
//                            if !dialog.isJoined() {
//                                dialog.join(completionBlock: { error in
//                                    print("we have joined the dialog after atempt 2!! \(String(describing: error))")
//                                })
//                            }
//                        }
//                    }
                }
            })
        //}
    }

    func getUserAvatar(senderId: Int, compleation: @escaping (String, String, Date) -> Void) {
        if senderId == UserDefaults.standard.integer(forKey: "currentUserID") {
            compleation("self", "self", Date())
        } else {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: senderId) {
                    compleation(foundContact.avatar, foundContact.fullName, foundContact.lastOnline)
                } else {
                    Request.users(withIDs: [NSNumber(value: senderId)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                        DispatchQueue.main.async {
                            if let firstUser = users.first {
                                compleation(PersistenceManager.shared.getCubeProfileImage(usersID: firstUser) ?? "", firstUser.fullName ?? "Chatr User", firstUser.lastRequestAt ?? Date())
                            }
                        }
                    })
                }
            } catch { }
        }
    }

    func likeMessage(from userId: Int, name: String, message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("likes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                msg.child("\(userId)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues(["\(userId)" : "\(Date())"])
                self.sendPushNoti(userIDs: [NSNumber(value: message.senderID)], title: "Liked Message", message: "\(name) liked your message \"\(message.text)\"")

                completion(true)
            }
        })
    }
    
    func dislikeMessage(from userId: Int, name: String, message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("dislikes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                msg.child("\(userId)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues(["\(userId)" : "\(Date())"])
                self.sendPushNoti(userIDs: [NSNumber(value: message.senderID)], title: "Disliked Message", message: "\(name) disliked your message \"\(message.text)\"")
                
                completion(true)
            }
        })
    }
    
    func sendReply(text: String, name: String, completion: @escaping () -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies")
        let newPostId = msg.childByAutoId().key
        let newPostReference = msg.child(newPostId ?? "no post id")
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcTimeZoneStr = formatter.string(from: date)
        
        newPostReference.updateChildValues(["fromId" : "\(UserDefaults.standard.integer(forKey: "currentUserID"))", "text" : text, "timestamp" : utcTimeZoneStr])
        self.sendPushNoti(userIDs: [NSNumber(value: self.message.senderID)], title: "Reply", message: "\(name) replied to your message \"\(self.message.text)\"")

        completion()
    }
    
    func deleteReply(messageId: String, completion: @escaping () -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies")

        msg.child("\(messageId)").removeValue()

        completion()
    }
    
    func fetchTotalReplyCount(completion: @escaping (Int) -> Void) {
        guard self.message.id.description != "" else {
            completion(0)
            return
        }
        Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies").observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }
    
    func fetchReplyCount(message: MessageStruct, completion: @escaping (Int) -> Void) {
        Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies").observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }
    
    func editMessage() {
        print("edit message")
    }
    
    func trashMessage(connectyDialog: ChatDialog, messageId: String, completion: @escaping () -> Void) {
        connectyDialog.removeMessage(withID: messageId) { (error) in
            if error != nil {
                print("the error deleting: \(String(describing: error?.localizedDescription))")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                changeMessageRealmData.shared.updateMessageState(messageID: messageId, messageState: .deleted)

                completion()
            }
        }
    }

    func fetchMessage(messageId: String) -> MessageStruct {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                //Contact is in Realm...
                return realmContact
            } else {
                return MessageStruct()
            }
        } catch {
            print(error.localizedDescription)
            return MessageStruct()
        }
    }

    func sendPushNoti(userIDs: [NSNumber], title: String, message: String) {
        let event = Event()
        event.notificationType = .push
        event.usersIDs = userIDs
        event.type = .oneShot
        event.name = title

        var pushParameters = [String : String]()
        pushParameters["title"] = title
        pushParameters["message"] = message
        pushParameters["ios_sound"] = "app_sound.wav"

        if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
            let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

            event.message = jsonString

            Request.createEvent(event, successBlock: {(events) in
                print("sent push notification!! \(events)")
            }, errorBlock: {(error) in
                print("error sending noti: \(error.localizedDescription)")
            })
        }
    }

    func dateFormatTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
     
        return dateFormatter.string(from: date)
    }
    
    func dateFormatTimeExtended(date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
     
        return dateFormatter.string(from: date)
    }
}
