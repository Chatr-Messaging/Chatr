//
//  userModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/10/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import ConnectyCube
import FirebaseAuth

class Users: NSObject {
    
    override init() {
        super.init()
    }

    public func login(auth: AuthModel, completion: @escaping () -> Void) {
        //user.password = Session.current.sessionDetails!.token'
        Auth.auth().currentUser?.getIDTokenResult(completion: { idToken, error in
            if error != nil {
                DispatchQueue.main.async {
                    completion()
                }
            } else {
                if let tokenId = idToken {
                    Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: tokenId.token, successBlock: { (userPulled) in
                        // save user core data here...
                        UserDefaults.standard.set(userPulled.id, forKey: "currentUserID")
                        auth.profile.updateProfile(userPulled, completion: {
                            ChatrApp.chatInstanceConnect(id: userPulled.id)

                            DispatchQueue.main.async {
                                completion()
                            }
                        })
                    })
                }
            }
        })
    }
}
