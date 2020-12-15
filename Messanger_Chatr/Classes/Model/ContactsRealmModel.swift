//
//  ContactsRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/20/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import ConnectyCube
import RealmSwift
import Firebase
import FirebaseStorage
import FirebaseDatabase

class ContactStruct : Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var fullName: String = "No Name"
    @objc dynamic var bio: String = ""
    @objc dynamic var lastOnline: Date = Date()
    @objc dynamic var createdAccount: Date = Date()
    @objc dynamic var phoneNumber: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var emailAddress: String = ""
    @objc dynamic var website: String = ""
    @objc dynamic var facebook: String = ""
    @objc dynamic var twitter: String = ""
    @objc dynamic var likeCount: Int = 0
    @objc dynamic var isOnline: Bool = false
    @objc dynamic var isFavourite: Bool = false
    @objc dynamic var hasQuickSnaped: Bool = false
    @objc dynamic var lastQuickSnapDate: String = ""
    @objc dynamic var isPremium: Bool = false
    @objc dynamic var isMyContact: Bool = false
    @objc dynamic var isInfoPrivate: Bool = false
    @objc dynamic var isMessagingPrivate: Bool = false
    
    var quickSnaps = List<String>()

    override static func primaryKey() -> String? {
        return "id"
    }
}

class ContactsRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
    var results: Results<Element>
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
    
    func filterContact(text: String) -> Results<Element> {
        if text == "" {
            return results.sorted(byKeyPath: "fullName", ascending: false)
        } else {
            return results.filter("fullName CONTAINS %@", text).sorted(byKeyPath: "fullName", ascending: false)
        }
    }
}

class changeContactsRealmData {
    
    func observeQuickSnaps() {
        //always looking at Users section
        let usersQuery = Database.database().reference().child("Users").child("\(UserDefaults.standard.integer(forKey: "currentUserID"))").child("quickSnaps")
        usersQuery.observe(.value, with: { (snapshot: DataSnapshot) in
            let arraySnapshot = snapshot.children.allObjects as! [DataSnapshot]
            arraySnapshot.forEach({ (child) in
                if (snapshot.value as? [String: Any]) != nil {
                    //New item ref has been added so we need to read it
                    let snapQuery = Database.database().reference().child("Users").child("\(UserDefaults.standard.integer(forKey: "currentUserID"))").child("quickSnaps").child(child.key).queryLimited(toLast: 50)
                    snapQuery.observeSingleEvent(of: .value, with: { postSnapshot in
                        let childArraySnapshot = postSnapshot.children.allObjects as! [DataSnapshot]
                        childArraySnapshot.forEach({ (snapChild) in
                            
                                //get contents of found post
                                let quickSnapQuery = Database.database().reference().child("Quick Snaps").child(snapChild.key)
                                quickSnapQuery.observeSingleEvent(of: .value, with: { snapshot2 in
                                    
                                //Save to QuickSnapStruct realm
                                if let dict = snapshot2.value as? [String: Any] {
                                    let config = Realm.Configuration(schemaVersion: 1)
                                    do {
                                        let realm = try Realm(configuration: config)
                                        if (realm.object(ofType: QuickSnapsStruct.self, forPrimaryKey: snapChild.key) == nil) {
                                            let newData = QuickSnapsStruct()
                                            newData.id = snapChild.key
                                            newData.fromUserID = dict["fromConnectyCubeID"] as? Int ?? 0
                                            newData.imageUrl = dict["imageURL"] as? String ?? ""
                                            newData.contact = try Realm(configuration: Realm.Configuration(schemaVersion: 1)).object(ofType: ContactStruct.self, forPrimaryKey: dict["fromConnectyCubeID"] as? Int ?? 0)

                                            if let timeStamp = dict["timestamp"] as? String {
                                                let dateFormatter = DateFormatter()
                                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
                                                if let timestampDate = dateFormatter.date(from: timeStamp) {
                                                    newData.sentDate = timestampDate
                                                }
                                            }

                                            try realm.safeWrite ({
                                                realm.add(newData, update: .all)
                                                print("Succsessfuly added new quick snap to realm! \(newData.fromUserID)")
                                            })
                                        } 
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                }
                            })
                            
                            let config = Realm.Configuration(schemaVersion: 1)
                            do {
                                let realm = try Realm(configuration: config)
                                if let oldData = realm.object(ofType: ContactStruct.self, forPrimaryKey: Int(child.key)) {
                                    try realm.safeWrite ({
                                        if !oldData.quickSnaps.contains(snapChild.key) {
                                            //Check snapChild.value is = 1 aka TRUE and then add to realm
                                            if String(describing: snapChild.value) == "Optional(1)" {
                                                oldData.quickSnaps.append(snapChild.key)
                                                print("contacts does NOT contain a TRUE quick snap!!!")
                                            }
                                        } else {
                                            print("contacts DOES contain quick snap id.")
                                        }
                                        oldData.hasQuickSnaped = true
                                        realm.add(oldData, update: .all)
                                    })
                                }
                            } catch {
                                print(error.localizedDescription)
                            }
                        })
                    })
                }
            })
        })
    }
    
    func observeFirebaseContact(contactID: Int) {
        print("starting observe firebase CONTACT!")
        //Database.database().isPersistenceEnabled = true
        let user = Database.database().reference().child("Users").child("\(contactID)")
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
          if snapshot.value as? Bool ?? false {
            print("Connected to firebase")
          } else {
            print("Not connected to firebase")
          }
        })
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            print("Metadata: Data fetched from \(snapshot.ref.database.isPersistenceEnabled)")
            if let dict = snapshot.value as? [String: Any] {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: contactID) {
                        print("Contact FOUND in Realm: \(snapshot.key) anddd faceID? : \(String(describing: dict["faceID"] as? Bool))")
                        try realm.safeWrite ({
                            foundContact.bio = dict["bio"] as? String ?? ""
                            foundContact.facebook = dict["facebook"] as? String ?? ""
                            foundContact.twitter = dict["twitter"] as? String ?? ""
                            foundContact.isPremium = dict["isPremium"] as? Bool ?? false
                            
                            realm.add(foundContact, update: .all)
                        })
                    } else {
                        print("Contact NOT in Realm: \(snapshot.key)")
                        let newData = ContactStruct()
                        newData.id = Int(snapshot.key) ?? 0
                        newData.bio = dict["bio"] as? String ?? ""
                        newData.facebook = dict["facebook"] as? String ?? ""
                        newData.twitter = dict["twitter"] as? String ?? ""
                        newData.isPremium = dict["isPremium"] as? Bool ?? false
                        newData.isMyContact = false
                        
                        try realm.safeWrite ({
                            realm.add(newData, update: .all)
                        })
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        })
    }
    
    func observeFirebaseContactReturn(contactID: Int, completion: @escaping (ContactStruct) -> ()){
        print("starting observe firebase CONTACT! return")
        let user = Database.database().reference().child("Users").child("\(contactID)")
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let newData = ContactStruct()
                newData.id = Int(snapshot.key) ?? 0
                newData.bio = dict["bio"] as? String ?? ""
                newData.facebook = dict["facebook"] as? String ?? ""
                newData.twitter = dict["twitter"] as? String ?? ""
                newData.isPremium = dict["isPremium"] as? Bool ?? false
                newData.isInfoPrivate = dict["isInfoPrivate"] as? Bool ?? false
                newData.isMessagingPrivate = dict["isMessagingPrivate"] as? Bool ?? false
                newData.isMyContact = false
                
                completion(newData)
            } else {
                completion(ContactStruct())
            }
        })
    }

    func updateContacts(contactList: [ContactListItem], completion: @escaping (Bool) -> ()) {
        var contactUsers: [NSNumber] = []
        for contact in contactList {
            contactUsers.append(NSNumber(value: contact.userID))
        }
        if contactUsers.count != 0 {
            Request.users(withIDs: contactUsers, paginator: Paginator.limit(300, skip: 0), successBlock: { (paginator, users) in
                for user in users {
                    print("users pulled from Connecty Cube: \(String(describing: user.fullName)) & \(String(describing: user.phone))")
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: user.id) {
                            try realm.safeWrite ({
                                foundContact.fullName = user.fullName ?? "empty name"
                                foundContact.phoneNumber = user.phone ?? "empty phone number"
                                foundContact.emailAddress = user.email ?? "empty email address"
                                foundContact.website = user.website ?? "empty website"
                                foundContact.lastOnline = user.lastRequestAt ?? Date()
                                foundContact.avatar = PersistenceManager().getCubeProfileImage(usersID: user) ?? ""
                                foundContact.isMyContact = true
                                foundContact.isInfoPrivate = false
                                foundContact.isMessagingPrivate = false
                                
                                realm.add(foundContact, update: .all)
                            })
                        } else {
                            print("Contact NOT in Realm: \(user.id)")
                            let newData = ContactStruct()
                            newData.id = Int(user.id)
                            newData.fullName = user.fullName ?? "empty name"
                            newData.phoneNumber = user.phone ?? "empty phone number"
                            newData.emailAddress = user.email ?? "empty email address"
                            newData.website = user.website ?? "empty website"
                            newData.isFavourite = false
                            newData.isInfoPrivate = false
                            newData.isMessagingPrivate = false
                            newData.isMyContact = true
                            newData.lastOnline = user.lastRequestAt ?? Date()
                            newData.avatar = PersistenceManager().getCubeProfileImage(usersID: user) ?? ""
                            newData.createdAccount = user.createdAt ?? Date()
                                
                            try realm.safeWrite ({
                                realm.add(newData, update: .all)
                                print("Succsessfuly added new contact to realm! \(newData.fullName)")
                                
                            })
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                completion(true)
            }) { (error) in
                print("error pulling connecty users: \(error.localizedDescription)")
                completion(true)
            }
        }
    }
    
    func deleteContact(contactID: Int, isMyContact: Bool, completion: @escaping (Bool) -> ()) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: contactID) {
                try realm.safeWrite ({
                    foundContact.isMyContact = isMyContact
                    realm.add(foundContact, update: .all)
                    completion(true)
                })
            } else {
                completion(true)
            }
        } catch {
            completion(true)
            print(error.localizedDescription)
        }
    }
    
    func getDialogContacts(occuIDs: [NSNumber], completion: @escaping ([String]) -> ()) {
        var avitarURLs: [String] = []
        Request.users(withIDs: occuIDs, paginator: Paginator.limit(100, skip: 0), successBlock: { (paginator, users) in
            for user in users {
                avitarURLs.append(PersistenceManager().getCubeProfileImage(usersID: user) ?? "")
            }
            completion(avitarURLs)
        })
        completion([String]())
    }
    
    func updateSingleRealmContact(userID: Int, completion: @escaping (Bool) -> ()) {
        Request.users(withIDs: [NSNumber(value: userID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
            for user in users {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: user.id) {
                        try realm.safeWrite ({
                            foundContact.fullName = user.fullName ?? "empty name"
                            foundContact.phoneNumber = user.phone ?? "empty phone number"
                            foundContact.emailAddress = user.email ?? "empty email address"
                            foundContact.website = user.website ?? "empty website"
                            foundContact.lastOnline = user.lastRequestAt ?? Date()
                            foundContact.avatar = PersistenceManager().getCubeProfileImage(usersID: user) ?? ""
                            foundContact.isMyContact = true
                            
                            realm.add(foundContact, update: .all)
                        })
                    } else {
                        print("Contact NOT in Realm: \(user.id)")
                        let newData = ContactStruct()
                        newData.id = Int(user.id)
                        newData.fullName = user.fullName ?? "empty name"
                        newData.phoneNumber = user.phone ?? "empty phone number"
                        newData.emailAddress = user.email ?? "empty email address"
                        newData.website = user.website ?? "empty website"
                        newData.isFavourite = false
                        newData.isMyContact = true
                        newData.lastOnline = user.lastRequestAt ?? Date()
                        newData.avatar = PersistenceManager().getCubeProfileImage(usersID: user) ?? ""
                        newData.createdAccount = user.createdAt ?? Date()
                            
                        try realm.safeWrite ({
                            realm.add(newData, update: .all)
                            print("Succsessfuly added new contact to realm! \(newData.fullName)")
                            
                        })
                    }
                } catch {
                    print(error.localizedDescription)
                    completion(false)
                }
            }
        })
    }
    
    func updateContactOnlineStatus(userID: UInt, isOnline: Bool) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: userID) {
                //Contact is in Realm...
                print("Contact is in Realm: \(realmContact.fullName)")
                try realm.safeWrite ({
                    realmContact.isOnline = isOnline
                    realmContact.lastOnline = Date()
                    realm.add(realmContact, update: .all)
                    print("Succsessfuly updated online status to realm! \(isOnline)")
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateContactFavouriteStatus(userID: UInt, favourite: Bool) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: userID) {
                //Contact is in Realm...
                try realm.safeWrite ({
                    realmContact.isFavourite = favourite
                    realm.add(realmContact, update: .all)
                    print("Succsessfuly updated favourite status in realm! \(favourite)")
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateContactHasQuickSnap(userID: [Int], hasQuickSnap: Bool) {
        for i in userID {
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let realmContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: i) {
                    //Contact is in Realm...
                    if realmContact.hasQuickSnaped != hasQuickSnap {
                        try realm.safeWrite ({
                            realmContact.hasQuickSnaped = hasQuickSnap
                            realm.add(realmContact, update: .all)
                        })
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func getRealmContact(userID: Int) -> ContactStruct {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let profileResult = realm.object(ofType: ContactStruct.self, forPrimaryKey: userID) {
                return profileResult
            }
        } catch {
            print(error.localizedDescription)
        }
        return ContactStruct()
    }
    
    func removeAllContacts() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let contacts = realm.objects(ContactStruct.self)

            try? realm.safeWrite {
                realm.delete(contacts)
            }
        }
    }
}
