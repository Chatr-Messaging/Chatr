//
//  Constants.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/3/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import FirebaseAuth
import RealmSwift

struct Constants {
    
    // MARK: - Basics
    static let btnSize = CGFloat(46)
    static let smallBtnSize = CGFloat(34)
    static let microBtnSize = CGFloat(18)
    static let menuBtnSize = CGFloat(48)
    static let quickSnapBtnSize = CGFloat(52)
    static let avitarSize = CGFloat(55)
    static let smallAvitarSize = CGFloat(30)
    static let maxNumberGroupOccu = 30
    static let maxNumberEarlyAdopters = 1000

    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let edges = UIApplication.shared.windows.first?.safeAreaInsets

    static let FirebaseProjectID = "chatr-b849e"
    static let FirebaseStoragePath = "gs://chatr-b849e.appspot.com"
    static let firebaseCurrentUser = Auth.auth().currentUser

    static let uploadcarePublicKey = "58ae497bf7dad52e4a35"
    static let uploadcareSecretKey = "709171e4d5148528c64f"
    static let uploadcareBaseUrl = "https://ucarecdn.com/"
    static let uploadcareBaseVideoUrl = "https://api.uploadcare.com/files/"
    static let uploadcareStandardTransform = "/-/preview/-/quality/smart_retina/-/format/auto/"
    static let uploadcare45x45Transform = "/-/resize/45x45/-/stretch/off/"
    static let uploadcare50x50Transform = "/-/resize/50x50/-/stretch/off/"
    static let uploadcare55x55Transform = "/-/resize/55x55/-/stretch/off/"
    static let uploadcareStandardVideoTransform = "/-/video/-/size/\(Constants.screenWidth * 0.65)x/-/quality/normal/"

    static let projectVersion = "1.0.0"
    static let appStoreLink = "https://apple.co/3kZBVtL"

    static let allowedHosts = [".com", ".me", ".org", ".io", ".edu", ".net", ".app", ".web", ".co", ".uk", ".us", ".gov", ".biz", ".info", ",jobs", ".ly", ".name", ".xyz"]

    let connectyCurrentUserID = UserDefaults.standard.integer(forKey: "currentUserID")

    static var userHasiOS14 : Bool {
        get { if #available(iOS 14.0, *) { return true } else { return false } }
    }
    
    static let termsOfService = "Chatr's Terms and Conditions. \nLast updated: August 27, 2020 \n\nPlease read these Terms and Conditions ('Terms', 'Terms and Conditions') carefully before using the Chatr mobile application (the 'Service') operated by Chatr ('us', 'we', or 'our'). \nYour access to and use of the Service is conditioned upon your acceptance of and compliance with these Terms. These Terms apply to all visitors, users and others who wish to access or use the Service. \n\n Communications\n By creating an Account on our service, you agree to subscribe to newsletters, marketing or promotional materials and other information we may send. However, you may opt out of receiving any, or all, of these communications from us by following the unsubscribe link or instructions provided in any email we send. \nContent \n\nOur Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ('Content'). You are responsible for the Content that you post on or through the Service, including its legality, reliability, and appropriateness. \nBy posting Content on or through the Service, You represent and warrant that: (i) the Content is yours (you own it) and/or you have the right to use it and the right to grant us the rights and license as provided in these Terms, and (ii) that the posting of your Content on or through the Service does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person or entity. We reserve the right to terminate the account of anyone found to be infringing on a copyright. \nYou retain any and all of your rights to any Content you submit, post or display on or through the Service and you are responsible for protecting those rights. We take no responsibility and assume no liability for Content you or any third party posts on or through the Service. However, by posting Content using the Service you grant us the right and license to use, modify, perform, display, reproduce, and distribute such Content on and through the Service.\nChatr has the right but not the obligation to monitor and edit all Content provided by users. \nIn addition, Content found on or through this Service are the property of Chatr or used with permission. You may not distribute, modify, transmit, reuse, download, repost, copy, or use said Content, whether in whole or in part, for commercial purposes or for personal gain, without express advance written permission from us.\n\n Accounts\n When you create an account with us, you guarantee that you are above the age of 13, and that the information you provide us is accurate, complete, and current at all times. Inaccurate, incomplete, or obsolete information may result in the immediate termination of your account on the Service.\nYou are responsible for maintaining the confidentiality of your account and password, including but not limited to the restriction of access to your computer and/or account. You agree to accept responsibility for any and all activities or actions that occur under your account and/or password, whether your password is with our Service or a third-party service. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account. \nYou are responsible for maintaining the confidentiality of your account and password, including but not limited to the restriction of access to your computer and/or account. You agree to accept responsibility for any and all activities or actions that occur under your account and/or password, whether your password is with our Service or a third-party service. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account. \nYou may not use as a username the name of another person or entity or that is not lawfully available for use, a name or trademark that is subject to any rights of another person or entity other than you, without appropriate authorization. You may not use as a username any name that is offensive, vulgar or obscene. \n\n Links To Other Web Sites \nOur Service may contain links to third party web sites or services that are not owned or controlled by Chatr. \nChatr has no control over, and assumes no responsibility for the content, privacy policies, or practices of any third party web sites or services. We do not warrant the offerings of any of these entities/individuals or their websites. \nYou acknowledge and agree that Chatr shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with use of or reliance on any such content, goods or services available on or through any such third party web sites or services. \nWe strongly advise you to read the terms and conditions and privacy policies of any third party web sites or services that you visit. \n\n Termination \nWe may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms. \nIf you wish to terminate your account, you may simply discontinue using the Service. \nAll provisions of the Terms which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity and limitations of liability. \n\n Indemnification \nYou agree to defend, indemnify and hold harmless Chatr and its licensee and licensors, and their employees, contractors, agents, officers and directors, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees), resulting from or arising out of a) your use and access of the Service, by you or any person using your account and password; b) a breach of these Terms, or c) Content posted on the Service. \n\n Limitation Of Liability \nIn no event shall Chatr, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access to or use of or inability to access or use the Service; (ii) any conduct or content of any third party on the Service; (iii) any content obtained from the Service; and (iv) unauthorized access, use or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence) or any other legal theory, whether or not we have been informed of the possibility of such damage, and even if a remedy set forth herein is found to have failed of its essential purpose. \n\n Disclaimer \n Your use of the Service is at your sole risk. The Service is provided on an 'AS IS' and 'AS AVAILABLE' basis. The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance. \nChatr its subsidiaries, affiliates, and its licensors do not warrant that a) the Service will function uninterrupted, secure or available at any particular time or location; b) any errors or defects will be corrected; c) the Service is free of viruses or other harmful components; or d) the results of using the Service will meet your requirements. \n\nExclusions \n Some jurisdictions do not allow the exclusion of certain warranties or the exclusion or limitation of liability for consequential or incidental damages, so the limitations above may not apply to you. \n\nGoverning Law \nThese Terms shall be governed and construed in accordance with the laws of New York, United States, without regard to its conflict of law provisions. \n Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect. These Terms constitute the entire agreement between us regarding our Service, and supersede and replace any prior agreements we might have had between us regarding the Service. \n\nChanges \nWe reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will provide at least 15 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion. \nBy continuing to access or use our Service after any revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, you are no longer authorized to use the Service. \n\nContact Us \nIf you have any questions about these Terms, please contact us."
    
    static let EULAagreement = "End-User License Agreement (EULA) of Chatr \n\nThis End-User License Agreement ('EULA') is a legal agreement between you and Chatr \nThis EULA agreement governs your acquisition and use of our Chatr software ('Software') directly from Chatr or indirectly through a Chatr authorized reseller or distributor (a 'Reseller').\nPlease read this EULA agreement carefully before completing the installation process and using the Chatr software. It provides a license to use the Chatr software and contains warranty information and liability disclaimers. \nIf you register for a free trial of the Chatr software, this EULA agreement will also govern that trial. By clicking 'accept' or installing and/or using the Chatr software, you are confirming your acceptance of the Software and agreeing to become bound by the terms of this EULA agreement.\nIf you are entering into this EULA agreement on behalf of a company or other legal entity, you represent that you have the authority to bind such entity and its affiliates to these terms and conditions. If you do not have such authority or if you do not agree with the terms and conditions of this EULA agreement, do not install or use the Software, and you must not accept this EULA agreement. \nThis EULA agreement shall apply only to the Software supplied by Chatr herewith regardless of whether other software is referred to or described herein. The terms also apply to any Chatr updates, supplements, Internet-based services, and support services for the Software, unless other terms accompany those items on delivery. If so, those terms apply. This EULA was created by EULA Template for Chatr. \n\n License Grant \nChatr hereby grants you a personal, non-transferable, non-exclusive licence to use the Chatr software on your devices in accordance with the terms of this EULA agreement. \nYou are permitted to load the Chatr software (for example a PC, laptop, mobile or tablet) under your control. You are responsible for ensuring your device meets the minimum requirements of the Chatr software. \nYou are not permitted to: \nEdit, alter, modify, adapt, translate or otherwise change the whole or any part of the Software nor permit the whole or any part of the Software to be combined with or become incorporated in any other software, nor decompile, disassemble or reverse engineer the Software or attempt to do any such things \nReproduce, copy, distribute, resell or otherwise use the Software for any commercial purpose \nAllow any third party to use the Software on behalf of or for the benefit of any third party \nUse the Software in any way which breaches any applicable local, national or international law \nUse the Software for any purpose that Chatr considers is a breach of this EULA agreement \n\nIntellectual Property and Ownership \nChatr shall at all times retain ownership of the Software as originally downloaded by you and all subsequent downloads of the Software by you. The Software (and the copyright, and other intellectual property rights of whatever nature in the Software, including any modifications made thereto) are and shall remain the property of Chatr. \nChatr reserves the right to grant licences to use the Software to third parties. \n\nTermination \nThis EULA agreement is effective from the date you first use the Software and shall continue until terminated. You may terminate it at any time upon written notice to Chatr. \nIt will also terminate immediately if you fail to comply with any term of this EULA agreement. Upon such termination, the licenses granted by this EULA agreement will immediately terminate and you agree to stop all access and use of the Software. The provisions that by their nature continue and survive will survive any termination of this EULA agreement. \n\nGoverning Law \nThis EULA agreement, and any dispute arising out of or in connection with this EULA agreement, shall be governed by and construed in accordance with the laws of us."
    
    // MARK: - Colors
    static let blueGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    static let messageBlueGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 97 / 255, green: 195 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 49 / 255, green: 143 / 255, blue: 255 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    static let purpleGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 88 / 255, green: 218 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 148 / 255, green: 109 / 255, blue: 245 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    static let snapPurpleGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 224 / 255, green: 155 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 175 / 255, green: 82 / 255, blue: 254 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    static let grayGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 218 / 255, green: 218 / 255, blue: 218 / 255, opacity: 1.0), Color(.sRGB, red: 166 / 255, green: 166 / 255, blue: 166 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    static let baseBlue = Color(red: 69/255, green: 155/255, blue: 255/255, opacity: 1.0)
}

extension Date {
    func getElapsedInterval(lastMsg: String) -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? "\(year)" + " " + "yr" :
                "\(year)" + " " + "yrs"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "\(month)" + " " + "mth" :
                "\(month)" + " " + "mths"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "\(day)" + " " + "day" :
                "\(day)" + " " + "days"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hr" :
                "\(hour)" + " " + "hrs"
        } else if let min = interval.minute, min > 0 {
            return min == 1 ? "\(min)" + " " + "min" :
                "\(min)" + " " + "mins"
        } else if let sec = interval.second, sec > 0 {
            return sec == 1 ? "\(sec)" + " " + "sec" :
                "\(sec)" + " " + "sec"
        } else {
            return lastMsg
        }
    }
    
    func getFullElapsedInterval() -> String {
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return year == 1 ? "\(year)" + " " + "year ago" :
                "\(year)" + " " + "years ago"
        } else if let month = interval.month, month > 0 {
            return month == 1 ? "\(month)" + " " + "month ago" :
                "\(month)" + " " + "months ago"
        } else if let day = interval.day, day > 0 {
            return day == 1 ? "\(day)" + " " + "day ago" :
                "\(day)" + " " + "days ago"
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hour ago" :
                "\(hour)" + " " + "hours ago"
        } else if let min = interval.minute, min > 0 {
            return min == 1 ? "\(min)" + " " + "minute ago" :
                "\(min)" + " " + "minutes ago"
        } else if let sec = interval.second, sec > 0 {
            return sec == 1 ? "\(sec)" + " " + "second ago" :
                "\(sec)" + " " + "seconds ago"
        } else {
            return "just now"
        }
    }
}

extension String {
    func toDate(withFormat format: String = "HH:mm") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        guard let dateObjectWithTime = dateFormatter.date(from: self) else { return nil }
        
        let gregorian = Calendar(identifier: .gregorian)
        let now = Date()
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        var dateComponents = gregorian.dateComponents(components, from: now)

        let calendar = Calendar.current
        dateComponents.hour = calendar.component(.hour, from: dateObjectWithTime)
        dateComponents.minute = calendar.component(.minute, from: dateObjectWithTime)
        dateComponents.second = 0

        return gregorian.date(from: dateComponents)
    }
    
    var containsEmoji: Bool {
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x2600...0x26FF,   // Misc symbols
                 0x2700...0x27BF,   // Dingbats
                 0xFE00...0xFE0F:   // Variation Selectors
                return true
            default:
                continue
            }
        }
        return false
    }
    
    func emojiToImage(text: String) -> [UIImage?] {
        let size = CGSize(width: 30, height: 30)
        var imag: [UIImage] = []
        
        for chari in text {
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor.clear.set()
            let rect = CGRect(origin: CGPoint(), size: size)
            UIRectFill(rect)
            ("\(chari)" as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 26)])
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return [] }
            UIGraphicsEndImageContext()
            imag.append(image)
        }
        return imag
    }
    
    func firstLeters(text: String) -> String {
        if !text.isEmpty {
            let stringInputArr = text.components(separatedBy: " ")
            var stringNeed: String = ""

            for string in stringInputArr {
                if stringNeed.count >= 3 {
                    return stringNeed
                } else {
                    if let firstLetter = string.first {
                        stringNeed = stringNeed + String(firstLetter)
                    }
                }
            }
            return stringNeed
        } else {
            return ""
        }
    }
    
    func messageStatusText(message: MessageStruct, positionRight: Bool, isGroup: Bool, fullName: String?) -> String {
        if positionRight == true {
            //if is your message
            switch message.messageState {
            case .sending:
                return ""
            case .delivered:
                return "sent"
            case .read:
                if message.readIDs.count <= 2 {
                    if message.readIDs.count == 1 && message.readIDs.first == UserDefaults.standard.integer(forKey: "currentUserID") {
                        //groups/public auto see the message so there will always be one
                        return "sent"
                    } else {
                        return "read"
                    }
                } else {
                    return message.readIDs.count.description + " read"
                }
            case .editied:
                return "edited"

            case .deleted:
                return "deleted"

            case .error:
                return "error"

            case .isTyping:
                return "typing"

            case .removedTyping:
                return ""

            case .sent:
                return "sent"

            }
        } else {
            guard let name = fullName?.byWords.first?.description, isGroup else { return "" }
            
            return name //.byWords.first?.description ?? fullName
        }
    }
    
    func detailMessageStatusText(message: MessageStruct, date: String) -> String {
        
        switch message.messageState {
        case .read:
            guard message.readIDs.count >= 2 else {
                return message.readIDs.count.description + " read"
            }

            return date + "   " + message.readIDs.count.description + " read"
            
        case .editied:
            guard message.readIDs.count >= 2 else {
                return date + "   editied"
            }

            return date + "   editied   " + message.readIDs.count.description + " read"

        default:
            return date

        }
        
    }
}

extension Realm {
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}

extension UIDevice {
    var hasNotch: Bool {
        let keyWindow = UIApplication.shared.connectedScenes
            .lazy
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first { $0.isKeyWindow }
        let bottom = keyWindow?.safeAreaInsets.bottom ?? 0
        return bottom > 0
    }
}
