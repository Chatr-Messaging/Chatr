//
//  ProfileRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/17/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import ConnectyCube
import RealmSwift
import FirebaseDatabase

class ProfileStruct : Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var fullName: String = "No Name"
    @objc dynamic var bio: String = ""
    @objc dynamic var lastOnline: Date = Date()
    @objc dynamic var phoneNumber: String = ""
    @objc dynamic var avatar: String = ""
    @objc dynamic var emailAddress: String = ""
    @objc dynamic var website: String = ""
    @objc dynamic var facebook: String = ""
    @objc dynamic var twitter: String = ""
    @objc dynamic var instagramAccessToken: String = ""
    @objc dynamic var instagramId: Int = 0
    @objc dynamic var isLocalAuthOn: Bool = false
    @objc dynamic var isPremium: Bool = false
    @objc dynamic var isInfoPrivate: Bool = false
    @objc dynamic var isMessagingPrivate: Bool = false
    @objc dynamic var lastAddressBookUpdate: String = "n/a"

    var contactRequests = List<Int>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class ProfileRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
    @Published var results: Results<Element>
    private var token: NotificationToken!
    let messageApi = changeProfileRealmDate.shared

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
    
    func addContactRequest(userID: UInt) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: UserDefaults.standard.integer(forKey: "currentUserID")) {
                try realm.safeWrite ({
                    if !oldData.contactRequests.contains(Int(userID)) {
                        oldData.contactRequests.append(Int(userID))
                    }
                    
                    realm.add(oldData, update: .all)
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func removeContactRequest(userID: UInt) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: UserDefaults.standard.integer(forKey: "currentUserID")) {
                try realm.safeWrite ({
                    if let index = oldData.contactRequests.firstIndex(of: Int(userID)) {
                        oldData.contactRequests.remove(at: index)
                        print("removed contact!")
                    }
                    realm.add(oldData, update: .all)
                })
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

class changeProfileRealmDate {
    init() { }
    static let shared = changeProfileRealmDate()
    
    func observeFirebaseUser(with id: Int) {
        //let queue = DispatchQueue.init(label: "com.brandon.chatrFirebbase", qos: .utility)
        //queue.async {
            let user = Database.database().reference().child("Users").child("\(id)")
            user.observe(.value, with: { (snapshot: DataSnapshot) in
                if let dict = snapshot.value as? [String: Any] {
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ProfileStruct.self, forPrimaryKey: id) {
                            print("Contact FOUND in Realm: \(snapshot.key) anddd faceID? : \(String(describing: dict["faceID"] as? Bool))")
                            try realm.safeWrite({
                                foundContact.bio = dict["bio"] as? String ?? ""
                                foundContact.facebook = dict["facebook"] as? String ?? ""
                                foundContact.twitter = dict["twitter"] as? String ?? ""
                                foundContact.instagramAccessToken = dict["instagramAccessToken"] as? String ?? ""
                                foundContact.instagramId = dict["instagramId"] as? Int ?? 0
                                foundContact.lastAddressBookUpdate = dict["lastAddressBookUpload"] as? String ?? ""
                                foundContact.isLocalAuthOn = dict["faceID"] as? Bool ?? false
                                foundContact.isPremium = dict["isPremium"] as? Bool ?? false
                                foundContact.isInfoPrivate = dict["isInfoPrivate"] as? Bool ?? false
                                foundContact.isMessagingPrivate = dict["isMessagingPrivate"] as? Bool ?? false
                                
                                realm.add(foundContact, update: .all)
                            })
                        } else {
                            print("Contact NOT in Realm: \(snapshot.key)")
                            let newData = ProfileStruct()
                            newData.id = Int(snapshot.key) ?? 0
                            newData.bio = dict["bio"] as? String ?? ""
                            newData.facebook = dict["facebook"] as? String ?? ""
                            newData.twitter = dict["twitter"] as? String ?? ""
                            newData.instagramAccessToken = dict["instagramAccessToken"] as? String ?? ""
                            newData.instagramId = dict["instagramId"] as? Int ?? 0
                            newData.lastAddressBookUpdate = dict["lastAddressBookUpload"] as? String ?? ""
                            newData.isLocalAuthOn = dict["faceID"] as? Bool ?? false
                            newData.isPremium = dict["isPremium"] as? Bool ?? false
                            newData.isInfoPrivate = dict["isInfoPrivate"] as? Bool ?? false
                            newData.isMessagingPrivate = dict["isMessagingPrivate"] as? Bool ?? false

                            try realm.safeWrite({
                                realm.add(newData, update: .all)
                            })
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            })
        //}
    }
    
    func updateProfile<T>(_ objects: T, completion: @escaping () -> Void) where T: User {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: Session.current.currentUser?.id) {
                try realm.safeWrite({
                    oldData.fullName = objects.fullName ?? "No Name"
                    oldData.lastOnline = objects.lastRequestAt ?? Date()
                    oldData.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: objects) ?? ""
                    oldData.website = objects.website ?? ""
                    oldData.emailAddress = objects.email ?? ""
                    //oldData.isLocalAuthOn = self.getCubeProfileLocalAuthSetting(usersID: objects) ?? false

                    realm.add(oldData, update: .all)
                    print("Succsessfuly updated Profile to Realm!")
                    completion()
                })
            } else {
                let newData = ProfileStruct()
                newData.id = Int(objects.id)
                newData.fullName = objects.fullName ?? "No Name"
                newData.lastOnline = objects.lastRequestAt ?? Date()
                newData.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: objects) ?? ""
                newData.website = objects.website ?? ""
                newData.emailAddress = objects.email ?? ""
                //newData.isLocalAuthOn = self.getCubeProfileLocalAuthSetting(usersID: objects) ?? false

                try realm.safeWrite({
                    realm.add(newData, update: .all)
                    print("Succsessfuly added new Profile to Realm!")
                    completion()
                })
            }
        } catch {
            print(error.localizedDescription)
            completion()
        }
    }
    
    func updateLocalAuth(bool: Bool) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let profileResult = realm.object(ofType: ProfileStruct.self, forPrimaryKey: Session.current.currentUser?.id)
            try? realm.safeWrite({
                profileResult?.isLocalAuthOn = bool
                realm.add(profileResult!, update: .all)
                print("Succsessfuly updated profile's isLocalAuth bool to: \(String(describing: profileResult?.isLocalAuthOn))")
            })
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getCubeProfileLocalAuthSetting(usersID: ConnectyCube.User) -> Bool? {
        if let data = usersID.customData?.data(using: .utf8) {
            if let customData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : String] {
                
                if let authSetting = customData["local_auth"] {
                    print("the users Auth Setting is: \(String(describing: authSetting))")
                    if authSetting == "true" {
                        return true
                    } else {
                        return false
                    }
                } else { return false }
            }
        }
        return false
    }
    
    func updateAddressBookSyncDate() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM-dd-yy"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcTimeZoneStr = formatter.string(from: date)
        
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: Session.current.currentUserID) {
                try realm.safeWrite({
                    oldData.lastAddressBookUpdate = utcTimeZoneStr
                    
                    realm.add(oldData, update: .all)
                    
                    Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["lastAddressBookUpload" : utcTimeZoneStr])
                })
            }
        } catch {
            
        }
    }

    func removeAllProfile() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let profile = realm.objects(ProfileStruct.self)

            try? realm.safeWrite {
                realm.delete(profile)
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    func isValidUrl(url: String) -> Bool {
        let urlRegEx = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: url)
        return result
    }
}
