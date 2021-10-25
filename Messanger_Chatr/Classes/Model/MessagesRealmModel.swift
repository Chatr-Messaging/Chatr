//
//  MessagesRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/4/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import Combine
import UIKit
import Photos
import AVKit
import ConnectyCube
import Firebase
import RealmSwift

class MessageStruct : Object, Identifiable {
    @objc dynamic var id: String = ""
    @objc dynamic var text: String = ""
    @objc dynamic var dialogID: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var destroyDate: Int = 0
    @objc dynamic var senderID: Int = 0
    @objc dynamic var bubbleWidth: Int = 0
    @objc dynamic var longitude: Double = 0.0
    @objc dynamic var latitude: Double = 0.0
    @objc dynamic var contactID: Int = 0
    @objc dynamic var channelID: String = ""
    @objc dynamic var image: String = ""
    @objc dynamic var localAttachmentPath: String = ""
    @objc dynamic var imageType: String = ""
    @objc dynamic var hadDelay: Bool = false
    @objc dynamic var isPinned: Bool = false
    @objc dynamic var uploadMediaId: String = ""
    @objc dynamic var uploadProgress: Double = 0.0
    @objc dynamic var placeholderVideoImg: String = ""
    @objc dynamic var mediaRatio: Double = 0.0
    @objc dynamic var positionRight: Bool = true
    @objc dynamic var hasPrevious: Bool = false
    @objc dynamic var needsTimestamp: Bool = false
    @objc dynamic var isPriorWider: Bool = false
    @objc dynamic var isHeader: Bool = false
    @objc dynamic var status = messageStatus.sending.rawValue
    var messageState: messageStatus {
        get { return messageStatus(rawValue: status) ?? .delivered }
        set { status = newValue.rawValue }
    }
    let readIDs = List<Int>()
    let deliveredIDs = List<Int>()
    let likedId = List<Int>()
    let dislikedId = List<Int>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

class MessagesRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
    @Published var results: Results<Element>
    private var token: NotificationToken!
    
    private var itemsPerPage = 15
    private var start = -15
    private var stop = -1

    init(results: Results<Element>) {
        self.results = results
        lateInit()
    }

    func lateInit() {
        token = results.observe { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        token.invalidate()
    }
    
    private func incrementPaginationIndices() {
        start += self.itemsPerPage
        stop += self.itemsPerPage
      
        stop = min(self.results.count, stop)
    }
    
    func selectedDialog(dialogID: String) -> Results<Element> {
        if dialogID == "" {
            return results.filter("status != %@", messageStatus.deleted.rawValue).sorted(byKeyPath: "date", ascending: true)
        } else {
            return results.filter("dialogID == %@", dialogID).filter("status != %@", messageStatus.removedTyping.rawValue).filter("status != %@", messageStatus.deleted.rawValue).sorted(byKeyPath: "date", ascending: true)
        }
    }
}

extension MessagesRealmModel {

    func getMessageUpdates(dialogID: String, limit: Int, skip: Int, completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "date_sent", "mark_as_read" : "0"]
        Request.messages(withDialogID: dialogID, extendedRequest: extRequest, paginator: Paginator.limit(UInt(limit), skip: UInt(skip)), successBlock: { (messages, _) in
            self.insertMessages(messages, completion: {
                self.checkSurroundingValues(dialogId: dialogID, completion: {
                    completion(true)
                })
            })
        }) { _ in
            completion(false)
        }
    }
    
    func loadMoreMessages(dialogID: String, currentCount: Int, completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "date_sent", "mark_as_read" : "0"]
        
        //For the 'skip' paginator... you need to get to total unread count & if greater than ~10 apply unread count
        //No need to scroll to bottom. When you hit the bottom, load ~10 more or so.
        Request.messages(withDialogID: dialogID, extendedRequest: extRequest, paginator: Paginator.limit(UInt(currentCount + 20), skip: 0), successBlock: { (messages, _) in
            self.insertMessages(messages, completion: {
                completion(true)
            })
        }){ (error) in
            completion(false)
        }
    }
    
    func insertMessages<T>(_ objects: [T], completion: @escaping () -> Void) where T: ChatMessage {
        objects.forEach({ (object) in
            let config = Realm.Configuration(schemaVersion: 1)

            do {
                let realm = try Realm(configuration: config)
                if let foundMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: object.id ?? "") {
                    try realm.write({
                        
                        if let text = object.text, foundMessage.text != text {
                            foundMessage.text = text
                        }
                        
                        if let dialogID = object.dialogID, foundMessage.dialogID != dialogID {
                            foundMessage.dialogID = dialogID
                        }
                        
                        if let date = object.dateSent, foundMessage.date != date {
                            foundMessage.date = date
                        }
                        
                        if foundMessage.senderID != Int(object.senderID) {
                            foundMessage.senderID = Int(object.senderID)
                        }
                        
                        let positionz = Int(object.senderID) == UserDefaults.standard.integer(forKey: "currentUserID")
                        if foundMessage.positionRight != positionz {
                            foundMessage.positionRight = positionz
                        }
                        
                        if let readz = object.readIDs {
                            for read in readz {
                                if !foundMessage.readIDs.contains(Int(truncating: read)) {
                                    foundMessage.readIDs.append(Int(truncating: read))
                                }
                            }
                        }
                        
                        if !foundMessage.readIDs.contains(Int(Session.current.currentUserID)) {
                            Chat.instance.read(object) { (error) in }
                        }
                        
                        if let delivered = object.deliveredIDs {
                            for deliv in delivered {
                                if !foundMessage.deliveredIDs.contains(Int(truncating: deliv)) {
                                    foundMessage.deliveredIDs.append(Int(truncating: deliv))
                                }
                            }
                        }
                        
                        //case delivered, sending, read, isTyping, editied, deleted, error
                        if let deliverCount = object.deliveredIDs?.count, deliverCount > 1 {
                            foundMessage.messageState = .delivered
                        } else {
                            foundMessage.messageState = .sending
                        }
                        if object.readIDs?.count ?? 0 > 0 {
                            foundMessage.messageState = .read
                        }
                        if object.edited {
                            foundMessage.messageState = .editied
                        }
                        if object.removed {
                            foundMessage.messageState = .deleted
                        }
                        if object.delayed, !foundMessage.hadDelay {
                            foundMessage.hadDelay = true
                        }

                        if (object.destroyAfterInterval > 0), foundMessage.destroyDate != Int(object.destroyAfterInterval) {
                            foundMessage.destroyDate = Int(object.destroyAfterInterval)
                        }
                        
                        if let attachments = object.attachments {
                            for attach in attachments {
                                //image/video attachment
                                if let type = attach.type, foundMessage.imageType != type {
                                    foundMessage.imageType = type
                                }
                                
                                if let imagePram = attach.customParameters as? [String: String] {
                                    if let img = imagePram["imageURL"], foundMessage.image != img {
                                        foundMessage.image = img
                                    }
                                    
                                    if let imageUploadId = imagePram["uploadId"], foundMessage.image != imageUploadId {
                                        foundMessage.uploadMediaId = imageUploadId
                                    }
                                    
                                    if let contactId = Int(imagePram["contactID"] ?? ""), foundMessage.contactID != contactId {
                                        foundMessage.contactID = contactId
                                    }
                                    
                                    if let channelId = imagePram["channelID"], foundMessage.channelID != channelId {
                                        foundMessage.channelID = channelId
                                    }
                                    
                                    if let longitude = imagePram["longitude"], foundMessage.longitude != Double("\(longitude)") ?? 0 {
                                        foundMessage.longitude = Double("\(longitude)") ?? 0
                                    }
                                    
                                    if let latitude = imagePram["latitude"], foundMessage.latitude != Double("\(latitude)") ?? 0 {
                                        foundMessage.latitude = Double("\(latitude)") ?? 0
                                    }
                                    
                                    if let videoUrl = imagePram["videoURL"], foundMessage.image != "\(videoUrl)" {
                                        foundMessage.image = "\(videoUrl)"
                                    }
                                    
                                    if let placeholderId = imagePram["placeholderURL"], foundMessage.placeholderVideoImg != "\(placeholderId)" {
                                        foundMessage.placeholderVideoImg = "\(placeholderId)"
                                    }

                                    if let ratio = imagePram["mediaRatio"], foundMessage.mediaRatio != Double("\(ratio)") {
                                        foundMessage.mediaRatio = Double("\(ratio)") ?? 0.0
                                    }
                                }
                            }
                        }
                        
                        realm.add(foundMessage, update: .all)
                    })
                } else {
                    let newData = MessageStruct()

                    newData.id = object.id ?? ""
                    newData.text = object.text ?? ""
                    newData.dialogID = object.dialogID ?? ""
                    newData.date = object.dateSent ?? Date()
                    newData.senderID = Int(object.senderID)
                    newData.positionRight = Int(object.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false

                    for read in object.readIDs ?? [] {
                        if !newData.readIDs.contains(Int(truncating: read)) {
                            newData.readIDs.append(Int(truncating: read))
                        }
                    }

                    if !newData.readIDs.contains(Int(Session.current.currentUserID)) {
                        Chat.instance.read(object) { (error) in }
                    }
                    
                    for deliv in object.deliveredIDs ?? [] {
                        if !newData.deliveredIDs.contains(Int(truncating: deliv)) {
                            newData.deliveredIDs.append(Int(truncating: deliv))
                        }
                    }
                    
                    //case delivered, sending, read, isTyping, editied, deleted, error
                    if object.deliveredIDs?.count ?? 0 > 1 {
                        newData.messageState = .delivered
                    } else {
                        newData.messageState = .sending
                    }
                    if object.readIDs?.count ?? 0 > 0 {
                        newData.messageState = .read
                    }
                    if object.edited {
                        newData.messageState = .editied
                    }
                    if object.removed {
                        newData.messageState = .deleted
                    }
                    if object.delayed {
                        newData.hadDelay = true
                    }

                    if (object.destroyAfterInterval > 0) {
                        newData.destroyDate = Int(object.destroyAfterInterval)
                    }
                    
                    if let attachments = object.attachments {
                        for attach in attachments {
                            //image/video attachment
                            if let imagePram = attach.customParameters as? [String: String] {
                                if let typez = attach.type {
                                    newData.imageType = typez
                                }

                                if let imagez = imagePram["imageURL"] {
                                    newData.image = imagez
                                }

                                if let imageUploadPram = imagePram["uploadId"] {
                                    newData.uploadMediaId = imageUploadPram
                                }

                                if let contactID = imagePram["contactID"] {
                                    newData.contactID = Int(contactID) ?? 0
                                }

                                if let channelId = imagePram["channelID"] {
                                    newData.channelID = channelId
                                }

                                if let longitude = imagePram["longitude"] {
                                    newData.longitude = Double("\(longitude)") ?? 0
                                }

                                if let latitude = imagePram["latitude"] {
                                    newData.latitude = Double("\(latitude)") ?? 0
                                }
                                
                                if let videoUrl = imagePram["videoURL"] {
                                    newData.image = "\(videoUrl)"
                                }

                                if let placeholderId = imagePram["placeholderURL"] {
                                    newData.placeholderVideoImg = "\(placeholderId)"
                                }

                                if let ratio = imagePram["mediaRatio"] {
                                    newData.mediaRatio = Double("\(ratio)") ?? 0.0
                                }
                            }
                        }
                    }
                    
                    try realm.write({
                        realm.add(newData, update: .all)
                    })
                }
//                else {
//                    let msg = Database.database().reference().child("Dialogs").child(object.dialogID ?? "").child(object.id ?? "")
//                    msg.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
//                        updateMessageLike(messageID: object.id ?? "", messageLikeCount: Int(snapshot.childSnapshot(forPath: "likes").childrenCount))
//                        updateMessageDislike(messageID: object.id ?? "", messageDislikeCount: Int(snapshot.childSnapshot(forPath: "dislikes").childrenCount))
//                        completion()
//                    })
//                }
            } catch {  }
        })
        DispatchQueue.main.async {
            completion()
        }
    }
    
    func insertMessage<T>(_ object: T, completion: @escaping () -> Void) where T: ChatMessage {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let foundMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: object.id ?? "") {
                try realm.write({
                    if let text = object.text, foundMessage.text != text {
                        foundMessage.text = text
                    }
                    
                    if let dialogID = object.dialogID, foundMessage.dialogID != dialogID {
                        foundMessage.dialogID = dialogID
                    }
                    
                    if let date = object.dateSent, foundMessage.date != date {
                        foundMessage.date = date
                    }
                    
                    if foundMessage.senderID != Int(object.senderID) {
                        foundMessage.senderID = Int(object.senderID)
                    }
                    
                    let positionz = Int(object.senderID) == UserDefaults.standard.integer(forKey: "currentUserID")
                    if foundMessage.positionRight != positionz {
                        foundMessage.positionRight = positionz
                    }
                    
                    if let readz = object.readIDs {
                        for read in readz {
                            if !foundMessage.readIDs.contains(Int(truncating: read)) {
                                foundMessage.readIDs.append(Int(truncating: read))
                            }
                        }
                    }
                    
                    if !foundMessage.readIDs.contains(Int(Session.current.currentUserID)) {
                        Chat.instance.read(object) { (error) in }
                    }
                    
                    if let delivered = object.deliveredIDs {
                        for deliv in delivered {
                            if !foundMessage.deliveredIDs.contains(Int(truncating: deliv)) {
                                foundMessage.deliveredIDs.append(Int(truncating: deliv))
                            }
                        }
                    }
                    
                    //case delivered, sending, read, isTyping, editied, deleted, error
                    if let deliverCount = object.deliveredIDs?.count, deliverCount > 1 {
                        foundMessage.messageState = .delivered
                    } else {
                        foundMessage.messageState = .sending
                    }
                    if object.readIDs?.count ?? 0 > 0 {
                        foundMessage.messageState = .read
                    }
                    if object.edited {
                        foundMessage.messageState = .editied
                    }
                    if object.removed {
                        foundMessage.messageState = .deleted
                    }
                    if object.delayed, !foundMessage.hadDelay {
                        foundMessage.hadDelay = true
                    }

                    if (object.destroyAfterInterval > 0), foundMessage.destroyDate != Int(object.destroyAfterInterval) {
                        foundMessage.destroyDate = Int(object.destroyAfterInterval)
                    }
                    
                    if let attachments = object.attachments {
                        for attach in attachments {
                            //image/video attachment
                            if let type = attach.type, foundMessage.imageType != type {
                                foundMessage.imageType = type
                            }
                            
                            if let imagePram = attach.customParameters as? [String: String] {
                                if let imagePramz = imagePram["imageURL"], foundMessage.image != imagePramz {
                                    foundMessage.image = imagePramz
                                }
                                
                                if let imageUploadId = imagePram["uploadId"], foundMessage.image != imageUploadId {
                                    foundMessage.uploadMediaId = imageUploadId
                                }
                                
                                if let contactId = Int(imagePram["contactID"] ?? ""), foundMessage.contactID != contactId {
                                    foundMessage.contactID = contactId
                                }
                                
                                if let channelId = imagePram["channelID"], foundMessage.channelID != channelId {
                                    foundMessage.channelID = channelId
                                }

                                if let longitude = imagePram["longitude"], foundMessage.longitude != Double("\(longitude)") ?? 0 {
                                    foundMessage.longitude = Double("\(longitude)") ?? 0
                                }

                                if let latitude = imagePram["latitude"], foundMessage.latitude != Double("\(latitude)") ?? 0 {
                                    foundMessage.latitude = Double("\(latitude)") ?? 0
                                }

                                if let videoUrl = imagePram["videoURL"], foundMessage.image != "\(videoUrl)" {
                                    foundMessage.image = "\(videoUrl)"
                                }

                                if let placeholderId = imagePram["placeholderURL"], foundMessage.placeholderVideoImg != "\(placeholderId)" {
                                    foundMessage.placeholderVideoImg = "\(placeholderId)"
                                }

                                if let ratio = imagePram["mediaRatio"], foundMessage.mediaRatio != Double("\(ratio)") {
                                    foundMessage.mediaRatio = Double("\(ratio)") ?? 0.0
                                }
                            }
                        }
                    }
                    
                    realm.add(foundMessage, update: .all)
                    
                    self.checkSingleSurroundingValues(message: foundMessage, completion: {
                        DispatchQueue.main.async {
                            completion()
                        }
                    })
                })
            } else {
                let newData = MessageStruct()
                newData.id = object.id ?? ""
                newData.text = object.text ?? ""
                newData.dialogID = object.dialogID ?? ""
                newData.date = object.dateSent ?? Date()
                newData.senderID = Int(object.senderID)
                newData.positionRight = Int(object.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false

                for read in object.readIDs ?? [] {
                    if !newData.readIDs.contains(Int(truncating: read)) {
                        newData.readIDs.append(Int(truncating: read))
                    }
                }
                
                if !newData.readIDs.contains(Int(Session.current.currentUserID)) {
                    Chat.instance.read(object) { (error) in }
                }

                for deliv in object.deliveredIDs ?? [] {
                    if !newData.deliveredIDs.contains(Int(truncating: deliv)) {
                        newData.deliveredIDs.append(Int(truncating: deliv))
                    }
                }
                            
                //case delivered, sending, read, isTyping, edited, deleted, error
                if object.deliveredIDs?.count ?? 0 > 1 {
                    newData.messageState = .delivered
                } else {
                    newData.messageState = .sending
                }
                if object.readIDs?.count ?? 0 > 0 {
                    newData.messageState = .read
                }
                if object.edited {
                    newData.messageState = .editied
                }
                if object.removed {
                    newData.messageState = .deleted
                }
                if object.delayed {
                    newData.hadDelay = true
                }
                if (object.destroyAfterInterval > 0) {
                    newData.destroyDate = Int(object.destroyAfterInterval)
                }
                
                if let attachments = object.attachments {
                    for attach in attachments {
                        //image/video attachment
                        if let imagePram = attach.customParameters as? [String: String] {
                            if let typez = attach.type {
                                newData.imageType = typez
                            }

                            if let imagez = imagePram["imageURL"] {
                                newData.image = imagez
                            }
                            
                            if let imageUploadPram = imagePram["uploadId"] {
                                newData.uploadMediaId = imageUploadPram
                            }
                            
                            if let contactID = imagePram["contactID"] {
                                newData.contactID = Int(contactID) ?? 0
                            }
                            
                            if let channelId = imagePram["channelID"] {
                                newData.channelID = channelId
                            }

                            if let longitude = imagePram["longitude"] {
                                newData.longitude = Double("\(longitude)") ?? 0
                            }
                            
                            if let latitude = imagePram["latitude"] {
                                newData.latitude = Double("\(latitude)") ?? 0
                            }

                            if let videoUrl = imagePram["videoURL"] {
                                newData.image = "\(videoUrl)"
                            }
                            
                            if let placeholderId = imagePram["placeholderURL"] {
                                newData.placeholderVideoImg = "\(placeholderId)"
                            }

                            if let ratio = imagePram["mediaRatio"] {
                                newData.mediaRatio = Double("\(ratio)") ?? 0.0
                            }
                        }
                    }
                }

                try realm.write({
                    realm.add(newData, update: .all)
                    
                    self.checkSingleSurroundingValues(message: newData, completion: {
                        DispatchQueue.main.async {
                            completion()
                        }
                    })
                })
            }
            //else {
                //                let msg = Database.database().reference().child("Dialogs").child(object.dialogID ?? "").child(object.id ?? "")
                //                msg.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
                //                    updateMessageLike(messageID: object.id ?? "", messageLikeCount: Int(snapshot.childSnapshot(forPath: "likes").childrenCount))
                //                    updateMessageDislike(messageID: object.id ?? "", messageDislikeCount: Int(snapshot.childSnapshot(forPath: "dislikes").childrenCount))
                //                    completion()
                //                })
            //}
        } catch {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func checkSurroundingValues(dialogId: String, completion: @escaping () -> (Void)) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let messages = realm.objects(MessageStruct.self)
            let filteredMessages =  messages.filter("dialogID == %@", dialogId).filter("status != %@", messageStatus.removedTyping.rawValue).sorted(byKeyPath: "date", ascending: true)

            for (indexz, i) in filteredMessages.enumerated() {
                if let foundMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: i.id) {
                    let hasPrevious = i.id != filteredMessages.last?.id ? (filteredMessages[indexz + 1].senderID == i.senderID && filteredMessages[indexz + 1].date <= i.date.addingTimeInterval(86400) ? true : false) : false
                    let needsTimestamp = i.id != filteredMessages.first?.id ? (i.messageState != .isTyping && i.date >= filteredMessages[indexz - 1].date.addingTimeInterval(86400) ? true : false) : false
                    let isPriorWider = i.id != filteredMessages.first?.id ? (i.senderID == filteredMessages[indexz - 1].senderID && (i.date >= filteredMessages[indexz - 1].date.addingTimeInterval(86400) ? false : true) && i.bubbleWidth > filteredMessages[indexz - 1].bubbleWidth ? false : true) : true
                    let isHeader = i.id == filteredMessages.first?.id

                    try? realm.safeWrite({
                        if foundMessage.hasPrevious != hasPrevious {
                            foundMessage.hasPrevious = hasPrevious
                        }
                        
                        if foundMessage.needsTimestamp != needsTimestamp {
                            foundMessage.needsTimestamp = needsTimestamp
                        }

                        if foundMessage.isPriorWider != isPriorWider {
                            foundMessage.isPriorWider = isPriorWider
                        }
                        
                        if foundMessage.isHeader != isHeader {
                            foundMessage.isHeader = isHeader
                        }
                        
                        realm.add(foundMessage, update: .all)
                    })
                }
            }
            
            completion()
        }
    }
    
    func checkSingleSurroundingValues(message: MessageStruct, completion: @escaping () -> (Void)) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let messages = realm.objects(MessageStruct.self)
            let filteredMessages =  messages.filter("dialogID == %@", message.dialogID).filter("status != %@", messageStatus.removedTyping.rawValue).sorted(byKeyPath: "date", ascending: true)
            
            if let foundMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: message.id), let currentIndex = filteredMessages.firstIndex(of: message) {
                
                try? realm.safeWrite({
                    if filteredMessages.indices.contains(currentIndex - 1) {
                        let futureMsgIndex: MessageStruct = filteredMessages[currentIndex - 1]
                        let needsTimestamp = message.id != filteredMessages.first?.id ? (message.messageState != .isTyping && message.date >= futureMsgIndex.date.addingTimeInterval(86400) ? true : false) : false
                        let isPriorWider = message.id != filteredMessages.first?.id ? (message.senderID == futureMsgIndex.senderID && (message.date >= futureMsgIndex.date.addingTimeInterval(86400) ? false : true) && message.bubbleWidth > futureMsgIndex.bubbleWidth ? false : true) : true
                        let previousNeedsUpdatedhasPrevious = futureMsgIndex.id != filteredMessages.last?.id ? (futureMsgIndex.senderID == message.senderID && message.date <= futureMsgIndex.date.addingTimeInterval(86400) ? true : false) : false
                        
                        if foundMessage.needsTimestamp != needsTimestamp {
                            foundMessage.needsTimestamp = needsTimestamp
                        }
                        
                        if foundMessage.isPriorWider != isPriorWider {
                            foundMessage.isPriorWider = isPriorWider
                        }
                        
                        if futureMsgIndex.hasPrevious != previousNeedsUpdatedhasPrevious, let foundPreviousMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: futureMsgIndex.id) {
                                try? realm.safeWrite({
                                    foundPreviousMessage.hasPrevious = previousNeedsUpdatedhasPrevious
                                    realm.add(foundPreviousMessage, update: .all)
                                })
                        }
                    }

                    if filteredMessages.indices.contains(currentIndex + 1) {
                        let previousMsgIndex = filteredMessages[currentIndex + 1]
                        
                        let hasPrevious = message.id != filteredMessages.last?.id ? (previousMsgIndex.senderID == message.senderID && previousMsgIndex.date <= message.date.addingTimeInterval(86400) ? true : false) : false
                        
                        if foundMessage.hasPrevious != hasPrevious {
                            foundMessage.hasPrevious = hasPrevious
                        }
                    }
                    
                    let isHeader = foundMessage.id == filteredMessages.first?.id

                    if foundMessage.isHeader != isHeader {
                        foundMessage.isHeader = isHeader
                    }

                    realm.add(foundMessage, update: .all)
                })

                completion()
            } else {
                completion()
            }
        }
    }
    
    func sendMessage(dialog: DialogStruct, text: String, occupentID: [NSNumber]) {
        let message = ChatMessage.markable()
        message.markable = true
        message.text = text
        message.senderID = Session.current.currentUserID
        message.dialogID = dialog.id
        message.createdAt = Date()
        message.deliveredIDs = []
        
        self.insertMessage(message, completion: {
            NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

            //Wait for animation to play before making network request
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                pDialog.occupantIDs = occupentID
                
                pDialog.send(message) { (error) in
                    if error != nil {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                    }
                }
            }
        })
    }
    
    func sendContactMessage(dialog: DialogStruct, contactID: [Int], occupentID: [NSNumber]) {
        for id in contactID {
            let attachment = ChatAttachment()
            attachment["contactID"] = "\(id)"
            
            let message = ChatMessage.markable()
            message.markable = true
            message.text = "Shared contact"
            message.attachments = [attachment]
            message.senderID = Session.current.currentUserID
            message.dialogID = dialog.id
            message.createdAt = Date()
            message.deliveredIDs = []
            
            let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            self.insertMessage(message, completion: {
                NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    pDialog.send(message) { (error) in
                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                        }
                    }
                }
            })
        }
    }
    
    func sendPublicChannel(dialog: DialogStruct, contactID: [String], occupentID: [NSNumber]) {
        for id in contactID {
            let attachment = ChatAttachment()
            attachment["channelID"] = id
            
            let message = ChatMessage.markable()
            message.markable = true
            message.text = "Shared channel"
            message.attachments = [attachment]
            message.senderID = Session.current.currentUserID
            message.dialogID = dialog.id
            message.createdAt = Date()
            message.deliveredIDs = []
            
            let pDialog = ChatDialog(dialogID: dialog.id, type: occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            self.insertMessage(message, completion: {
                NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    pDialog.send(message) { (error) in
                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                        }
                    }
                }
            })
        }
    }
    
    func sendLocationMessage(dialog: DialogStruct, longitude: Double, latitude: Double, occupentID: [NSNumber]) {
        let attachment = ChatAttachment()
        attachment["longitude"] = "\(longitude)"
        attachment["latitude"] = "\(latitude)"
        
        let message = ChatMessage.markable()
        message.markable = true
        message.text = "Current location"
        message.attachments = [attachment]
        message.senderID = Session.current.currentUserID
        message.dialogID = dialog.id
        message.createdAt = Date()
        message.deliveredIDs = []
        
        let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
        
        self.insertMessage(message, completion: {
            NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                pDialog.send(message) { (error) in
                    if error != nil {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                    }
                }
            }
        })
    }
    
    func sendAudioAttachment(dialog: DialogStruct, audioURL: URL, occupentID: [NSNumber]) {
        do {
            let attachURL = try Data(contentsOf: audioURL, options: [.alwaysMapped , .uncached])
            Request.uploadFile(with: attachURL,
                               fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).m4a",
                               contentType: "audio/m4a",
                               isPublic: true,
                               progressBlock: { _ in
                                //Update UI with upload progress
            }, successBlock: { (blob) in
                let attachment = ChatAttachment()
                attachment.type = "audio/m4a"
                attachment["videoURL"] = blob.uid
                
                let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                pDialog.occupantIDs = occupentID
                
                let message = ChatMessage()
                message.text = "Audio message"
                message.attachments = [attachment]
                
                pDialog.send(message) { (error) in
                    self.insertMessage(message, completion: {
                        NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                        }
                    })
                }
            })
        } catch {  }
    }

    func sendGIFAttachment(dialog: DialogStruct, GIFAssets: [GIFMediaAsset], occupentID: [NSNumber]) {
        for attachment in GIFAssets {
            let attachmentz = ChatAttachment()
            attachmentz.type = "image/gif"
            attachmentz["imageURL"] = attachment.url
            attachmentz["mediaRatio"] = "\(attachment.mediaRatio)"

            let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            let message = ChatMessage()
            message.text = "GIF attachment"
            message.attachments = [attachmentz]
            message.senderID = Session.current.currentUserID
            message.dialogID = dialog.id
            message.createdAt = Date()
            message.deliveredIDs = []
            
            self.insertMessage(message, completion: {
                NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                    pDialog.send(message) { (error) in
                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                        }
                    }
                }
            })
        }
    }
    
    func sendPhotoAttachment(dialog: DialogStruct, attachmentImages: [UIImage], occupentID: [NSNumber]) {
        //NOTE: FUNC IS NOT USED
        
        for attachment in attachmentImages {
            let data = attachment.jpegData(compressionQuality: 1.0)
            
            Request.uploadFile(with: data!,
                               fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).png",
                               contentType: "image/png",
                               isPublic: true,
                               progressBlock: { (progress) in
                                //Update UI with upload progress
            }, successBlock: { (blob) in
                let attachment = ChatAttachment()
                attachment.type = "image/png"
                attachment.id = blob.uid
                
                let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                pDialog.occupantIDs = occupentID
                
                let message = ChatMessage()
                message.text = "Image Attachment"
                message.attachments = [attachment]
                
                pDialog.send(message) { (error) in
                    self.insertMessage(message, completion: {
                        NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                        }
                    })
                }
            })
        }
    }

    func sendVideoAttachment(dialog: DialogStruct, attachmentVideos: [PHAsset], occupentID: [NSNumber]) {
        for vid in attachmentVideos {
            let newVideIdString = NSUUID().uuidString
            let options = PHVideoRequestOptions()

            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: vid, options: options) { (asset, mix, args) in
                if let assz = asset as? AVURLAsset {
                    // URL OF THE VIDEO IS GOT HERE
                    DispatchQueue.main.async {
                        Request.uploadFile(with: assz.url,
                                           fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).mov",
                                           contentType: "video/mov",
                                           isPublic: true,
                                           progressBlock: { _ in
                            
                        }, successBlock: { (blob) in
                            self.sendVideoMessage(id: newVideIdString, dialog: dialog, videoId: blob.uid ?? "", occupentID: occupentID)
                        }) { (error) in

                        }
                    }
                }
            }
        }
    }
    
    func sendVideoMessage(id: String, dialog: DialogStruct, videoId: String, occupentID: [NSNumber]) {
        let attachment = ChatAttachment()
        attachment.type = "video/mov"
        attachment["videoURL"] = videoId

        let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
        
        let message = ChatMessage()
        message.markable = true
        message.text = "Video attachment"
        message.attachments = [attachment]
        message.senderID = Session.current.currentUserID
        message.dialogID = dialog.id
        message.createdAt = Date()
        message.deliveredIDs = []

        self.insertMessage(message, completion: {
            NotificationCenter.default.post(name: NSNotification.Name("scrollToLastId"), object: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                pDialog.send(message) { (error) in
                    if error != nil {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        self.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                    }
                }
            }
        })
    }
    
    func saveVideoInDocumentsDirectory(withAsset asset: AVAsset, completion: @escaping (_ url: URL?,_ error: Error?) -> Void) {
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        var outputURL = documentDirectory.appendingPathComponent("output")
        
        do {
            try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            let name = NSUUID().uuidString
            outputURL = outputURL.appendingPathComponent("\(name).mp4")
        } catch  {  }

        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else { return }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(outputURL, exportSession.error)
                
            case .failed:
                completion(nil, exportSession.error)
                
            case .cancelled:
                completion(nil, exportSession.error)
                
            default: break
            }
        }
    }
    
    func updateMessageDislikeAdded(messageID: String, userID: Int) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try realm.safeWrite {
                    if !realmContact.dislikedId.contains(userID) {
                        realmContact.dislikedId.append(userID)
                        realm.add(realmContact, update: .all)
                    }
                }
            }
        } catch {  }
    }
    
    func updateMessageDislikeRemoved(messageID: String, userID: Int) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try realm.safeWrite {
                    guard let removedDislikeIndex = realmContact.dislikedId.index(of: userID) else { return }

                    realmContact.dislikedId.remove(at: removedDislikeIndex)
                    realm.add(realmContact, update: .all)
                }
            }
        } catch {  }
    }
        
    func updateMessageLikeAdded(messageID: String, userID: Int) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try realm.safeWrite {
                    if !realmContact.likedId.contains(userID) {
                        realmContact.likedId.append(userID)
                        realm.add(realmContact, update: .all)
                    }
                }
            }
        } catch {  }
    }
    
    func updateMessageLikeRemoved(messageID: String, userID: Int) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try realm.safeWrite {
                    guard let removedLikeIndex = realmContact.likedId.index(of: userID) else { return }

                    realmContact.likedId.remove(at: removedLikeIndex)
                    realm.add(realmContact, update: .all)
                }
            }
        } catch {  }
    }
    
    func updateMessageState(messageID: String, messageState: messageStatus) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                //Contact is in Realm...
                if realmContact.messageState != messageState {
                    try realm.safeWrite {
                        realmContact.messageState = messageState
                        realm.add(realmContact, update: .all)
                    }
                }
            }
        } catch {  }
    }

    func updateMessageImageUrl(messageID: String, url: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                //Contact is in Realm...
                try realm.safeWrite {
                    realmContact.image = url
                    realm.add(realmContact, update: .all)
                }
            }
        } catch {  }
    }

    func updateMessageMediaProgress(messageID: String, progress: Double) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                //Contact is in Realm...
                try realm.safeWrite {
                    realmContact.uploadProgress = progress
                    realm.add(realmContact, update: .all)
                }
            }
        } catch {  }
    }
    
    func addTypingMessage(userID: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: userID) {
                //Contact is in Realm...
                if realmContact.messageState != .isTyping {
                    try realm.safeWrite {
                        realmContact.messageState = .isTyping
                        realmContact.date = Date()
                        realmContact.senderID = Int(userID) ?? 0
                        realmContact.positionRight = false
                        realm.add(realmContact, update: .all)
                        
                        self.checkSingleSurroundingValues(message: realmContact, completion: {  })
                    }
                }
            } else {
                let newData = MessageStruct()
                newData.id = userID
                newData.senderID = Int(userID) ?? 0
                newData.positionRight = false
                newData.dialogID = dialogID
                newData.date = Date()
                newData.messageState = .isTyping
                
                try realm.safeWrite {
                    realm.add(newData, update: .all)
                    
                    self.checkSingleSurroundingValues(message: newData, completion: {  })
                }
            }
        } catch {  }
    }
    
    func removeTypingMessage(userID: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let typingMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: userID) {
                //Contact is in Realm...
                try realm.safeWrite {
                    typingMessage.messageState = .removedTyping
                    realm.add(typingMessage, update: .all)
                }
            }
        } catch {  }
    }

    func updateBubbleWidth(messageId: String, width: Int) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                //Contact is in Realm...
                if realmContact.bubbleWidth != width {
                    try realm.safeWrite {
                        realmContact.bubbleWidth = width
                        realm.add(realmContact, update: .all)
                    }
                }
            }
        } catch {  }
    }

    func updateMessageDelayState(messageID: String, messageDelayed: Bool) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                //Contact is in Realm...
                if realmContact.hadDelay != messageDelayed {
                    try realm.safeWrite {
                        realmContact.hadDelay = messageDelayed
                        realm.add(realmContact, update: .all)
                    }
                }
            }
        } catch {  }
    }
    
    func removeAllMessages(completion: @escaping (Bool) -> ()) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let profile = realm.objects(MessageStruct.self)

            try? realm.safeWrite {
                realm.delete(profile)
            }
            completion(true)
        }
    }
}
