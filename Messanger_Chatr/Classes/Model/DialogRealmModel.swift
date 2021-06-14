//
//  DialogRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/3/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import ConnectyCube
import RealmSwift
import Firebase

class DialogStruct : Object {
    @objc dynamic var id: String = ""
    @objc dynamic var fullName: String = "No Name"
    @objc dynamic var lastMessage: String = "no messages sent"
    @objc dynamic var owner: Int = 0
    @objc dynamic var onlineUserCount: Int = 0
    @objc dynamic var lastMessageDate: Date = Date()
    @objc dynamic var notificationCount: Int = 0
    @objc dynamic var image: String = ""
    @objc dynamic var isOpen : Bool = false
    @objc dynamic var typedText: String = ""
    @objc dynamic var dialogType: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var coverPhoto: String = ""
    @objc dynamic var bio: String = ""
    @objc dynamic var isDeleted: Bool = false
    @objc dynamic var canMembersType: Bool = false
    @objc dynamic var createdAt: Date = Date()
    let occupentsID = List<Int>()
    let adminID = List<Int>()
    let pinMessages = List<String>()
    let publicTags = List<String>()

    var messages: Results<MessageStruct> {
        if let realm = self.realm {
            return realm.objects(MessageStruct.self).filter(NSPredicate(format: "dialogID == %@", self.id)).filter("status != %@", messageStatus.removedTyping.rawValue).sorted(byKeyPath: "date", ascending: true)
        } else {
            return RealmSwift.List<MessageStruct>().filter("1 != 1")
        }
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class DialogRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
    @Published var results: Results<Element>
    private var token: NotificationToken!
    
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
    
    func filterDia(text: String) -> Results<Element> {
        if text == "" {
            return results.sorted(byKeyPath: "lastMessageDate", ascending: false)
        } else {
            return results.filter("fullName CONTAINS %@", text).sorted(byKeyPath: "lastMessageDate", ascending: false)
        }
    }
    
    func selectedDia(dialogID: String) -> Results<Element> {
        return results.filter("id == %@", dialogID)
    }
}

class changeDialogRealmData {
    init() { }
    static let shared = changeDialogRealmData()

    func fetchDialogs(completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]

        Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
            if dialogs.count > 0 {
                self.insertDialogs(dialogs) {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try! Realm(configuration: config)
                    let realmDialogs = realm.objects(DialogStruct.self)

                    try! realm.safeWrite {
                        for dia in realmDialogs {
                            dia.isDeleted = true
                            realm.add(dia, update: .all)
                        }
                    }
                }
            }
        }) { (error) in
            print("Error in fetching dialogs... error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    func insertDialogs(_ objects: [ChatDialog], completion: @escaping () -> Void) {
        objects.forEach({ object in
            let config = Realm.Configuration(schemaVersion: 1)

            do {
                let realm = try Realm(configuration: config)
                if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: object.id) {
                    try realm.safeWrite({
                        if let name = object.name, foundDialog.fullName != name {
                            foundDialog.fullName = name
                        }
                        
                        if let lastMessage = object.lastMessageText, foundDialog.lastMessage != lastMessage {
                            foundDialog.lastMessage = lastMessage
                        }
                        
                        if let lastMessageDate = object.lastMessageDate, foundDialog.lastMessageDate != lastMessageDate {
                            foundDialog.lastMessageDate = lastMessageDate
                        }
                        
                        if foundDialog.notificationCount != Int(object.unreadMessagesCount) {
                            foundDialog.notificationCount = Int(object.unreadMessagesCount)
                        }
                        
                        if let bio = object.dialogDescription, foundDialog.bio != bio {
                            foundDialog.bio = bio
                        }
                        
                        if let publicUrl = Blob.publicUrl(forFileUID: object.photo ?? ""), foundDialog.avatar != publicUrl {
                            foundDialog.avatar = publicUrl
                        }
                        
                        realm.add(foundDialog, update: .all)
                    })
                } else {
                    let newData = DialogStruct()
                    newData.id = object.id ?? ""
                    newData.fullName = object.name ?? "No Dialog Name"
                    newData.lastMessage = object.lastMessageText ?? "no messages sent"
                    newData.lastMessageDate = object.lastMessageDate ?? Date.init(timeIntervalSinceReferenceDate: 86400)
                    newData.notificationCount = Int(object.unreadMessagesCount)
                    newData.createdAt = object.createdAt ?? Date()
                    newData.owner = Int(object.userID)
                    
                    for occu in object.occupantIDs ?? [] {
                        newData.occupentsID.append(Int(truncating: occu))
                    }

                    if object.type == .private { newData.dialogType = "private" }
                    else if object.type == .group { newData.dialogType = "group" }
                    else if object.type == .broadcast { newData.dialogType = "broadcast" }
                    else if object.type == .public { newData.dialogType = "public" }

                    if object.type == .group || object.type == .public {
                        for admin in object.adminsIDs ?? [] {
                            newData.adminID.append(Int(truncating: admin))
                        }

                        if let publicUrl = Blob.publicUrl(forFileUID: object.photo ?? "") {
                            newData.avatar = publicUrl
                        }

                        newData.bio = object.dialogDescription ?? ""
                    }

                    if newData.id == UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" && UserDefaults.standard.bool(forKey: "localOpen") {
                        newData.isOpen = true
                    }
                    
                    try realm.safeWrite({
                        realm.add(newData, update: .all)
                    })
                }
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    completion()
                }
            }
        })

        DispatchQueue.main.async {
            completion()
        }
    }

    func observeFirebaseDialogReturn(dialogModel: DialogStruct, completion: @escaping (DialogStruct?, String?) -> ()) {
        //Request.occupants(forPublicDialogID: , paginator: , successBlock: , errorBlock: )
        print("starting observe firebase DIALOG! return \(dialogModel.id)")
        let user = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogModel.id)")
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                //let newData = DialogStruct()
                //dialogModel.id = dic
                dialogModel.coverPhoto = dict["cover_photo"] as? String ?? ""
                dialogModel.canMembersType = dict["canMembersType"] as? Bool ?? false
                for childSnapshot in snapshot.children {
                    let childSnap = childSnapshot as! DataSnapshot
                    if let dict2 = childSnap.value as? [String: Any] {
                        for tag in dict2 {
                            if !dialogModel.publicTags.contains(tag.key) {
                                dialogModel.publicTags.append(tag.key)
                            }
                        }
                    }
                }
                completion(dialogModel, dialogModel.coverPhoto)
//                let config = Realm.Configuration(schemaVersion: 1)
//                do {
//                    let realm = try Realm(configuration: config)
//                    if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogModel.id) {
//                        foundDialog.coverPhoto = dialogModel.coverPhoto
//                        foundDialog.canMembersType = dialogModel.canMembersType
//
//                        print("found dialogg trying to write..")
//                        try? realm.safeWrite({
//                            realm.add(foundDialog, update: .all)
//                        })
//
//                        completion(nil, dialogModel.coverPhoto)
//                    } else {
//                        completion(dialogModel, dialogModel.coverPhoto)
//                    }
//                } catch { completion(nil, nil) }
            } else {
                completion(nil, nil)
            }
        })
    }
    
    func updateDialogOpen(isOpen: Bool, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    dialogResult.isOpen = isOpen
                    realm.add(dialogResult, update: .all)
                }
            })
        } catch {
            print(error.localizedDescription)
        }
    }

    func addDialogPin(messageId: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    if !dialogResult.pinMessages.contains(where: { $0 == messageId }) && messageId != "" {
                        dialogResult.pinMessages.append(messageId)
                        realm.add(dialogResult, update: .all)
                    }
                    
                }
                
                if let messageResult = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                    messageResult.isPinned = true
                    realm.add(messageResult, update: .all)
                }
            })
        } catch {
            print(error.localizedDescription)
        }
    }

    func removeDialogPin(messageId: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    if let index = dialogResult.pinMessages.firstIndex(where: { $0 == messageId }) {
                        dialogResult.pinMessages.remove(at: index)
                        realm.add(dialogResult, update: .all)
                    }
                    
                    if let messageResult = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                        messageResult.isPinned = false
                        realm.add(messageResult, update: .all)
                    }
                }
            })
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateDialogDelete(isDelete: Bool, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    dialogResult.isDeleted = isDelete
                    realm.add(dialogResult, update: .all)
                    print("Succsessfuly deleted Dialog! \(String(describing: dialogResult.isDeleted))")
                }
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateDialogTypedText(text: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                try? realm.safeWrite({
                    dialogResult.typedText = text
                    realm.add(dialogResult, update: .all)
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateDialogNameDescription(name: String, description: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID)

            try? realm.safeWrite({
                dialogResult?.fullName = name
                dialogResult?.bio = description
                realm.add(dialogResult!, update: .all)
            })
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateDialogAvatar(avatar: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID)

            try? realm.safeWrite({
                dialogResult?.avatar = avatar
                realm.add(dialogResult!, update: .all)
            })
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateDialogCoverPhoto(coverPhoto: String, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID)

            try? realm.safeWrite({
                dialogResult?.coverPhoto = coverPhoto
                realm.add(dialogResult!, update: .all)
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getRealmDialog(dialogId: String) -> DialogStruct {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                return dialogResult
            }
        } catch {
            print(error.localizedDescription)
        }
        return DialogStruct()
    }
    
    func deletePrivateConnectyDialog(dialogID: String, isOwner: Bool) {
        Request.deleteDialogs(withIDs: Set<String>([dialogID]), forAllUsers: isOwner ? true : false, successBlock: { (deletedObjectsIDs, notFoundObjectsIDs, wrongPermissionsObjectsIDs) in
            self.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }) { (error) in
            print("error deleting dialog: \(error.localizedDescription) for dialog: \(dialogID)")
            self.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }
    }

    func unsubscribePublicConnectyDialog(dialogID: String) {
        Request.unsubscribeFromPublicDialog(withID: dialogID, successBlock: {
            self.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }, errorBlock: { error in
            print("error deleting public: \(error.localizedDescription) for dialog: \(dialogID)")
        })
    }
    
    func removeAllDialogs() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let profile = realm.objects(DialogStruct.self)

            try? realm.safeWrite {
                realm.delete(profile)
            }
        }
    }
}
