//
//  Mesages.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/7/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import UIKit
import ConnectyCube

class MessagesObject: NSObject, ObservableObject {
    
    override init() {
        super.init()
    }
    
    public func getMessageUpdates(dialogID: String, completion: @escaping (Bool) -> ()) {
        let extRequest : [String: String] = ["sort_asc" : "dateSent"]
        Request.messages(withDialogID: dialogID, extendedRequest: extRequest, paginator: Paginator.limit(100, skip: 0), successBlock: { (messages, paginator) in
            PersistenceManager.shared.insertMessages(messages, completion: {
                completion(true)
            })
            if messages.count < paginator.limit { return }
            paginator.skip += UInt(messages.count)
        }){ (error) in
            print("eror getting messages: \(error.localizedDescription)")
        }
    }
    
    func sendMessage(dialogID: String, text: String, occupentID: [NSNumber]) {
        let message = ChatMessage.markable()
        message.text = text
        let pDialog = ChatDialog(dialogID: dialogID, type: occupentID.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupentID
                
        pDialog.send(message) { (error) in
            if error != nil {
                print("error sending message: \(String(describing: error?.localizedDescription))")
            } else {
                print("Success sending message to ConnectyCube server!")
                ChatrApp.messages.getMessageUpdates(dialogID: dialogID, completion: { newMessages in
                    print("Message model successfully pulled new messages!")
                    ChatrApp.dialogs.getDialogUpdates() { results in }
                })
                /*
                PersistenceManager.shared.insertSingleMessage(message, completion: {
                    print("Success saving sent message! \(String(describing: message.id))")
                    ChatrApp.messages.getMessageUpdates(dialogID: dialogID, completion: { newMessages in
                        print("Message model successfully pulled new messages!")
                        ChatrApp.dialogs.getDialogUpdates() { results in }
                    })
                })
                */
            }
        }
        
//        if occupentID.count > 2 {
//            pDialog.join { (error) in
//                print("joined?")
//                if error == nil {
//                    print("success joining group")
//                    pDialog.send(message) { (error) in
//                        if error != nil {
//                            print("error sending message: \(String(describing: error?.localizedDescription))")
//                        } else {
//                            PersistenceManager.shared.insertSingleMessage(message, completion: {
//                                print("Success saving sent message! \(String(describing: message.id))")
//                                AuthModel().insertLocalMessgae(messageId: message.id ?? "")
//                                pDialog.leave { (error) in
//                                    print("Success left group chat!")
//                                }
//                            })
//                        }
//                    }
//                } else {
//                    print("error joining group: \(String(describing: error?.localizedDescription))")
//                }
//            }
//        } else {
//            pDialog.join { (error) in
//                print("joined??:")
//                pDialog.send(message) { (error) in
//                    if error != nil {
//                        print("error sending message: \(String(describing: error?.localizedDescription))")
//                    } else {
//                        print("Success sending message!")
//                        PersistenceManager.shared.insertSingleMessage(message, completion: {
//                            print("Success saving sent message! \(String(describing: message.id))")
//                            AuthModel().insertLocalMessgae(messageId: message.id ?? "")
//                        })
//                    }
//                }
//            }
//        }
    }
}
