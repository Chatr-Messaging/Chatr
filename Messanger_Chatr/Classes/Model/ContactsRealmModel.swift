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
    @objc dynamic var instagramAccessToken: String = ""
    @objc dynamic var instagramId: Int = 0
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
    
    func filterContact(text: String) -> Results<Element> {
        if text == "" {
            return results.sorted(byKeyPath: "fullName", ascending: false)
        } else {
            return results.filter("fullName CONTAINS %@", text).sorted(byKeyPath: "fullName", ascending: false)
        }
    }
}

class changeContactsRealmData {
    init() { }
    static let shared = changeContactsRealmData()

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
        let user = Database.database().reference().child("Users").child("\(contactID)")
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: contactID) {
                        //print("Contact FOUND in Realm: \(snapshot.key) anddd contacts faceID? : \(String(describing: dict["faceID"] as? Bool))")
                        try realm.safeWrite ({
                            if let bio = dict["bio"] as? String, foundContact.bio != bio {
                                foundContact.bio = bio
                            }
                            
                            if let facebook = dict["facebook"] as? String, foundContact.facebook != facebook {
                                foundContact.facebook = facebook
                            }
                            
                            if let twitter = dict["twitter"] as? String, foundContact.twitter != twitter {
                                foundContact.twitter = twitter
                            }
                            
                            if let instagramAccessToken = dict["instagramAccessToken"] as? String, foundContact.instagramAccessToken != instagramAccessToken {
                                foundContact.instagramAccessToken = instagramAccessToken
                            }
                            
                            if let instagramId = dict["instagramId"] as? Int, foundContact.instagramId != instagramId {
                                foundContact.instagramId = instagramId
                            }
                            
                            if let isPremium = dict["isPremium"] as? Bool, foundContact.isPremium != isPremium {
                                foundContact.isPremium = isPremium
                            }
                                                        
                            try realm.safeWrite({
                                realm.add(foundContact, update: .all)
                            })
                        })
                    } else {
                        print("Contact NOT in Realm: \(snapshot.key)")
                        let newData = ContactStruct()
                        newData.id = Int(snapshot.key) ?? 0
                        newData.bio = dict["bio"] as? String ?? ""
                        newData.facebook = dict["facebook"] as? String ?? ""
                        newData.twitter = dict["twitter"] as? String ?? ""
                        newData.instagramAccessToken = dict["instagramAccessToken"] as? String ?? ""
                        newData.instagramId = dict["instagramId"] as? Int ?? 0
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
    
    func observeFirebaseContactReturn(contactID: Int, completion: @escaping (ContactStruct) -> ()) {
        print("starting observe firebase CONTACT! return")
        let user = Database.database().reference().child("Users").child("\(contactID)")
        user.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let newData = ContactStruct()
                newData.id = Int(snapshot.key) ?? 0
                newData.bio = dict["bio"] as? String ?? ""
                newData.facebook = dict["facebook"] as? String ?? ""
                newData.twitter = dict["twitter"] as? String ?? ""
                newData.instagramAccessToken = dict["instagramAccessToken"] as? String ?? ""
                newData.instagramId = dict["instagramId"] as? Int ?? 0
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
        self.removeOldContact(completion: { 
            for contact in contactList {
                contactUsers.append(NSNumber(value: contact.userID))
            }
            if contactUsers.count != 0 {
                Request.users(withIDs: contactUsers, paginator: Paginator.limit(300, skip: 0), successBlock: { (paginator, users) in
                    for user in users {
                        //print("users pulled from Connecty Cube: \(String(describing: user.fullName)) & \(String(describing: user.phone))")
                        let config = Realm.Configuration(schemaVersion: 1)
                        do {
                            let realm = try Realm(configuration: config)
                            if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: user.id) {
                                try realm.safeWrite ({
                                    if let name = user.fullName, foundContact.fullName != name {
                                        foundContact.fullName = name
                                    }
                                    
                                    if let phoneNumber = user.phone, foundContact.phoneNumber != phoneNumber {
                                        foundContact.phoneNumber = phoneNumber
                                    }
                                    
                                    if let emailAddress = user.email, foundContact.emailAddress != emailAddress {
                                        foundContact.emailAddress = emailAddress
                                    }
                                    
                                    if let website = user.website, foundContact.website != website {
                                        foundContact.website = website
                                    }
                                   
                                    if let lastRequest = user.lastRequestAt, foundContact.lastOnline != lastRequest {
                                        foundContact.lastOnline = lastRequest
                                    }
                                    
                                    if let avatar = user.avatar, avatar != "", foundContact.avatar != avatar {
                                        foundContact.avatar = avatar
                                    } else if user.avatar == "", let avatarCube = PersistenceManager.shared.getCubeProfileImage(usersID: user), avatarCube != "", foundContact.avatar != avatarCube {
                                        foundContact.avatar = avatarCube
                                    }

                                    foundContact.isMyContact = true
                                    foundContact.isInfoPrivate = false
                                    foundContact.isMessagingPrivate = false
                                    
                                    realm.add(foundContact, update: .all)
                                    self.observeFirebaseContact(contactID: foundContact.id)
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
                                if let lastRequest = user.lastRequestAt {
                                    newData.lastOnline = lastRequest
                                }
                                newData.avatar = user.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: user) ?? ""
                                newData.createdAccount = user.createdAt ?? Date()
                                    
                                try realm.safeWrite ({
                                    realm.add(newData, update: .all)
                                    self.observeFirebaseContact(contactID: newData.id)
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
        })
    }
    
    func removeOldContact(completion: @escaping () -> ()) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            for i in realm.objects(ContactStruct.self) {
                if let user = Chat.instance.contactList?.contacts.first(where: { $0.userID == i.id }) {
                    print("running through contact: \(String(describing: user.userID))")
                } else {
                    print("DELETING contact: \(String(describing: i.id))")
                    try realm.safeWrite ({
                        i.isMyContact = false
                        realm.add(i, update: .all)
                    })
                }
            }

            DispatchQueue.main.async {
                completion()
            }
        } catch {
            DispatchQueue.main.async {
                completion()
            }
            print(error.localizedDescription)
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
                })
                completion(true)
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
                avitarURLs.append(user.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: user) ?? "")
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
                            if let name = user.fullName, foundContact.fullName != name {
                                foundContact.fullName = name
                            }
                            
                            if let phoneNumber = user.phone, foundContact.phoneNumber != phoneNumber {
                                foundContact.phoneNumber = phoneNumber
                            }
                            
                            if let emailAddress = user.email, foundContact.emailAddress != emailAddress {
                                foundContact.emailAddress = emailAddress
                            }
                            
                            if let website = user.website, foundContact.website != website {
                                foundContact.website = website
                            }

                            if let lastRequest = user.lastRequestAt, foundContact.lastOnline != lastRequest {
                                foundContact.lastOnline = lastRequest
                            }
                            
                            if let avatar = user.avatar, avatar != "", foundContact.avatar != avatar {
                                foundContact.avatar = avatar
                            } else if user.avatar == "", let avatarCube = PersistenceManager.shared.getCubeProfileImage(usersID: user), avatarCube != "", foundContact.avatar != avatarCube {
                                foundContact.avatar = avatarCube
                            }
                            
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
                        if let lastRequest = user.lastRequestAt {
                            newData.lastOnline = lastRequest
                        }
                        newData.avatar = user.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: user) ?? ""
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

    func getRealmContact(userID: Int) -> ContactStruct? {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let profileResult = realm.object(ofType: ContactStruct.self, forPrimaryKey: userID) {
                return profileResult
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
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
