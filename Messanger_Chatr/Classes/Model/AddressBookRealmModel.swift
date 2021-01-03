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
    
    func uploadAddressBook(completion: @escaping (Bool) -> ()) {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .denied || status == .restricted {
            AuthModel().requestContacts()
            completion(false)
        }
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            guard granted else {
                DispatchQueue.main.async {
                    AuthModel().requestContacts()
                }
                return
            }

            // get the contacts
            var contacts = [CNContact]()
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            do {
                try store.enumerateContacts(with: request) { contact, stop in
                    contacts.append(contact)
                }
            } catch {
                print(error)
            }

            if contacts.count > 0 {
                //self.removeAllAddressBook(completion: { _ in
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
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }

                    Request.uploadAddressBook(withUdid: UIDevice.current.identifierForVendor?.uuidString, addressBook: addressBook, force: false, successBlock: { (updates) in
                        print("Successfully uploaded all of your contacts to ConnectyCube backend! :D \(addressBook.count)")

                        changeProfileRealmDate().updateAddressBookSyncDate()
                        
                        completion(true)
                    }) { (error) in
                        print("Failed to uploaded all of your contacts to ConnectyCube backend: \(error.localizedDescription)")
                        completion(false)
                    }
                //})
            }
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