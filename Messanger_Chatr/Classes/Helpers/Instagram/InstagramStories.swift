//
//  InstagramStories.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/9/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit

class InstagramStories: NSObject {
    
    private let urlScheme = URL(string: "instagram-stories://share")!
    
    enum optionsKey: String {
        case StickerImage = "com.instagram.sharedSticker.stickerImage"
        case bgImage = "com.instagram.sharedSticker.backgroundImage"
        case bgVideo = "com.instagram.sharedSticker.backgroundVideo"
        case bgTopColor = "com.instagram.sharedSticker.backgroundTopColor"
        case bgBottomColor = "com.instagram.sharedSticker.backgroundBottomColor"
        case contentUrl = "com.instagram.sharedSticker.contentURL"
    }
    
    //MARK: Post background image
    func post(bgImage: UIImage, stickerImage: UIImage? = nil, contentURL: String? = nil) -> Bool {
        var items:[[String : Any]] = [[:]]
        //Background Image
        let bgData = bgImage.pngData()!
        items[0].updateValue(bgData, forKey: optionsKey.bgImage.rawValue)
        //Sticker Image
        if stickerImage != nil {
            let stickerData = stickerImage!.pngData()!
            items[0].updateValue(stickerData, forKey: optionsKey.StickerImage.rawValue)
        }
        //Content URL
        if contentURL != nil {
            items[0].updateValue(contentURL as Any, forKey: optionsKey.contentUrl.rawValue)
        }
        let isPosted = post(items)
        return isPosted
    }
    
    //MARK: Post background video
    func post(bgVideoUrl: URL, stickerImage: UIImage? = nil, contentURL: String? = nil) -> Bool {
        var items: [[String : Any]] = [[:]]
        //Background Video
        var videoData: Data?
        
        do {
            try videoData = Data(contentsOf: bgVideoUrl)
        } catch {
            return false
        }
        items[0].updateValue(videoData as Any, forKey: optionsKey.bgVideo.rawValue)
        
        //Sticker Image
        if stickerImage != nil {
            let stickerData = stickerImage!.pngData()!
            items[0].updateValue(stickerData, forKey: optionsKey.StickerImage.rawValue)
        }

        //Content URL
        if contentURL != nil {
            items[0].updateValue(contentURL as Any, forKey: optionsKey.contentUrl.rawValue)
        }

        let isPosted = post(items)
        
        return isPosted
    }
    
    //MARK: Post a sticker
    func post(stickerImage: UIImage, bgTop: String = "#000000", bgBottom: String = "#000000", contentURL: String? = nil) -> Bool {
        var items: [[String : Any]] = [[:]]

        //Sticker Image
        let stickerData = stickerImage.pngData()!
        items[0].updateValue(stickerData, forKey: optionsKey.StickerImage.rawValue)

        //Background Color
        items[0].updateValue(bgTop, forKey: optionsKey.bgTopColor.rawValue)
        items[0].updateValue(bgBottom, forKey: optionsKey.bgBottomColor.rawValue)

        //Content URL
        if contentURL != nil {
            items[0].updateValue(contentURL as Any, forKey: optionsKey.contentUrl.rawValue)
        }

        let isPosted = post(items)
        
        return isPosted
    }
    
    //MARK: Post to Instagram Stories
    private func post(_ items:[[String : Any]]) -> Bool{
        guard UIApplication.shared.canOpenURL(urlScheme) else {            
            return false
        }

        let options: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(60 * 5)]
        UIPasteboard.general.setItems(items, options: options)
        UIApplication.shared.open(urlScheme)

        return true
    }
    
}

// Singleton☝️
extension InstagramStories {
    class var Shared : InstagramStories {
        struct Static { static let instance : InstagramStories = InstagramStories() }

        return Static.instance
    }
}
