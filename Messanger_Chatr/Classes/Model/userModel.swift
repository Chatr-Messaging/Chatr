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

//struct User: Codable, Identifiable {
//    let id = UUID()
//    var fullName: String
//    var phoneNumber: String
//    var lastOnline: String
//    var createdProfile: String
//}

class Users: NSObject {
    //var sortedData: SortedDataProvider<User>!
    
    override init() {
        super.init()
        // Default sort view
//        sortedData = SortedDataProvider(sorting: { (u1, u2) -> ComparisonResult in
//            return u1.fullName!.compare(u2.fullName!)
//        })
//        Cache.users.register(sortedDataProvider: sortedData)
    }
    
    private let errorHandler : (_ error: Error) -> Void = {
        if let reason = ($0 as NSError).userInfo[NSLocalizedFailureReasonErrorKey] as! [AnyHashable : Any]? {
            if let errors = reason["errors"] as? [AnyHashable : Any] {
                if let key = errors.keys.first, let value = (errors[key] as! [String]).first {
                    print("users error with status: \(key)" + value)
                    return
                }
            }
        }
        print("users error: \($0.localizedDescription)")
    }
    
    /// Login with User Instance
    ///
    /// - Parameters:
    ///   - user: User to login
    ///   - completion: Completion handler.
    public func login(completion: @escaping () -> Void) {
        //user.password = Session.current.sessionDetails!.token'
        Auth.auth().currentUser?.getIDTokenResult(completion: { idToken, error in
            if error != nil {
                // Handle error
                print("the error for FireBase token: \(error!.localizedDescription)")
                completion()
            } else {
                if let tokenId = idToken {
                    
                    print("any token has expired... need to re-login expirationSate: \(tokenId.expirationDate) & sign in in seconds factor \(tokenId.signInSecondFactor) & sign in provider \(tokenId.signInProvider) & issued at date: \(tokenId.issuedAtDate)")
                    Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: tokenId.token, successBlock: { (userPulled) in
                        // save user core data here...
                        print("You are now loged in with ConnectyCube: \(String(describing: userPulled.avatar)) created at: \(String(describing: userPulled.createdAt)) & last sesh at: \(String(describing: userPulled.lastRequestAt)) with the name of: \(String(describing: userPulled.fullName))")
                        UserDefaults.standard.set(Session.current.currentUserID, forKey: "currentUserID")
                        changeProfileRealmDate().updateProfile(userPulled, completion: {
                            changeProfileRealmDate().observeFirebaseUser()
                            completion()
                        })
                    }, errorBlock: { error in
                        //self.errorHandler
                        ChatrApp.connect()
                        print("error logging into ConnectyCube: \(error.localizedDescription)")
                    })
                    
//                    if tokenId.expirationDate < Date() || Session.current.currentUserID == 0 || Session.current.tokenHasExpired {
//                        //firebase token date has expired...relogin
//                        print("any token has expired... need to re-login")
//                        Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: tokenId.token, successBlock: { (userPulled) in
//                            // save user core data here...
//                            print("You are now loged in with ConnectyCube: \(String(describing: userPulled.avatar)) created at: \(String(describing: userPulled.createdAt)) & last sesh at: \(String(describing: userPulled.lastRequestAt)) with the name of: \(String(describing: userPulled.fullName))")
//                            PersistenceManager.shared.setCubeProfile(userPulled)
//                            completion()
//                        }, errorBlock: self.errorHandler)
//                    } else {
//                        print("firebase has NOT expired but it will at: \(tokenId.expirationDate) & connectycube is: \(String(describing: Session.current.sessionDetails?.token))")
//                        completion()
//                    }
                }
            }
        })
        
        
        
//
//        if Session.current.currentUserID != 0, !Session.current.tokenHasExpired, !force {
//            print("Connecty Cube Session has NOT expired")
//             Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: user.password ?? "password", successBlock: { (userPulled) in
//                // save user core data here...
//                 print("the currect session had to force login: \(userPulled.id))")
//                PersistenceManager.shared.setCubeProfile(userPulled)
//                completion()
//            }, errorBlock: self.errorHandler)
//        } else {
//            print("Connecty Cube Session has expired")
//            Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: user.password ?? "password", successBlock: { (userPulled) in
//               // save user core data here...
//                print("the currect session had to force login: \(userPulled.id))")
//               PersistenceManager.shared.setCubeProfile(userPulled)
//               completion()
//           }, errorBlock: self.errorHandler)
//        }
    }
}
