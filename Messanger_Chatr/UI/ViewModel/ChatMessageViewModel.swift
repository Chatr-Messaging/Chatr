//
//  ChatMessageViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/6/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI
import RealmSwift
import ConnectyCube
import Firebase
import SDWebImageSwiftUI

class ChatMessageViewModel: ObservableObject {
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    @ObservedObject var audio = VoiceViewModel()
    @Published var isDetailOpen: Bool = false
    @Published var message: MessageStruct = MessageStruct()
    @Published var contact: ContactStruct = ContactStruct()
    @Published var contactRelationship: visitContactRelationship = .unknown
    @Published var dismissView: Bool = true
    @Published var showPinDetails: String = ""
    @Published var player: AVPlayer = AVPlayer()
    @Published var totalDuration: Float = 0.0
    @Published var videoTimeText: String = "0:00"
    @Published var videoSize: CGSize = CGSize.zero
    @Published var playVideoo: Bool = true
    @Published var totalMessageCount: Int = -1
    @Published var unreadMessageCount: Int = 0
    @Published var preferenceVideoMute: Bool = false

    func loadDialog(auth: AuthModel, dialogId: String, completion: @escaping () -> Void) {
        let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]

        Request.updateDialog(withID: dialogId, update: UpdateChatDialogParameters(), successBlock: { dialog in
            self.syncLoadFoundDialog(dialog: dialog, auth: auth, dialogId: dialogId, completion: {
                completion()
            })
        }) { (error) in
            print("error fetching the dialog: \(error.localizedDescription)")
            Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
                for dialog in dialogs {
                    if dialog.id == dialogId {
                        self.syncLoadFoundDialog(dialog: dialog, auth: auth, dialogId: dialogId, completion: {
                            completion()
                        })
                        
                        break
                    }
                }
            }) { (error) in
                print("error fetching the dialog againnn: \(error.localizedDescription)")
                completion()
            }
        }
    }
    
    func syncLoadFoundDialog(dialog: ChatDialog, auth: AuthModel, dialogId: String, completion: @escaping () -> Void) {
        auth.selectedConnectyDialog = dialog
        dialog.sendUserStoppedTyping()
        self.updateDialogMessageCount(dialogId: dialogId, completion: {
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

            guard dialog.type == .group || dialog.type == .public else {
                completion()

                return
            }
            
            dialog.requestOnlineUsers(completionBlock: { (online, error) in
                print("The online count is!!: \(String(describing: online?.count))")
                //self.onlineCount = online?.count ?? 0
                self.setOnlineCount(dialog: dialog)
            })

            dialog.onUpdateOccupant = { (userID: UInt) in
                print("update occupant: \(userID)")
                self.setOnlineCount(dialog: dialog)
            }

            dialog.onJoinOccupant = { (userID: UInt) in
                print("on join occupant: \(userID)")
                self.setOnlineCount(dialog: dialog)
            }

            dialog.onLeaveOccupant = { (userID: UInt) in
                print("on leave occupant: \(userID)")
                self.setOnlineCount(dialog: dialog)
            }

            guard !dialog.isJoined(), Chat.instance.isConnected else {
                completion()
                return
            }

            dialog.join(completionBlock: { _ in
                self.setOnlineCount(dialog: dialog)
                completion()
            })
        })
    }
    
    func updateDialogMessageCount(dialogId: String, completion: @escaping () -> Void) {
        Request.countOfMessages(forDialogID: dialogId, extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
            self.totalMessageCount = Int(count)
            print("the total message count is: \(Int(count))")
            Request.totalUnreadMessageCountForDialogs(withIDs: Set([dialogId]), successBlock: { (unread, directory) in
                print("the unread count for this dialog: \(unread) && \(directory)")
                self.unreadMessageCount = Int(unread)
                
                if self.unreadMessageCount == 0 {
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                            self.unreadMessageCount = foundDialog.notificationCount
                            completion()
                        }
                    } catch { completion() }
                } else {
                    completion()
                }
            })
        })
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
                                compleation(firstUser.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: firstUser) ?? "", firstUser.fullName ?? "No Name", firstUser.lastRequestAt ?? Date())
                            }
                        }
                    })
                }
            } catch { }
        }
    }

    func likeMessage(from userId: Int, name: String, message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        DispatchQueue.main.async {
            let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("likes")

            msg.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                    msg.child("\(userId)").removeValue()

                    completion(false)
                } else {
                    msg.updateChildValues(["\(userId)" : "\(Date())"])
                    self.sendPushNoti(userIDs: [NSNumber(value: message.senderID)], title: "Liked Message", message: "👍 \(name) liked your message \"\(message.text)\"")

                    completion(true)
                }
            })
        }
    }
    
    func dislikeMessage(from userId: Int, name: String, message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        DispatchQueue.main.async {
            let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("dislikes")

            msg.observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.childSnapshot(forPath: "\(userId)").exists() {
                    msg.child("\(userId)").removeValue()

                    completion(false)
                } else {
                    msg.updateChildValues(["\(userId)" : "\(Date())"])
                    self.sendPushNoti(userIDs: [NSNumber(value: message.senderID)], title: "Disliked Message", message: "👎 \(name) disliked your message \"\(message.text)\"")
                    
                    completion(true)
                }
            })
        }
    }
    
    func sendReply(text: String, name: String, messagez: MessageStruct, completion: @escaping () -> Void) {
        guard messagez.senderID != 0, messagez.dialogID != "" else {
            print("the sender id or dialog is is not there...")
            return
        }

        let msg = Database.database().reference().child("Dialogs").child(messagez.dialogID).child(messagez.id).child("replies")
        let newPostId = msg.childByAutoId().key
        let newPostReference = msg.child(newPostId ?? "no post id")
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcTimeZoneStr = formatter.string(from: date)
        
        newPostReference.updateChildValues(["fromId" : "\(UserDefaults.standard.integer(forKey: "currentUserID"))", "text" : text, "timestamp" : utcTimeZoneStr])
        self.sendPushNoti(userIDs: [NSNumber(value: messagez.senderID)], title: "\(name) Replied", message: text)

        DispatchQueue.main.async {
            completion()
        }
    }
    
    func deleteReply(messageId: String, completion: @escaping () -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies")

        msg.child("\(messageId)").removeValue()

        DispatchQueue.main.async {
            completion()
        }
    }
    
    func fetchTotalReplyCount(completion: @escaping (Int) -> Void) {
        guard self.message.id.description != "" else {
            DispatchQueue.main.async {
                completion(0)
            }
            return
        }
        Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies").observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            DispatchQueue.main.async {
                completion(count)
            }
        })
    }
    
    func pinMessage(message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child("pinned")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(message.id)").exists() {
                msg.child("\(message.id)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues(["\(message.id)" : "\(Date())"])

                completion(true)
            }
        })
    }

    func playVideo() {
        let currentItem = player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }

        player.play()
        playVideoo = true
    }

    func pause() {
        player.pause()
        playVideoo = false
    }
    
//    func loadVideo(fileId: String, completion: @escaping () -> Void) {
//        DispatchQueue.main.async {
//            do {
//                let result = try self.storage?.entry(forKey: fileId)
//                let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mp4", fileExtension: "mp4")
//
//                self.player = AVPlayer(playerItem: playerItem)
//
//                completion()
//            } catch {
//                Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
//                    print("the progress of the download is: \(progress)")
//                }, successBlock: { data in
//                    let playerItem = CachingPlayerItem(data: data as Data, mimeType: "video/mp4", fileExtension: "mp4")
//                    self.player = AVPlayer(playerItem: playerItem)
//
//                    self.storage?.async.setObject(data, forKey: fileId, completion: { _ in })
//
//                    completion()
//                }, errorBlock: { error in
//                    print("the error videoo is: \(String(describing: error.localizedDescription))")
//                    completion()
//                })
//            }
//        }
//    }
    
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

                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    func sendReplyReport(replyStruct: messageReplyStruct, name: String, completion: @escaping () -> Void) {
        guard message.senderID != 0, message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child(message.id).child("replies").child(replyStruct.id).child("reported")
        
        msg.observe(.value, with: { snapshot in
            //let count = Int(snapshot.childrenCount)

            let date = Date()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            let utcTimeZoneStr = formatter.string(from: date)

            msg.updateChildValues(["\(UserDefaults.standard.integer(forKey: "currentUserID"))" : utcTimeZoneStr])
            
            self.sendPushNoti(userIDs: [NSNumber(value: Int(replyStruct.fromId) ?? 0)], title: "Reply Reported", message: "\(name) reported your reply: \"\(self.message.text)\"")
        })

        DispatchQueue.main.async {
            completion()
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
    
    func fetchUser() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                self.contact = foundContact
                self.contactRelationship = .contact
            } else {
                Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                    changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: Int(users.first?.id ?? 0), completion: { contact in
                        if let firstUser = users.first {
                            let newContact = ContactStruct()
                            newContact.id = Int(firstUser.id)
                            newContact.fullName = firstUser.fullName ?? ""
                            newContact.phoneNumber = firstUser.phone ?? "empty phone number"
                            newContact.lastOnline = firstUser.lastRequestAt ?? Date()
                            newContact.createdAccount = firstUser.createdAt ?? Date()
                            newContact.avatar = firstUser.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: firstUser) ?? ""
                            newContact.bio = contact.bio
                            newContact.facebook = contact.facebook
                            newContact.twitter = contact.twitter
                            newContact.instagramAccessToken = contact.instagramAccessToken
                            newContact.instagramId = contact.instagramId
                            newContact.isPremium = contact.isPremium
                            newContact.emailAddress = firstUser.email ?? "empty email address"
                            newContact.website = firstUser.website ?? "empty website"

                            self.contact = newContact
                            self.contactRelationship = .notContact

                            if ((self.profile.results.first?.contactRequests.contains(self.contact.id)) != nil) {
                                self.contactRelationship = .pendingRequest
                            } else if Chat.instance.contactList?.pendingApproval.count ?? 0 > 0 {
                                for con in Chat.instance.contactList?.pendingApproval ?? [] {
                                    if con.userID == UInt(self.contact.id) {
                                        self.contactRelationship = .pendingRequest
                                        break
                                    }
                                }
                            }
                        }
                    })
                }) { (error) in

                }
            }
        } catch {
            
        }
    }
    
    func setOnlineCount(dialog: ChatDialog?) {
        guard let dialog = dialog, dialog.type == .group || dialog.type == .public else {
            return
        }

        dialog.requestOnlineUsers(completionBlock: { (online, error) in
            print("the online count is: \(online?.count ?? 0)")
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let foundContact = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialog.id) {
                    try realm.safeWrite ({
                        foundContact.onlineUserCount = online?.count ?? 0
                        realm.add(foundContact, update: .all)
                    })
                }
            } catch {
                print(error.localizedDescription)
            }
        })
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
