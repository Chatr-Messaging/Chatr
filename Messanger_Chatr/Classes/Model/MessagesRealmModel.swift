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
    @objc dynamic var text: String = "No Name"
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
            return results.filter("status != %@", messageStatus.deleted.rawValue).filter("status != %@", messageStatus.deleted.rawValue).sorted(byKeyPath: "date", ascending: true)
        } else {
            return results.filter("dialogID == %@", dialogID).filter("status != %@", messageStatus.removedTyping.rawValue).filter("status != %@", messageStatus.deleted.rawValue).sorted(byKeyPath: "date", ascending: true)
        }
    }
}

class changeMessageRealmData {
    init() { }
    static let shared = changeMessageRealmData()

    func getMessageUpdates(dialogID: String, limit: Int, skip: Int, completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "date_sent", "mark_as_read" : "0"]
        Request.messages(withDialogID: dialogID, extendedRequest: extRequest, paginator: Paginator.limit(UInt(limit), skip: UInt(skip)), successBlock: { (messages, _) in
            self.insertMessages(messages, completion: {
                completion(true)
            })
        }){ (error) in
            print("error getting messages: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func loadMoreMessages(dialogID: String, currentCount: Int, completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "date_sent", "mark_as_read" : "0"]
        
        //For the 'skip' paginator... you need to get to total unread count & if greater than ~10 apply unread count
        //No need to scroll to bottom. When you hit the bottom, load ~10 more or so.
        Request.messages(withDialogID: dialogID, extendedRequest: extRequest, paginator: Paginator.limit(UInt(currentCount + 20), skip: 0), successBlock: { (messages, _) in
            self.insertMessages(messages, completion: { })
        }){ (error) in
            print("eror getting messages: \(error.localizedDescription)")
        }

        completion(true)
    }
    
    func insertMessages<T>(_ objects: [T], completion: @escaping () -> Void) where T: ChatMessage {
        objects.forEach({ (object) in
            let config = Realm.Configuration(schemaVersion: 1)

            do {
                let realm = try Realm(configuration: config)
                if realm.object(ofType: MessageStruct.self, forPrimaryKey: object.id ?? "") == nil {
                    let newData = MessageStruct()
                    var hasRead = false

                    newData.id = object.id ?? ""
                    newData.text = object.text ?? ""
                    newData.dialogID = object.dialogID ?? ""
                    newData.date = object.dateSent ?? Date()
                    newData.senderID = Int(object.senderID)
                    for read in object.readIDs ?? [] {
                        if read.intValue == Session.current.currentUserID {
                            hasRead = true
                        }
                        newData.readIDs.append(Int(truncating: read))
                    }
                    if !hasRead {
                        Chat.instance.read(object) { (error) in }
                    }
                    hasRead = false
                    for deliv in object.deliveredIDs ?? [] {
                        newData.deliveredIDs.append(Int(truncating: deliv))
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
                            if let uid = attach.id {
                                //let storage = Storage.storage()
                                if let fileURL = Blob.privateUrl(forFileUID: uid) {
                                    newData.image = fileURL
                                } else if let fileURLPub = Blob.publicUrl(forFileUID: uid) {
                                    newData.image = fileURLPub
                                }

                                newData.imageType = attach.type ?? ""
                            }
                            
                            if let contactID = attach.customParameters as? [String: String] {
                                newData.contactID = Int(contactID["contactID"] ?? "") ?? 0
                                print("the shared contact ID is: \(newData.contactID)")
                            }
                            
                            if let contactID = attach.customParameters as? [String: String] {
                                newData.channelID = contactID["channelID"] ?? ""
                                print("the shared channel ID is: \(newData.channelID)")
                            }
                            
                            if let longitude = attach.customParameters["longitude"] {
                                newData.longitude = Double("\(longitude)") ?? 0
                                print("the shared longitude ID is: \(newData.longitude) && \(longitude)")
                            }
                            
                            if let latitude = attach.customParameters["latitude"] {
                                newData.latitude = Double("\(latitude)") ?? 0
                                print("the shared latitude is: \(newData.latitude) && \(latitude)")
                            }
                            
                            if let videoUrl = attach.customParameters["videoId"] {
                                newData.image = "\(videoUrl)"
                                newData.imageType = attach.type ?? ""
                                print("the video is: \(attach.type) && \(videoUrl)")
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
            } catch {
                print(error.localizedDescription)
            }
        })
        DispatchQueue.main.async {
            completion()
        }
    }
    
    func insertMessage<T>(_ object: T, completion: @escaping () -> Void) where T: ChatMessage {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if realm.object(ofType: MessageStruct.self, forPrimaryKey: object.id ?? "") == nil {
                let newData = MessageStruct()
                newData.id = object.id ?? ""
                newData.text = object.text ?? ""
                newData.dialogID = object.dialogID ?? ""
                newData.date = object.dateSent ?? Date()
                newData.senderID = Int(object.senderID)
                
                for read in object.readIDs ?? [] {
                    newData.readIDs.append(Int(truncating: read))
                }
                for deliv in object.deliveredIDs ?? [] {
                    newData.deliveredIDs.append(Int(truncating: deliv))
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
                        if let uid = attach.id {
                            //let storage = Storage.storage()
                            if let fileURL = Blob.privateUrl(forFileUID: uid) {
                                newData.image = fileURL
                            } else if let fileURLPub = Blob.publicUrl(forFileUID: uid) {
                                newData.image = fileURLPub
                            }

                            newData.imageType = attach.type ?? ""
                        }
                        
                        if let contactID = attach.customParameters as? [String: String] {
                            newData.contactID = Int(contactID["contactID"] ?? "") ?? 0
                            print("the shared contact ID is: \(newData.contactID)")
                        }
                        
                        if let contactID = attach.customParameters as? [String: String] {
                            newData.channelID = contactID["channelID"] ?? ""
                            print("the shared channel ID is: \(newData.channelID)")
                        }
                        
                        if let longitude = attach.customParameters["longitude"] {
                            newData.longitude = Double("\(longitude)") ?? 0
                            print("the shared longitude ID is: \(newData.longitude) & \(longitude)")
                        }
                        
                        if let latitude = attach.customParameters["latitude"] {
                            newData.latitude = Double("\(latitude)") ?? 0
                            print("the shared latitude is: \(newData.latitude) && \(latitude)")
                        }

                        if let videoUrl = attach.customParameters["videoId"] {
                            newData.image = "\(videoUrl)"
                            newData.imageType = attach.type ?? ""
                            print("the video is: \(newData.image) && \(videoUrl)")
                        }
                    }
                }

                try realm.write({
                    realm.add(newData, update: .all)
                    DispatchQueue.main.async {
                        completion()
                    }
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
            print(error.localizedDescription)
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func sendMessage(dialog: DialogStruct, text: String, occupentID: [NSNumber]) {
        let message = ChatMessage.markable()
        message.markable = true
        message.text = text
        let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
        
        pDialog.send(message) { (error) in
            self.insertMessage(message, completion: {
                if error != nil {
                    print("error sending message: \(String(describing: error?.localizedDescription))")
                    self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                } else {
                    print("Success sending message to ConnectyCube server!")
                    //ChatrApp.auth.acceptScrolls = true
                }
            })
        }
    }
    
    func sendContactMessage(dialog: DialogStruct, contactID: [Int], occupentID: [NSNumber]) {
        for id in contactID {
            let attachment = ChatAttachment()
            attachment["contactID"] = "\(id)"
            
            let message = ChatMessage.markable()
            message.markable = true
            message.text = "Shared Contact"
            message.attachments = [attachment]
            
            let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            pDialog.send(message) { (error) in
                self.insertMessage(message, completion: {
                    if error != nil {
                        print("error sending message: \(String(describing: error?.localizedDescription))")
                        self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        print("Success sending message to ConnectyCube server!")
                    }
                })
            }
        }
    }
    
    func sendPublicChannel(dialog: DialogStruct, contactID: [String], occupentID: [NSNumber]) {
        for id in contactID {
            let attachment = ChatAttachment()
            attachment["channelID"] = id
            
            let message = ChatMessage.markable()
            message.markable = true
            message.text = "Shared chat \(dialog.fullName)"
            message.attachments = [attachment]
            
            let pDialog = ChatDialog(dialogID: dialog.id, type: occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            pDialog.send(message) { (error) in
                self.insertMessage(message, completion: {
                    if error != nil {
                        print("error sending message: \(String(describing: error?.localizedDescription))")
                        self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        print("Success sending message to ConnectyCube server!")
                    }
                })
            }
        }
    }
    
    func sendLocationMessage(dialog: DialogStruct, longitude: Double, latitude: Double, occupentID: [NSNumber]) {
        let attachment = ChatAttachment()
        attachment["longitude"] = "\(longitude)"
        attachment["latitude"] = "\(latitude)"
        
        let message = ChatMessage.markable()
        message.markable = true
        message.text = "Current Location"
        message.attachments = [attachment]
        
        let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
        
        pDialog.send(message) { (error) in
            self.insertMessage(message, completion: {
                if error != nil {
                    print("error sending message: \(String(describing: error?.localizedDescription))")
                    self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                } else {
                    print("Success sending message to ConnectyCube server!")
                }
            })
        }
    }
    
    func sendAudioAttachment(dialog: DialogStruct, audioURL: URL, occupentID: [NSNumber]) {
        do {
            let attachURL = try Data(contentsOf: audioURL, options: [.alwaysMapped , .uncached])
            Request.uploadFile(with: attachURL,
                               fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).m4a",
                               contentType: "audio/m4a",
                               isPublic: true,
                               progressBlock: { (progress) in
                                //Update UI with upload progress
                                print("upload progress is: \(progress)")
            }, successBlock: { (blob) in
                let attachment = ChatAttachment()
                attachment.type = "audio/m4a"
                attachment["videoId"] = blob.uid
                
                let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                pDialog.occupantIDs = occupentID
                
                let message = ChatMessage()
                message.text = "Audio Message"
                message.attachments = [attachment]
                
                pDialog.send(message) { (error) in
                    self.insertMessage(message, completion: {
                        if error != nil {
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            print("Success sending attachment to ConnectyCube server!")
                        }
                    })
                }
            }) { (error) in
                print("there is an error uploading audio attachment: \(error.localizedDescription)")
            }
        } catch {
            print("error setting url data")
        }
    }

    func sendGIFAttachment(dialog: DialogStruct, attachmentStrings: [String], occupentID: [NSNumber]) {
        for attachment in attachmentStrings {
            do {
                let attachURL = try Data(contentsOf: URL(string: attachment)!, options: [.alwaysMapped , .uncached])
                print("upload url is: \(attachURL.count)")
                Request.uploadFile(with: attachURL,
                                   fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).gif",
                                   contentType: "image/gif",
                                   isPublic: true,
                                   progressBlock: { (progress) in
                                    //Update UI with upload progress
                                    print("upload progress is: \(progress)")
                }, successBlock: { (blob) in
                    let attachment = ChatAttachment()
                    attachment.type = "image/gif"
                    attachment.id = blob.uid
                    
                    let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                    pDialog.occupantIDs = occupentID
                    
                    let message = ChatMessage()
                    message.text = "GIF Attachment"
                    message.attachments = [attachment]
                    
                    pDialog.send(message) { (error) in
                        self.insertMessage(message, completion: {
                            if error != nil {
                                print("error sending attachment: \(String(describing: error?.localizedDescription))")
                                self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                            } else {
                                print("Success sending attachment to ConnectyCube server!")
                            }
                        })
                    }
                }) { (error) in
                    print("there is an error uploading attachment: \(error.localizedDescription)")
                }
            } catch {
                print("error setting url data")
            }
        }
    }

    func sendPhotoAttachment(dialog: DialogStruct, attachmentImages: [UIImage], occupentID: [NSNumber]) {
        for attachment in attachmentImages {
            let data = attachment.jpegData(compressionQuality: 1.0)
            print("about to upload image... && \(data?.count)")
            Request.uploadFile(with: data!,
                               fileName: "\(UserDefaults.standard.integer(forKey: "currentUserID"))\(dialog.id)\(dialog.fullName)\(Date()).png",
                               contentType: "image/png",
                               isPublic: true,
                               progressBlock: { (progress) in
                                //Update UI with upload progress
                                print("upload progress is: \(progress)")
            }, successBlock: { (blob) in
                print("DONE upload image...")
                let attachment = ChatAttachment()
                attachment.type = "image/png"
                attachment.id = blob.uid
                
                let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
                pDialog.occupantIDs = occupentID
                
                let message = ChatMessage()
                message.text = "Image Attachment"
                message.attachments = [attachment]
                
                pDialog.send(message) { (error) in
                    print("SENT image...")
                    self.insertMessage(message, completion: {
                        if error != nil {
                            print("error sending attachment: \(String(describing: error?.localizedDescription))")
                            self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                        } else {
                            print("Success sending attachment to ConnectyCube server!")
                        }
                    })
                }
            }) { (error) in
                print("there is an error uploading attachment: \(error.localizedDescription)")
            }
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
                                           progressBlock: { (progress) in
                                            print("the upload progress is: \(progress)")
                        }, successBlock: { (blob) in
                            self.sendVideoMessage(id: newVideIdString, dialog: dialog, blobId: blob.uid ?? "", occupentID: occupentID)
                        }) { (error) in

                        }
                    }
                }
            }
        }
    }
    
    func sendVideoMessage(id: String, dialog: DialogStruct, blobId: String, occupentID: [NSNumber]) {
        let attachment = ChatAttachment()
        attachment.type = "video/mov"
        attachment["videoId"] = blobId

        let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
        
        let message = ChatMessage()
        message.markable = true
        message.text = "Video Attachment"
        message.attachments = [attachment]

        pDialog.send(message) { (error) in
            self.insertMessage(message, completion: {
                if error != nil {
                    print("error sending attachment: \(String(describing: error?.localizedDescription))")
                    self.updateMessageState(messageID: message.id ?? "", messageState: .error)
                } else {
                    print("Success sending video to ConnectyCube server!")
                }
            })
        }
    }
    
    func saveVideoInDocumentsDirectory(withAsset asset: AVAsset, completion: @escaping (_ url: URL?,_ error: Error?) -> Void) {
        let manager = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return }
        var outputURL = documentDirectory.appendingPathComponent("output")
        
        do {
            try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
            let name = NSUUID().uuidString
            outputURL = outputURL.appendingPathComponent("\(name).mp4")
        } catch let error {
            print(error.localizedDescription)
        }
        //Remove existing file
        _ = try? manager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else { return }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                completion(outputURL, exportSession.error)
                
            case .failed:
                print("failed \(exportSession.error?.localizedDescription ?? "")")
                completion(nil, exportSession.error)
                
            case .cancelled:
                print("cancelled \(exportSession.error?.localizedDescription ?? "")")
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
                        realm.add(realmContact, update: .all)
                    }
                }
            } else {
                let newData = MessageStruct()
                newData.id = userID
                newData.senderID = Int(userID) ?? 0
                newData.dialogID = dialogID
                newData.date = Date()
                newData.messageState = .isTyping
                
                try realm.safeWrite {
                    realm.add(newData, update: .all)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
        } catch {
            print(error.localizedDescription)
        }
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
