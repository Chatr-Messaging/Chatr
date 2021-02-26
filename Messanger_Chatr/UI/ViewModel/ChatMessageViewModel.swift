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
    @Published var selectedMessageId: String = ""

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

    func getUserAvatar(senderId: Int, compleation: @escaping (String, String) -> Void) {
        if senderId == UserDefaults.standard.integer(forKey: "currentUserID") {
            compleation("self", "self")
        } else {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: senderId) {
                    compleation(foundContact.avatar, foundContact.fullName)
                } else {
                    Request.users(withIDs: [NSNumber(value: senderId)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                        DispatchQueue.main.async {
                            if let firstUser = users.first {
                                compleation(PersistenceManager.shared.getCubeProfileImage(usersID: firstUser) ?? "", firstUser.fullName ?? "Chatr User")
                            }
                        }
                    })
                }
            } catch { }
        }
    }

    func likeMessage(from userId: Int, name: String, message: MessageStruct, completion: @escaping (Bool) -> Void) {
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
        
    func replyMessage() {
        print("reply message")
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
        dateFormatter.timeStyle = .medium
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
     
        return dateFormatter.string(from: date)
    }
}
