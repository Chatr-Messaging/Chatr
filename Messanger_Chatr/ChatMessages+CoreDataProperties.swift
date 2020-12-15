//
//  ChatMessages+CoreDataProperties.swift
//  
//
//  Created by Brandon Shaw on 8/1/20.
//
//

import Foundation
import CoreData


extension ChatMessages {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessages> {
        return NSFetchRequest<ChatMessages>(entityName: "ChatMessages")
    }

    @NSManaged public var date: Date?
    @NSManaged public var dialogID: String?
    @NSManaged public var id: String?
    @NSManaged public var image: String?
    @NSManaged public var senderID: Int32
    @NSManaged public var text: String?

}
