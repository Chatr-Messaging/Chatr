//
//  DiscoverViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/26/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI
import Firebase

class DiscoverViewModel: ObservableObject {

    func observeFeaturedDialogs(_ completion: @escaping (PublicDialogModel) -> Void, isHiddenIndicator:  @escaping (_ isHiddenIndicator: Bool?) -> Void) {
                
        Database.database().reference().child("Marketplace/featured").queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { snapshot in
            let arraySnapshot = (snapshot.children.allObjects as! [DataSnapshot]).reversed()
            arraySnapshot.forEach({ (child) in
                self.observeDialog(withId: child.key, completion: { dia in
                    completion(dia)
                    isHiddenIndicator(true)
                })
            })
        })
    }
    
    func observeDialog(withId id: String, completion: @escaping (PublicDialogModel) -> Void) {
        Database.database().reference().child("Marketplace/public_dialogs").child(id).observeSingleEvent(of: DataEventType.value, with: {
            snapshot in
            if let dict = snapshot.value as? [String: Any] {
                let post = PublicDialogModel.transformDialog(dict, key: snapshot.key)
                completion(post)
            }
        })
    }
    
    func loadTags(completion: @escaping ([publicTag]) -> Void) {
        let marketplaceTags = Database.database().reference().child("Marketplace").child("tags")
        var tag: [publicTag] = []

        marketplaceTags.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for i in dict {
                    tag.append(publicTag(title: i.key))
                }

                completion(tag)
            } else {
                completion(tag)
            }
        })
    }
}
