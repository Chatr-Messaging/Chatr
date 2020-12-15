//
//  UserProfile+CoreDataProperties.swift
//  
//
//  Created by Brandon Shaw on 8/1/20.
//
//

import Foundation
import CoreData


extension UserProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var avatar: String?
    @NSManaged public var fullName: String?
    @NSManaged public var id: Int32
    @NSManaged public var lastOnline: Date?
    @NSManaged public var password: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var profilePicture: Data?

}
