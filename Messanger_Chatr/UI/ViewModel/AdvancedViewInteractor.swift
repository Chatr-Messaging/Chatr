//
//  AdvancedViewInteractor.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/16/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import Contacts
import Combine

class AdvancedViewInteractor {
    @Published var contactsPermission: Bool = false
    
    init(contactsPermission: Bool) {
        self.contactsPermission = contactsPermission
    }
    
    func checkContactsPermission() {
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            self.contactsPermission = false
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.contactsPermission = true
        }
    }
    
    func requestContacts() {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts){succeeded, err in
                guard err == nil && succeeded else {
                    self.contactsPermission = false
                    return
                }
                if succeeded {
                    self.contactsPermission = true
                }
            }
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            print("Contacts are authorized")
            self.contactsPermission = true

        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
//            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.contactsPermission = false
        }
    }
}
