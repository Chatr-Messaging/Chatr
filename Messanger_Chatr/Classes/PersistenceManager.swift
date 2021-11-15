//
//  PersistenceManager.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/24/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Combine
import ConnectyCube

class PersistenceManager: ObservableObject {

    init() {}
    static let shared = PersistenceManager()

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Messanger_Chatr")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    lazy var context = persistentContainer.viewContext

    // MARK: - Core Data Saving support
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    /*
    func insertDialogs<T>(_ objects: [T], completion: @escaping () -> Void) where T: ChatDialog {
        print("all the sent dialogs fetch count: \(objects.count)")
        //self.deleteAll(object: self.fetch(UserDialogs.self))
        objects.forEach({ (object) in
            if self.fetchDialogs(dialogID: object.id).isEmpty {
                let dialogz = UserDialogs(context: self.context)
                dialogz.id = object.id
                dialogz.lastMessage = object.lastMessageText
                dialogz.date = object.lastMessageDate
                dialogz.notifications = Int32(object.unreadMessagesCount)
                dialogz.occupentsID = object.occupantIDs as NSObject?
                if let dialogName = object.name {
                    //dialog has name
                    dialogz.name = dialogName
                } else {
                    //dialog does not have name so we use the lastest users message
                    dialogz.from = Int32(object.lastMessageUserID)
                }
                if object.occupantIDs?.count ?? 0 > 2 {
                    //dialog has more than 1 user
                    dialogz.isPrivate = false
                } else {
                    //dialog is private
                    dialogz.from = Int32(object.recipientID)
                    dialogz.isPrivate = true
                }
            } else {
                let setDialog = self.fetchDialogs(dialogID: object.id)[0]
                setDialog.id = object.id
                setDialog.name = object.name
                setDialog.lastMessage = object.lastMessageText
                setDialog.date = object.lastMessageDate
                setDialog.notifications = Int32(object.unreadMessagesCount)

                if object.occupantIDs?.count ?? 0 > 2 {
                    //dialog has more than 1 user
                    setDialog.isPrivate = false
                } else {
                    //dialog is private
                    setDialog.from = Int32(object.recipientID)
                    setDialog.isPrivate = true
                }
            }
            self.save()
        })
        
        DispatchQueue.main.async {
            completion()
        }
    }

    func fetchDialogs(dialogID: String? = "", nameText: String? = "") -> [UserDialogs] {
        let entityName = String(describing: UserDialogs.self)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserDialogs.date, ascending: false)]
        if dialogID != "" || nameText != "" {
            fetchRequest.predicate = NSCompoundPredicate.init(type: .or, subpredicates: [NSPredicate(format: "id CONTAINS[cd] %@", dialogID ?? ""), NSPredicate(format: "name CONTAINS %@", nameText ?? "")])
        }
        
        do {
            let fetchedObjects = try context.fetch(fetchRequest)
            
            return fetchedObjects as! [UserDialogs]
        } catch {
            print(error)
            return [UserDialogs]()
        }
    }
    
    func insertMessages<T>(_ objects: [T], completion: @escaping () -> Void) where T: ChatMessage {
        print("all the sent messages fetch count: \(objects.count)")
        objects.forEach({ (object) in
            if self.fetchMessages(messageID: object.id).isEmpty {
                let message = ChatMessages(context: self.context)
                message.id = object.id
                message.dialogID = object.dialogID
                message.senderID = Int32(object.senderID)
                message.text = object.text
                message.date = object.dateSent
            } else {
                let setMessage = self.fetchMessages(messageID: object.id)[0]
                setMessage.id = object.id
                setMessage.dialogID = object.dialogID
                setMessage.senderID = Int32(object.senderID)
                setMessage.text = object.text
                setMessage.date = object.dateSent
            }
            self.save()
        })
        DispatchQueue.main.async {
            completion()
        }
    }
     */
    /*
    func fetchMessages(dialogID: String? = "", messageID: String? = "") -> [ChatMessages] {
        let entityName = String(describing: ChatMessages.self)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessages.date, ascending: true)]
        if dialogID != "" || messageID != ""{
            fetchRequest.predicate = NSCompoundPredicate.init(type: .or, subpredicates: [NSPredicate(format: "dialogID == %@", dialogID ?? ""), NSPredicate(format: "id == %@", messageID ?? "")])
        }

        do {
            let fetchedObjects = try self.context.fetch(fetchRequest)

            return fetchedObjects as? [ChatMessages] ?? []
        } catch {
            print(error)
            return [ChatMessages]()
        }
    }
    */
//    func fetchSelectedMessages() -> [ChatMessages] {
//        let entityName = String(describing: ChatMessages.self)
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
//        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessages.date, ascending: true)]
//        fetchRequest.predicate = NSPredicate(format: "dialogID == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
//
//        do {
//            let fetchedObjects = try self.context.fetch(fetchRequest) as? [ChatMessages]
//
//            return fetchedObjects ?? [ChatMessages]()
//        } catch {
//            print(error)
//            return [ChatMessages]()
//        }
//    }
    
//    func fetchMessage(messageID: String? = nil) -> ChatMessages {
//        let entityName = String(describing: ChatMessages.self)
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
//        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ChatMessages.date, ascending: false)]
//        if messageID != "" {
//            fetchRequest.predicate = NSPredicate(format: "id == %@", messageID ?? "")
//        }
//
//        do {
//            let fetchedObjects = try self.context.fetch(fetchRequest) as? [ChatMessages]
//
//            return fetchedObjects?.first ?? ChatMessages()
//        } catch {
//            print(error)
//            return ChatMessages()
//        }
//    }

    func fetch<T: NSManagedObject>(_ objectType: T.Type) -> [T] {
        let entityName = String(describing: objectType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        do {
            let fetchedObjects = try context.fetch(fetchRequest) as? [T]
            
            return fetchedObjects ?? [T]()
        } catch {
            return [T]()
        }
    }
    
    func fetchProfile<T: NSManagedObject>(_ objectType: T.Type) -> T {
        let entityName = String(describing: objectType)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        do {
            let fetchedObjects = try context.fetch(fetchRequest) as? [T]
            
            return fetchedObjects?.first ?? T()
        } catch {
            return T()
        }
    }
    
    /*
    func getCubeProfile() -> User? {
        if self.fetch(UserProfile.self).count > 0 {
            let user = User()
            let fetchedProfile = self.fetchProfile(UserProfile.self)
            user.id = UInt(fetchedProfile.id)
            user.fullName = fetchedProfile.fullName
            user.phone = fetchedProfile.phoneNumber
            user.login = fetchedProfile.phoneNumber
            
            return user
        } else {
            let user = User()
            user.fullName = "Chatr User"
            user.phone = "(123) 456-7890"
            user.password = "password"
            user.id = UInt(0)
            
            return user
        }
    }
    
    func setCubeProfile(_ profileModel: User) {
        self.delete(self.fetchProfile(UserProfile.self))
        let profile = UserProfile(context: self.context)
        profile.id = Int32(profileModel.id)
        profile.fullName = profileModel.fullName
        profile.phoneNumber = profileModel.phone
        profile.avatar = getCubeProfileImage(usersID: profileModel)
        
//        if let data = profileModel.customData?.data(using: .utf8) {
//            if let customData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : String] {
//                let avatarUID = customData["avatar_uid"]
//                let privateAvatarUrl = Blob.privateUrl(forFileUID: avatarUID ?? "")
//            }
//        }
//        if let data = profileModel.customData?.data(using: .utf8) {
//            profile.profilePicture = data
//        }
        print("the current user22 id is: \(profile.id) and the profile image: \(String(describing: profile.avatar))")
        
        self.save()
    }
    */
    
    func getCubeProfileImage(usersID: ConnectyCube.User) -> String? {
        if let data = usersID.customData?.data(using: .utf8) {
            if let customData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : String] {
                if let avatarUID = customData?["avatar_uid"] {
                    let privateAvatarUrl = Blob.privateUrl(forFileUID: avatarUID)

                    return privateAvatarUrl ?? ""
                }
            }
        } else if let avatarz = usersID.avatar {
            return avatarz
        }
    
        return nil
    }
    
    private func localFilePath(forKey key: String) -> String? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png").absoluteString
    }

    func delete(_ object: NSManagedObject) {
        context.delete(object)
        save()
    }
    
    func deleteAll(object: [NSManagedObject]) {
        object.forEach({ (item) in
            context.delete(item)
        })
        save()
    }
}
