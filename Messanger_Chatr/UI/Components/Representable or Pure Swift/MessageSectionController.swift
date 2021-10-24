//
//  MessageSectionController.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/24/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import IGListKit

final class MessageSectionController: ListSectionController {
    private var message: MessageModel?
    private var top: CGFloat = 0.0
    private var bottom: CGFloat = 0.0
    private let textFont = UIFont.systemFont(ofSize: 20, weight: .regular)
    override init() {
        super.init()
    }

    override func didUpdate(to object: Any) {
        guard let model = object as? MessageModel else { return }
        self.message = model
    }
}

extension MessageSectionController {
    override func numberOfItems() -> Int {
        return message == nil ? 0 : 1
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext, let message = self.message else { return CGSize.zero }
        let width = context.containerSize.width
        let estimatedFrame = self.calcEstimatedFrame(text: message.text, width: width)
        return CGSize(width: width, height: estimatedFrame.height)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cellClass = MessageCollectionViewCell.self
        guard let context = collectionContext,
              let cell = context.dequeueReusableCell(of: cellClass, for: self, at: index) as? MessageCollectionViewCell,
              let message = self.message else {
                  assertionFailure("collection context is nil");
                  return UICollectionViewCell()
              }
        let estimatedFrame = self.calcEstimatedFrame(text: message.text, width: context.containerSize.width)
        
        if message.isUser {
            let width = context.containerSize.width
            cell.child.view.frame = CGRect(x: width - estimatedFrame.width - 20, y: 0, width: estimatedFrame.width + 8, height: estimatedFrame.height)
            cell.container.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner]
        } else {
            cell.child.view.frame = CGRect(x: 10, y: 0, width: estimatedFrame.width + 10, height: estimatedFrame.height)
            cell.container.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        cell.child.rootView.text = message.text
        cell.child.rootView.isMine = message.isUser

        return cell
    }
}


extension MessageSectionController {
    func calcEstimatedFrame(text: String, width: CGFloat) -> CGSize {
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let cellSize = CGSize(width: width/2, height: 1000)
        let estimatedFrame = NSString(string: text).boundingRect(with:cellSize, options: options, attributes: [NSAttributedString.Key.font: self.textFont], context: nil)

        return CGSize(width: estimatedFrame.width + 16, height: estimatedFrame.height + 16)
    }
}

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.height
    }
    
    func boundingRect(with size: CGSize, attributes: [NSAttributedString.Key: Any]) -> CGRect {
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let rect = self.boundingRect(with: size, options: options, attributes: attributes, context: nil)

        return rect
    }
}

extension UIFont {
    func sizeOfString (string: String, constrainedToWidth width: Double) -> CGSize {
        return NSString(string: string).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: self], context: nil).size
    }

    func sizeOfStringFaster (string: String, constrainedToWidth width: Double) -> CGSize {
        let attributes = [NSAttributedString.Key.font:self,]
        let attString = NSAttributedString(string: string,attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)

        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    }
}
