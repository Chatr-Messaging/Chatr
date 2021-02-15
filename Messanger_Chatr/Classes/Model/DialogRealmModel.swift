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

class DialogStruct : Object {
    @objc dynamic var id: String = ""
    @objc dynamic var fullName: String = "No Name"
    @objc dynamic var lastMessage: String = "no messages"
    @objc dynamic var owner: Int = 0
    @objc dynamic var onlineUserCount: Int = 0
    @objc dynamic var lastMessageDate: Date = Date()
    @objc dynamic var notificationCount: Int = 0
    @objc dynamic var image: String = ""
    @objc dynamic var isOpen : Bool = false
    @objc dynamic var typedText: String = ""
    @objc dynamic var dialogType: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var bio: String = ""
    @objc dynamic var isDeleted: Bool = false
    @objc dynamic var createdAt: Date = Date()
    let occupentsID = List<Int>()
    let adminID = List<Int>()

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
    lazy var shared = changeDialogRealmData()

    func fetchDialogs(completion: @escaping (Bool) -> ()) {
        //let queue = DispatchQueue(label: "com.brandon.chatrQueue", qos: .utility)

        //queue.async {
            print("the thread fwefawefor featching dialogs: \(Thread.isMultiThreaded()) and the thread: \(Thread.isMainThread)")
            let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]
            Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
                if dialogs.count > 0 {
                    self.insertDialogs(dialogs) { }
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
                if dialogs.count < paginator.limit { return }
                paginator.skip += UInt(dialogs.count)
            }) { (error) in
                print("Error in feteching dialogs... error: \(error.localizedDescription)")
                ChatrApp.connect()
                completion(false)
           }
            
            completion(true)
        //}
    }
    
    func insertDialogs<T>(_ objects: [T], completion: @escaping () -> Void) where T: ChatDialog {
        objects.forEach({ object in
            let config = Realm.Configuration(schemaVersion: 1)

            do {
                let realm = try Realm(configuration: config)
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
                    newData.avatar = object.photo ?? ""
                    newData.bio = object.dialogDescription ?? ""
                }
                
                if newData.id == UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" && UserDefaults.standard.bool(forKey: "localOpen") {
                    newData.isOpen = true
                }
                
                try realm.safeWrite({
                    realm.add(newData, update: .all)
                    print("Succsessfuly added new Dialog data! \(newData.isDeleted) and the threadis: \(Thread.current)")
                    completion()
                })
            } catch {
                print(error.localizedDescription)
                completion()
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
                    print("Succsessfuly added new Dialog data from updateOpen\(Thread.isMainThread)! \(String(describing: dialogResult.isOpen))")
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
    
    func deletePrivateConnectyDialog(dialogID: String, isOwner: Bool) {
        Request.deleteDialogs(withIDs: Set<String>([dialogID]), forAllUsers: isOwner ? true : false, successBlock: { (deletedObjectsIDs, notFoundObjectsIDs, wrongPermissionsObjectsIDs) in
            self.shared.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }) { (error) in
            print("error deleting dialog: \(error.localizedDescription) for dialog: \(dialogID)")
            self.shared.updateDialogDelete(isDelete: true, dialogID: dialogID)
        }
    }
    
    func unsubscribePublicConnectyDialog(dialogID: String) {
        Request.unsubscribeFromPublicDialog(withID: dialogID, successBlock: {
            self.shared.updateDialogDelete(isDelete: true, dialogID: dialogID)
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
