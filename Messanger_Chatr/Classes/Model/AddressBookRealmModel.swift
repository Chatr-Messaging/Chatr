//
//  AddressBookRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/4/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import Contacts
import ConnectyCube
import FirebaseDatabase

class AddressBookStruct : Object {
    @objc dynamic var name: String = ""
    @objc dynamic var phone: String = ""

    override static func primaryKey() -> String? {
        return "phone"
    }
}

class AddressBookRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
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
    
    func filterAddressBook(text: String) -> Results<Element> {
        if text == "" {
            return results.sorted(byKeyPath: "name", ascending: false)
        } else {
            return results.filter("name CONTAINS %@", text).sorted(byKeyPath: "name", ascending: false)
        }
    }
}

class changeAddressBookRealmData {
    init() { }
    static let shared = changeAddressBookRealmData()
    let advancedViewModel = AdvancedViewModel()
    
    func uploadAddressBook(completion: @escaping (Bool) -> ()) {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                DispatchQueue.main.async {
                    self.advancedViewModel.requestContacts()
                }
                return
            }

            var contacts = [CNContact]()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])

            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    contacts.append(contact)
                }
            } catch {  }

            if !contacts.isEmpty {
                let addressBook = NSMutableOrderedSet()

                for contact in contacts {
                    if let contactPhone = contact.phoneNumbers.first?.value.stringValue {
                        //Loacl address book to upload online
                        let newContact = AddressBookContact()
                        newContact.name = contact.givenName + " " + contact.familyName
                        newContact.phone = contactPhone
                    
                        addressBook.add(newContact)

                        //Realm contact book
                        let config = Realm.Configuration(schemaVersion: 1)
                        do {
                            let realm = try Realm(configuration: config)
                            if let oldData = realm.object(ofType: AddressBookStruct.self, forPrimaryKey: contactPhone) {
                                try realm.safeWrite({
                                    oldData.name = contact.givenName + " " + contact.familyName
                                    
                                    realm.add(oldData, update: .all)
                                })
                            } else {
                                let newData = AddressBookStruct()
                                newData.name = contact.givenName + " " + contact.familyName
                                newData.phone = contactPhone

                                try realm.safeWrite({
                                    realm.add(newData, update: .all)
                                })
                            }
                        } catch {  }
                    }
                }

                Request.uploadAddressBook(withUdid: UIDevice.current.identifierForVendor?.uuidString, addressBook: addressBook, force: false, successBlock: { (updates) in
                    DispatchQueue.main.async {
                        self.updateAddressBookSyncDate()
                        
                        completion(true)
                    }
                }) { _ in
                    completion(false)
                }
            }
        }
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
    
    func removeAllAddressBook(completion: @escaping (Bool) -> Void) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            let contacts = realm.objects(AddressBookStruct.self)

            try realm.safeWrite {
                realm.delete(contacts)
                completion(true)
            }
        } catch {
            completion(false)
        }
    }
}
