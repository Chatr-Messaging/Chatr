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
    @objc dynamic var publicMemberCount: Int = 0
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
            self.insertDialogs(dialogs) {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try! Realm(configuration: config)
                    let realmDialogs = realm.objects(DialogStruct.self)

                    try! realm.safeWrite {
                        for dia in realmDialogs {
                            if !dialogs.contains(where: { $0.id == dia.id }) {
                                dia.isDeleted = true
                                realm.add(dia, update: .all)
                            }
                        }

                        DispatchQueue.main.async {
                            completion(true)
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
                        
                        if object.type == .public && foundDialog.publicMemberCount != Int(object.occupantsCount) {
                            foundDialog.publicMemberCount = Int(object.occupantsCount)
                        }
                        
                        if object.type == .group && foundDialog.occupentsID.count != Int(object.occupantIDs?.count ?? 0) {
                            foundDialog.occupentsID.removeAll()
                            for occu in object.occupantIDs ?? [] {
                                foundDialog.occupentsID.append(Int(truncating: occu))
                            }
                        }
                        
                        if object.type == .public && foundDialog.adminID.count != Int(object.adminsIDs?.count ?? 0) {
                            foundDialog.adminID.removeAll()
                            for admin in object.adminsIDs ?? [] {
                                foundDialog.adminID.append(Int(truncating: admin))
                            }
                        }
                        
                        if let bio = object.dialogDescription, foundDialog.bio != bio {
                            foundDialog.bio = bio
                        }
                        
                        if let publicUrl = object.photo, foundDialog.avatar != publicUrl {
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
                    else if object.type == .public {
                        newData.dialogType = "public"
                        newData.publicMemberCount = Int(object.occupantsCount)
                    }

                    if object.type == .group || object.type == .public {
                        for admin in object.adminsIDs ?? [] {
                            newData.adminID.append(Int(truncating: admin))
                        }

                        if let publicUrl = object.photo {
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
    
    func insertPublicDialogMembers(dialogId: String, users: [ConnectyCube.User], completion: @escaping () -> Void) {
        let config = Realm.Configuration(schemaVersion: 1)

        do {
            let realm = try Realm(configuration: config)
            if let foundDialog = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                try realm.safeWrite({
                    foundDialog.occupentsID.removeAll()
                    for i in users {
                        let id = Int(i.id)
                        if !foundDialog.occupentsID.contains(where: { $0 == id }) && id != 0 {
                            foundDialog.occupentsID.append(id)
                        }
                    }

                    realm.add(foundDialog, update: .all)
                    completion()
                })
            } else {
                //not found dia
                completion()
            }
        } catch { completion() }
    }
    
    func toggleFirebaseMemberCount(dialogId: String, isJoining: Bool, totalCount: Int?, onSuccess: @escaping (PublicDialogModel) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        //let dialogRef = Api.Post.REF_POSTS.child(dialogId)
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogId)")

        dialogRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var dia = currentData.value as? [String : AnyObject] {
                let userId = "\(UserDefaults.standard.integer(forKey: "currentUserID"))"
                var likes: Dictionary<String, Bool>

                likes = dia["members"] as? [String : Bool] ?? [:]
                var likeCount = dia["memberCount"] as? Int ?? 0
                
                if isJoining {
                    if let count = totalCount {
                        likeCount = count
                    } else if likes[userId] == nil {
                        likeCount += 1
                    }
                    likes[userId] = true
                } else if let _ = likes[userId] {
                    likeCount -= 1
                    likes.removeValue(forKey: userId)
                }
                
                dia["memberCount"] = likeCount as AnyObject?
                dia["members"] = likes as AnyObject?
                
                currentData.value = dia
                
                return TransactionResult.success(withValue: currentData)
            }
        
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                onError(error.localizedDescription)
            }

            if let dict = snapshot?.value as? [String: Any], let snap = snapshot?.key {
                let dia = PublicDialogModel.transformDialog(dict, key: snap)
                onSuccess(dia)
            }
        }
    }
    
    func addFirebaseAdmins(dialogId: String, adminIds: [NSNumber], onSuccess: @escaping (PublicDialogModel) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogId)")

        for id in adminIds {
            dialogRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                if var dia = currentData.value as? [String : AnyObject] {
                    let userId = "\(id)"
                    var admins: Dictionary<String, Bool>

                    admins = dia["adminIds"] as? [String : Bool] ?? [:]
                    admins[userId] = true
                    dia["adminIds"] = admins as AnyObject?
                    
                    currentData.value = dia
                    
                    return TransactionResult.success(withValue: currentData)
                }
            
                return TransactionResult.success(withValue: currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    onError(error.localizedDescription)
                }

                if let dict = snapshot?.value as? [String: Any], let snap = snapshot?.key {
                    let dia = PublicDialogModel.transformDialog(dict, key: snap)
                    onSuccess(dia)
                }
            }
        }
    }

    func removeFirebaseAdmin(dialogId: String, adminId: NSNumber, onSuccess: @escaping (PublicDialogModel) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogId)")

        dialogRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var dia = currentData.value as? [String : AnyObject] {
                let userId = "\(adminId)"
                var admins: Dictionary<String, Bool>

                admins = dia["adminIds"] as? [String : Bool] ?? [:]
                admins.removeValue(forKey: userId)
                
                dia["adminIds"] = admins as AnyObject?
                
                currentData.value = dia
                
                return TransactionResult.success(withValue: currentData)
            }
        
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                onError(error.localizedDescription)
            }

            if let dict = snapshot?.value as? [String: Any], let snap = snapshot?.key {
                let dia = PublicDialogModel.transformDialog(dict, key: snap)
                onSuccess(dia)
            }
        }
    }

    func removePublicFirebaseChild(dialogId: String) {
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogId)")

        dialogRef.removeValue { (_, _) in }
    }

    func reportFirebasePublicDialog(dialogId: String, onSuccess: @escaping (PublicDialogModel) -> Void, onError: @escaping (_ errorMessage: String?) -> Void) {
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs").child("\(dialogId)")

        dialogRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var dia = currentData.value as? [String : AnyObject] {
                let userId = "\(UserDefaults.standard.integer(forKey: "currentUserID"))"
                var reports: Dictionary<String, Bool>

                reports = dia["reports"] as? [String : Bool] ?? [:]
                var reportCount = dia["reportCount"] as? Int ?? 0
                
                if reports[userId] == nil {
                    reportCount += 1
                    reports[userId] = true
                }
                
                dia["reportCount"] = reportCount as AnyObject?
                dia["reports"] = reports as AnyObject?
                
                currentData.value = dia
                
                return TransactionResult.success(withValue: currentData)
            }
        
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                onError(error.localizedDescription)
            }

            if let dict = snapshot?.value as? [String: Any], let snap = snapshot?.key {
                let dia = PublicDialogModel.transformDialog(dict, key: snap)
                onSuccess(dia)
            }
        }
    }
    
    func fetchTotalCountPublicDialogs(completion: @escaping (Int) -> Void) {
        let dialogRef = Database.database().reference().child("Marketplace").child("public_dialogs")

        dialogRef.observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }
    
    func updateDialogOpen(isOpen: Bool, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    if dialogResult.dialogType == "public" {
                        if !dialogResult.canMembersType, dialogResult.owner != UserDefaults.standard.integer(forKey: "currentUserID"), !dialogResult.adminID.contains(UserDefaults.standard.integer(forKey: "currentUserID")) {
                            UserDefaults.standard.set(!dialogResult.canMembersType, forKey: "disabledMessaging")
                        }
                    } else {
                        UserDefaults.standard.set(false, forKey: "disabledMessaging")
                    }
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
    
    func updateDialogMembersType(canType: Bool, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            try? realm.safeWrite({
                if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID) {
                    dialogResult.canMembersType = canType
                    
                    realm.add(dialogResult, update: .all)
                    print("Successfully updated or adjusted Dialog! \(String(describing: dialogResult.canMembersType))")
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
                    print("Successfully deleted or adjusted Dialog! \(String(describing: dialogResult.isDeleted))")
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
    
    func updateDialogNameDescription(name: String, description: String, membersType: Bool, dialogID: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogID)

            try? realm.safeWrite({
                dialogResult?.fullName = name
                dialogResult?.bio = description
                dialogResult?.canMembersType = membersType
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
            self.toggleFirebaseMemberCount(dialogId: dialogID, isJoining: false, totalCount: nil, onSuccess: { _ in
                self.updateDialogDelete(isDelete: true, dialogID: dialogID)
                changeDialogRealmData.shared.removeFirebaseAdmin(dialogId: dialogID, adminId: NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID")), onSuccess: { _ in }, onError: { _ in })
            }, onError: { err in
                print("error deleting public: \(String(describing: err)) for dialog: \(dialogID)")
                self.updateDialogDelete(isDelete: true, dialogID: dialogID)
            })
        }) { (error) in
            print("error deleting dialog: \(error.localizedDescription) for dialog: \(dialogID)")
            self.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }
    }

    func unsubscribePublicConnectyDialog(dialogID: String, isOwner: Bool) {
        Request.unsubscribeFromPublicDialog(withID: dialogID, successBlock: {
            if isOwner {
                changeDialogRealmData.shared.removePublicFirebaseChild(dialogId: dialogID)
                self.updateDialogDelete(isDelete: true, dialogID: dialogID)
                UserDefaults.standard.set(false, forKey: "localOpen")
                
                return
            }
            
            self.toggleFirebaseMemberCount(dialogId: dialogID, isJoining: false, totalCount: nil, onSuccess: { _ in
                UserDefaults.standard.set(false, forKey: "localOpen")
                self.updateDialogDelete(isDelete: true, dialogID: dialogID)
                self.removePublicMemberRealmDialog(memberId: UserDefaults.standard.integer(forKey: "currentUserID"), dialogId: dialogID)
                changeDialogRealmData.shared.removeFirebaseAdmin(dialogId: dialogID, adminId: NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID")), onSuccess: { _ in }, onError: { _ in })
            }, onError: { err in
                print("error deleting public: \(String(describing: err)) for dialog: \(dialogID)")
            })
        }, errorBlock: { error in
            print("error deleting public: \(error.localizedDescription) for dialog: \(dialogID)")
        })
    }
    
    func removePublicMemberRealmDialog(memberId: Int, dialogId: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                if let index = dialogResult.occupentsID.firstIndex(of: memberId) {
                    try? realm.safeWrite({
                        dialogResult.occupentsID.remove(at: index)
                        dialogResult.publicMemberCount -= 1

                        realm.add(dialogResult, update: .all)
                    })
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func addPublicMemberCountRealmDialog(count: Int, dialogId: String) {
        //I need this func to update public member count live
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let dialogResult = realm.object(ofType: DialogStruct.self, forPrimaryKey: dialogId) {
                try? realm.safeWrite({
                    dialogResult.publicMemberCount = count

                    realm.add(dialogResult, update: .all)
                })
            }
        } catch {
            print(error.localizedDescription)
        }
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
