//
//  MessageModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/24/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import IGListKit

final class MessageModel: NSObject, Codable {
    var id: String = ""
    var text: String = ""
    var dialogID: String = ""
    var date: Date = Date()
    var destroyDate: Int = 0
    var senderID: Int = 0
    var bubbleWidth: Int = 0
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    var contactID: Int = 0
    var channelID: String = ""
    var image: String = ""
    var localAttachmentPath: String = ""
    var imageType: String = ""
    var hadDelay: Bool = false
    var isPinned: Bool = false
    var uploadMediaId: String = ""
    var uploadProgress: Double = 0.0
    var placeholderVideoImg: String = ""
    var mediaRatio: Double = 0.0
    var positionRight: Bool = true
    var hasPrevious: Bool = false
    var needsTimestamp: Bool = false
    var isPriorWider: Bool = false
    var isHeader: Bool = false
    var readIDs: [Int] = []
    var deliveredIDs: [Int] = []
    var likedId: [Int] = []
    var dislikedId: [Int] = []

    required override init() {
        super.init()
    }
    
    private enum MessageModelKey: String, CodingKey {
        case id = "id"
        case text = "text"
        case dialogID = "dialogID"
        case date = "date"
        case destroyDate = "destroyDate"
        case senderID = "senderID"
        case readIDs = "readIDs"
        case deliveredIDs = "deliveredIDs"
    }
    
    convenience init(id: String, text: String, dialogID: String, date: Date, destroyDate: Int, senderID: Int, readIDs: [Int], deliveredIDs: [Int]) {
        self.init()

        self.id = id
        self.text = text
        self.dialogID = dialogID
        self.date = date
        self.destroyDate = destroyDate
        self.senderID = senderID
        self.readIDs = readIDs
        self.deliveredIDs = deliveredIDs
    }
    
    convenience required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MessageModelKey.self)
        let id = try container.decode(String.self, forKey: .id)
        let text = try container.decode(String.self, forKey: .text)
        let dialogID = try container.decode(String.self, forKey: .dialogID)
        let date = try container.decode(Date.self, forKey: .date)
        let destroyDate = try container.decode(Int.self, forKey: .destroyDate)
        let senderID = try container.decode(Int.self, forKey: .senderID)
        let readIDs = try container.decode([Int].self, forKey: .readIDs)
        let deliveredIDs = try container.decode([Int].self, forKey: .deliveredIDs)

        self.init(id: id, text: text, dialogID: dialogID, date: date, destroyDate: destroyDate, senderID: senderID, readIDs: readIDs, deliveredIDs: deliveredIDs)
    }
}

extension MessageModel: ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        return id as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else { return true }
        guard let other = object as? MessageModel else { return false }
        return id == other.id && text == other.text && dialogID == other.dialogID && date == other.date && destroyDate == other.destroyDate && senderID == other.senderID && readIDs == other.readIDs && deliveredIDs == other.deliveredIDs
    }
}
