//
//  UserDialogs+CoreDataProperties.swift
//  
//
//  Created by Brandon Shaw on 8/1/20.
//
//

import Foundation
import CoreData


extension UserDialogs {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserDialogs> {
        return NSFetchRequest<UserDialogs>(entityName: "UserDialogs")
    }

    @NSManaged public var date: Date?
    @NSManaged public var from: Int32
    @NSManaged public var id: String?
    @NSManaged public var image: String?
    @NSManaged public var isOpen: Bool
    @NSManaged public var isPrivate: Bool
    @NSManaged public var lastMessage: String?
    @NSManaged public var name: String?
    @NSManaged public var notifications: Int32
    @NSManaged public var occupentsID: NSObject?
    @NSManaged public var typedText: String?

}
