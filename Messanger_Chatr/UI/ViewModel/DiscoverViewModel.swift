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

    func searchPublicDialog(withText text: String, completion: @escaping (PublicDialogModel) -> Void) {
        Database.database().reference().child("Marketplace/public_dialogs").queryOrdered(byChild: "name").queryStarting(atValue: text, childKey: "name").queryEnding(atValue: text+"\u{f8ff}", childKey: "name").observeSingleEvent(of: .value, with: {
            snapshot in
            snapshot.children.forEach({ (s) in
                let child = s as! DataSnapshot
                if let dict = child.value as? [String: Any] {
                    let post = PublicDialogModel.transformDialog(dict, key: child.key)
                    completion(post)
                }
            })
        })
    }
    
    func observeTopDialogs(kPagination: Int, loadMore: Bool, postCount: Int? = 0, completion: @escaping (PublicDialogModel) -> Void, isHiddenIndicator:  @escaping (_ isHiddenIndicator: Bool?) -> Void) {
        
        let query = Database.database().reference().child("Marketplace").child("public_dialogs").queryOrdered(byChild: "members").queryLimited(toLast: UInt(kPagination))
        query.observeSingleEvent(of: .value, with: {
            snapshot in
            var items = snapshot.children.allObjects
            print(items)
            if loadMore {
                print("cont Post \(String(describing: postCount)) and \(items.count)")
                if items.count <= postCount! {
                    isHiddenIndicator(true)
                    return
                }
                items.removeLast(postCount!)
            }
            let myGroup = DispatchGroup()
            var results = Array(repeating: (PublicDialogModel()), count: items.count)
            for (index, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()
                self.observeDialog(withId: item.key, completion: { dia in
                    results[index] = (dia)
                    myGroup.leave()
                })
            }
            myGroup.notify(queue: .main) {
                for result in results {
                    completion(result)
                }
                isHiddenIndicator(true)
            }
        })
    }
    
    func observeTopTagDialogs(tagId: String, kPagination: Int, loadMore: Bool, postCount: Int? = 0, completion: @escaping (PublicDialogModel) -> Void, isHiddenIndicator:  @escaping (_ isHiddenIndicator: Bool?) -> Void) {
        
        let query = Database.database().reference().child("Marketplace/tags").child(tagId).child("dialogs").queryOrdered(byChild: "members").queryLimited(toLast: UInt(kPagination))
        query.observeSingleEvent(of: .value, with: {
            snapshot in
            var items = snapshot.children.allObjects
            print(items)
            if loadMore {
                if items.count <= postCount! {
                    isHiddenIndicator(true)
                    return
                }
                items.removeLast(postCount!)
            }
            let myGroup = DispatchGroup()
            var results = Array(repeating: (PublicDialogModel()), count: items.count)
            for (index, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()
                self.observeDialog(withId: item.key, completion: { dia in
                    results[index] = (dia)
                    myGroup.leave()
                })
            }
            myGroup.notify(queue: .main) {
                for result in results {
                    completion(result)
                }
                isHiddenIndicator(true)
            }
        })
    }
    
    func fetchTagsDialogCount(_ tagId: String, completion: @escaping (Int) -> Void) {
        Database.database().reference().child("Marketplace/tags").child(tagId).child("dialogs").observeSingleEvent(of: .value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }

    func observeRecentDialogs(kPagination: Int, loadMore: Bool, postCount: Int? = 0, completion: @escaping (PublicDialogModel) -> Void, isHiddenIndicator:  @escaping (_ isHiddenIndicator: Bool?) -> Void) {
        
        let query = Database.database().reference().child("Marketplace").child("public_dialogs").queryOrdered(byChild: "creation_order").queryLimited(toLast: UInt(kPagination))
        query.observeSingleEvent(of: .value, with: {
            snapshot in
            var items = snapshot.children.allObjects
            print(items)
            if loadMore {
                if items.count <= postCount! {
                    isHiddenIndicator(true)
                    return
                }
                items.removeLast(postCount!)
            }
            let myGroup = DispatchGroup()
            var results = Array(repeating: (PublicDialogModel()), count: items.count)
            for (index, item) in (items as! [DataSnapshot]).enumerated() {
                myGroup.enter()
                self.observeDialog(withId: item.key, completion: { dia in
                    results[index] = (dia)
                    myGroup.leave()
                })
            }
            myGroup.notify(queue: .main) {
                for result in results {
                    completion(result)
                }
                isHiddenIndicator(true)
            }
        })
    }

    func observeFeaturedDialogs(_ completion: @escaping (PublicDialogModel) -> Void, isHiddenIndicator:  @escaping (_ isHiddenIndicator: Bool?) -> Void) {
                
        Database.database().reference().child("Marketplace/featured").queryLimited(toFirst: 6).observeSingleEvent(of: .value, with: { snapshot in
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
                for i in dict.sorted(by: { $0.key < $1.key }) {
                    tag.append(publicTag(title: i.key))
                }

                completion(tag)
            } else {
                completion(tag)
            }
        })
    }
}
