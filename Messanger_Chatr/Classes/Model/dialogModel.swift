//
//  dialogModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/15/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import ConnectyCube
import RealmSwift

struct Dialog : Identifiable {
    let id: String
    var fullName: String
    var lastMessage: String
    var lastMessageDate: Date
    var updateCount: Int
    var image: String
    var isOpen : Bool = false
    var typedText: String
}

class Dialogs: NSObject, ObservableObject {
    var auth: AuthModel = AuthModel()
    @Published var contactRequestIDs: [UInt] = []

    override init() {
        super.init()
    }

    public func getDialogUpdates(completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]
        Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
            PersistenceManager.shared.insertDialogs(dialogs) {
                //self.dialogData = self.persistenceManager.fetchDialogs()
                completion(true)
            }
            if dialogs.count < paginator.limit { return }
            paginator.skip += UInt(dialogs.count)
        })
    }
}


