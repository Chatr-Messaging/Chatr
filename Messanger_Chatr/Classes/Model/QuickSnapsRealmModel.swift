//
//  QuickSnapsRealmModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/31/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import FirebaseDatabase
import ConnectyCube

class QuickSnapsStruct : Object {
    @objc dynamic var id: String = ""
    @objc dynamic var fromUserID: Int = 0
    @objc dynamic var sentDate: Date = Date()
    @objc dynamic var imageUrl: String = ""
    @objc dynamic var contact: ContactStruct?

    override static func primaryKey() -> String? {
        return "id"
    }
}

class QuickSnapsRealmModel<Element>: ObservableObject where Element: RealmSwift.RealmCollectionValue {
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
}

class changeQuickSnapsRealmData {
    
    func sendQuickSnap(image: Data, sendTo: [Int], completion: @escaping (Bool) -> Void) {
        uploadSnapToFirebaseStorage(data: image, onSuccess: { (snapImgUrl) in
            if snapImgUrl != "error" {
                let newPostId = Database.database().reference().child("Quick Snaps").childByAutoId().key
                let newPostReference = Database.database().reference().child("Quick Snaps").child(newPostId ?? "no post id")
                guard let currentFirebaseUser = Auth.auth().currentUser else {
                    return
                }
                
                let date = Date()
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                let utcTimeZoneStr = formatter.string(from: date)
                
                let dict = ["fromConnectyCubeID": Session.current.currentUserID, "fromFirebseID": currentFirebaseUser.uid, "to": sendTo, "timestamp": utcTimeZoneStr, "imageURL": snapImgUrl] as [String : Any]
                
                newPostReference.setValue(dict, withCompletionBlock: {
                    (error, ref) in
                    if error != nil {
                        print("Error setting realtime database: \(String(describing: error?.localizedDescription))")
                        
                        completion(false)
                        return
                    }
                    //Add to users feed...
                    //.sorted(by: { $0.sentDate.compare($1.sentDate) == .orderedDescending })
                    for user in sendTo {
                        Database.database().reference().child("Users").child("\(user)").child("quickSnaps").child("\(Session.current.currentUserID)").updateChildValues([newPostId ?? "no post id" : true])
                    }
                    //need to push the notification here too...
                    
                    completion(true)
                })
            } else {
                print("error receiving image URL")
                completion(false)
            }
        })
    }
    
    func uploadSnapToFirebaseStorage(data: Data, onSuccess: @escaping (_ imageUrl: String) -> Void) {
        let photoIdString = NSUUID().uuidString
        let storageRef = Storage.storage().reference(forURL: Constants.FirebaseStoragePath).child("QuickSnaps").child("\(Session.current.currentUser?.fullName ?? "no name")" + photoIdString)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(data, metadata: metadata) { (metadata, error) in
            if error != nil {
                print("Error uploading the quick Snap image: \(String(describing: error?.localizedDescription))")
                onSuccess("error")
                return
            }
            storageRef.downloadURL { url, error in
                if error != nil {

                } else {
                    print("the metatdata is: \(String(describing: metadata))")
                    onSuccess((url?.absoluteString)!)
                }
            }
        }
    }
    
    func removeAllQuickSnaps() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try! Realm(configuration: config)
            let quickSnaps = realm.objects(QuickSnapsStruct.self)

            try? realm.safeWrite {
                realm.delete(quickSnaps)
            }
        }
    }
}
