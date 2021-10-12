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
        } catch {  }
    }
    
    func removeContactRequest(userID: UInt) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: UserDefaults.standard.integer(forKey: "currentUserID")) {
                try realm.safeWrite ({
                    if let index = oldData.contactRequests.firstIndex(of: Int(userID)) {
                        oldData.contactRequests.remove(at: index)
                    }
                    realm.add(oldData, update: .all)
                })
            }
        } catch {  }
    }
}

extension ProfileRealmModel {
    
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
                            try realm.safeWrite({
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
                                
                                if let lastAddressBookUpdate = dict["lastAddressBookUpload"] as? String, foundContact.lastAddressBookUpdate != lastAddressBookUpdate {
                                    foundContact.lastAddressBookUpdate = lastAddressBookUpdate
                                }
                                
                                if let isLocalAuthOn = dict["faceID"] as? Bool, foundContact.isLocalAuthOn != isLocalAuthOn {
                                    foundContact.isLocalAuthOn = isLocalAuthOn
                                }
                                
                                if let isInfoPrivate = dict["isInfoPrivate"] as? Bool, foundContact.isInfoPrivate != isInfoPrivate {
                                    foundContact.isInfoPrivate = isInfoPrivate
                                }
                                
                                if let isMessagingPrivate = dict["isMessagingPrivate"] as? Bool, foundContact.isMessagingPrivate != isMessagingPrivate {
                                    foundContact.isMessagingPrivate = isMessagingPrivate
                                }
                                
                                realm.add(foundContact, update: .all)
                            })
                        } else {
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
                    } catch {  }
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
                    if let fullName = objects.fullName, oldData.fullName != fullName {
                        oldData.fullName = fullName
                    }
                    
                    if let lastOnline = objects.lastRequestAt, oldData.lastOnline != lastOnline {
                        oldData.lastOnline = lastOnline
                    }
                    
                    if let avatar = objects.avatar, oldData.avatar != avatar {
                        oldData.avatar = avatar
                    } else if objects.avatar == "", let avatarCube = PersistenceManager.shared.getCubeProfileImage(usersID: objects), oldData.avatar != avatarCube {
                        oldData.avatar = avatarCube
                    }
                    
                    if let website = objects.website, oldData.website != website {
                        oldData.website = website
                    }
                    
                    if let emailAddress = objects.email, oldData.emailAddress != emailAddress {
                        oldData.emailAddress = emailAddress
                    }
                    
                    //oldData.isLocalAuthOn = self.getCubeProfileLocalAuthSetting(usersID: objects) ?? false

                    realm.add(oldData, update: .all)

                    DispatchQueue.main.async {
                        completion()
                    }
                })
            } else {
                let newData = ProfileStruct()
                newData.id = Int(objects.id)
                newData.fullName = objects.fullName ?? "No Name"
                newData.lastOnline = objects.lastRequestAt ?? Date()
                newData.avatar = objects.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: objects) ?? ""
                newData.website = objects.website ?? ""
                newData.emailAddress = objects.email ?? ""
                //newData.isLocalAuthOn = self.getCubeProfileLocalAuthSetting(usersID: objects) ?? false

                try realm.safeWrite({
                    realm.add(newData, update: .all)
                    DispatchQueue.main.async {
                        completion()
                    }
                })
            }
        } catch {
            DispatchQueue.main.async {
                completion()
            }
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
            })
        } catch {  }
    }
    
    func getCubeProfileLocalAuthSetting(usersID: ConnectyCube.User) -> Bool? {
        if let data = usersID.customData?.data(using: .utf8) {
            if let customData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : String] {
                
                if let authSetting = customData?["local_auth"] {
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
