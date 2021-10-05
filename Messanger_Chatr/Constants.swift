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
import MarkdownUI

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
                if !isGroup {
                    if message.readIDs.count == 1 {
                        return "sent"
                    } else {
                        return "read"
                    }
                } else {
                    if message.readIDs.count <= 2 {
                        if message.readIDs.count == 1, message.readIDs.first == UserDefaults.standard.integer(forKey: "currentUserID") {
                            //groups/public auto see the message so there will always be one
                            return "sent"
                        } else {
                            return "read"
                        }
                    } else {
                        return message.readIDs.count.description + " read"
                    }
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

// MARK: Legal Agreement Markdowns

extension Constants {
    static let privacyPolicyMarkdown = Markdown(
                                #"""
                                ## Privacy Policy
                                *Last updated: October 05, 2021*
                                
                                This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.
                                
                                We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.
                                
                                ## Interpretation and Definitions
                                ### Interpretation
                                
                                The words of which the initial letter is capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.
                                
                                ### Definitions
                                
                                For the purposes of this Privacy Policy:
                                
                                * **Account** means a unique account created for You to access our Service or parts of our Service.
                                * **Affiliate** means an entity that controls, is controlled by or is under common control with a party, where "control" means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.
                                * **Application** means the software program provided by the Company downloaded by You on any electronic device, named Chatr
                                * **Company** (referred to as either "the Company", "We", "Us" or "Our" in this Agreement) refers to Chatr Messaging Inc., 42 W 33rd St..
                                * **Country** refers to: New York, United States
                                * **Device** means any device that can access the Service such as a computer, a cellphone or a digital tablet.
                                * **Personal Data** is any information that relates to an identified or identifiable individual.
                                * **Service** refers to the Application.
                                * **Service Provider** means any natural or legal person who processes the data on behalf of the Company. It refers to third-party companies or individuals employed by the Company to facilitate the Service, to provide the Service on behalf of the Company, to perform services related to the Service or to assist the Company in analyzing how the Service is used.
                                * **Third-party Social Media Service** refers to any website or any social network website through which a User can log in or create an account to use the Service.
                                * **Usage Data** refers to data collected automatically, either generated by the use of the Service or from the Service infrastructure itself (for example, the duration of a page visit).
                                * **You** means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.
                                
                                ## Collecting and Using Your Personal Data
                                ### Types of Data Collected
                                #### Personal Data
                                
                                While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to:
                                * Email address
                                * First name and last name
                                * Phone number
                                * Usage Data
                                
                                #### Usage Data
                                
                                Usage Data is collected automatically when using the Service.
                                Usage Data may include information such as Your Device's Internet Protocol address (e.g. IP address), browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, unique device identifiers and other diagnostic data.
                                
                                When You access the Service by or through a mobile device, We may collect certain information automatically, including, but not limited to, the type of mobile device You use, Your mobile device unique ID, the IP address of Your mobile device, Your mobile operating system, the type of mobile Internet browser You use, unique device identifiers and other diagnostic data.
                                
                                We may also collect information that Your browser sends whenever You visit our Service or when You access the Service by or through a mobile device.
                                
                                #### Information from Third-Party Social Media Services
                                
                                The Company allows You to create an account and log in to use the Service through the following Third-party Social Media Services:
                                
                                * Google
                                * Facebook
                                * Twitter
                                
                                If You decide to register through or otherwise grant us access to a Third-Party Social Media Service, We may collect Personal data that is already associated with Your Third-Party Social Media Service's account, such as Your name, Your email address, Your activities or Your contact list associated with that account.
                                
                                You may also have the option of sharing additional information with the Company through Your Third-Party Social Media Service's account. If You choose to provide such information and Personal Data, during registration or otherwise, You are giving the Company permission to use, share, and store it in a manner consistent with this Privacy Policy.
                                
                                #### Information Collected while Using the Application
                                
                                While using Our Application, in order to provide features of Our Application, We may collect, with Your prior permission:
                                * Information regarding your location
                                * Information from your Device's phone book (contacts list)
                                * Pictures and other information from your Device's camera and photo library
                                We use this information to provide features of Our Service, to improve and customize Our Service. The information may be uploaded to the Company's servers and/or a Service Provider's server or it may be simply stored on Your device.
                                
                                You can enable or disable access to this information at any time, through Your Device settings.
                                
                                ### Use of Your Personal Data
                                
                                The Company may use Personal Data for the following purposes:
                                * **To provide and maintain our Service**, including to monitor the usage of our Service.
                                * **To manage Your Account**: to manage Your registration as a user of the Service. The Personal Data You provide can give You access to different functionalities of the Service that are available to You as a registered user.
                                * **For the performance of a contract**: the development, compliance and undertaking of the purchase contract for the products, items or services You have purchased or of any other contract with Us through the Service.
                                * To contact You**: To contact You by email, telephone calls, SMS, or other equivalent forms of electronic communication, such as a mobile application's push notifications regarding updates or informative communications related to the functionalities, products or contracted services, including the security updates, when necessary or reasonable for their implementation.
                                * **To provide You** with news, special offers and general information about other goods, services and events which we offer that are similar to those that you have already purchased or enquired about unless You have opted not to receive such information.
                                * **To manage Your requests**: To attend and manage Your requests to Us.
                                * **For business transfers**: We may use Your information to evaluate or conduct a merger, divestiture, restructuring, reorganization, dissolution, or other sale or transfer of some or all of Our assets, whether as a going concern or as part of bankruptcy, liquidation, or similar proceeding, in which Personal Data held by Us about our Service users is among the assets transferred.
                                * **For other purposes**: We may use Your information for other purposes, such as data analysis, identifying usage trends, determining the effectiveness of our promotional campaigns and to evaluate and improve our Service, products, services, marketing and your experience.
                                
                                We may share Your personal information in the following situations:
                                
                                * **With Service Providers**: We may share Your personal information with Service Providers to monitor and analyze the use of our Service, to contact You.
                                * **For business transfers**: We may share or transfer Your personal information in connection with, or during negotiations of, any merger, sale of Company assets, financing, or acquisition of all or a portion of Our business to another company.
                                * **With Affiliates**: We may share Your information with Our affiliates, in which case we will require those affiliates to honor this Privacy Policy. Affiliates include Our parent company and any other subsidiaries, joint venture partners or other companies that We control or that are under common control with Us.
                                * **With business partners**: We may share Your information with Our business partners to offer You certain products, services or promotions.
                                * **With other users**: when You share personal information or otherwise interact in the public areas with other users, such information may be viewed by all users and may be publicly distributed outside. If You interact with other users or register through a Third-Party Social Media Service, Your contacts on the Third-Party Social Media Service may see Your name, profile, pictures and description of Your activity. Similarly, other users will be able to view descriptions of Your activity, communicate with You and view Your profile.
                                * **With Your consent**: We may disclose Your personal information for any other purpose with Your consent.
                                
                                ### Retention of Your Personal Data
                                
                                The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use Your Personal Data to the extent necessary to comply with our legal obligations (for example, if we are required to retain your data to comply with applicable laws), resolve disputes, and enforce our legal agreements and policies.
                                
                                The Company will also retain Usage Data for internal analysis purposes. Usage Data is generally retained for a shorter period of time, except when this data is used to strengthen the security or to improve the functionality of Our Service, or We are legally obligated to retain this data for longer time periods.
                                
                                ### Transfer of Your Personal Data
                                
                                Your information, including Personal Data, is processed at the Company's operating offices and in any other places where the parties involved in the processing are located. It means that this information may be transferred to — and maintained on — computers located outside of Your state, province, country or other governmental jurisdiction where the data protection laws may differ than those from Your jurisdiction.
                                
                                Your consent to this Privacy Policy followed by Your submission of such information represents Your agreement to that transfer.
                                
                                The Company will take all steps reasonably necessary to ensure that Your data is treated securely and in accordance with this Privacy Policy and no transfer of Your Personal Data will take place to an organization or a country unless there are adequate controls in place including the security of Your data and other personal information.
                                
                                ### Disclosure of Your Personal Data
                                
                                #### Business Transactions
                                
                                If the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred. We will provide notice before Your Personal Data is transferred and becomes subject to a different Privacy Policy.
                                
                                #### Law enforcement
                                
                                Under certain circumstances, the Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities (e.g. a court or a government agency).
                                
                                #### Other legal requirements
                                
                                The Company may disclose Your Personal Data in the good faith belief that such action is necessary to:
                                
                                * Comply with a legal obligation
                                * Protect and defend the rights or property of the Company
                                * Prevent or investigate possible wrongdoing in connection with the Service
                                * Protect the personal safety of Users of the Service or the public
                                * Protect against legal liability
                                
                                ### Security of Your Personal Data
                                
                                The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While We strive to use commercially acceptable means to protect Your Personal Data, We cannot guarantee its absolute security.
                                
                                ## Children's Privacy
                                
                                Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us. If We become aware that We have collected Personal Data from anyone under the age of 13 without verification of parental consent, We take steps to remove that information from Our servers.
                                
                                If We need to rely on consent as a legal basis for processing Your information and Your country requires consent from a parent, We may require Your parent's consent before We collect and use that information.
                                
                                ## Links to Other Websites
                                
                                Our Service may contain links to other websites that are not operated by Us. If You click on a third party link, You will be directed to that third party's site. We strongly advise You to review the Privacy Policy of every site You visit.
                                
                                We have no control over and assume no responsibility for the content, privacy policies or practices of any third party sites or services.
                                
                                ## Changes to this Privacy Policy
                                
                                We may update Our Privacy Policy from time to time. We will notify You of any changes by posting the new Privacy Policy on this page.
                                
                                We will let You know via email and/or a prominent notice on Our Service, prior to the change becoming effective and update the "Last updated" date at the top of this Privacy Policy.
                                
                                You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.
                                
                                ## Contact Us
                                
                                If you have any questions about this Privacy Policy, You can contact us:
                                * By visiting this page on our website: [www.chatr-messaging.com/support](https://www.chatr-messaging.com/support)
                                
                                """#
    )
    
    static let eulaMarkdown = Markdown(
                                #"""
                                
                                ## End-User License Agreement (EULA)
                                *Last updated: October 05, 2021*
                                
                                This End-User License Agreement ('EULA') is a legal agreement between you and Chatr
                                
                                This EULA agreement governs your acquisition and use of our Chatr software ('Software') directly from Chatr or indirectly through a Chatr authorized reseller or distributor (a 'Reseller').
                                
                                Please read this EULA agreement carefully before completing the installation process and using the Chatr software. It provides a license to use the Chatr software and contains warranty information and liability disclaimers.
                                
                                If you register for a free trial of the Chatr software, this EULA agreement will also govern that trial. By clicking 'accept' or installing and/or using the Chatr software, you are confirming your acceptance of the Software and agreeing to become bound by the terms of this EULA agreement.
                                
                                If you are entering into this EULA agreement on behalf of a company or other legal entity, you represent that you have the authority to bind such entity and its affiliates to these terms and conditions. If you do not have such authority or if you do not agree with the terms and conditions of this EULA agreement, do not install or use the Software, and you must not accept this EULA agreement.
                                
                                This EULA agreement shall apply only to the Software supplied by Chatr herewith regardless of whether other software is referred to or described herein. The terms also apply to any Chatr updates, supplements, Internet-based services, and support services for the Software, unless other terms accompany those items on delivery. If so, those terms apply. This EULA was created by EULA Template for Chatr.
                                
                                ### License Grant
                                
                                Chatr hereby grants you a personal, non-transferable, non-exclusive licence to use the Chatr software on your devices in accordance with the terms of this EULA agreement.
                                
                                You are permitted to load the Chatr software (for example a PC, laptop, mobile or tablet) under your control. You are responsible for ensuring your device meets the minimum requirements of the Chatr software.
                                
                                ### You are not permitted to:
                                
                                Edit, alter, modify, adapt, translate or otherwise change the whole or any part of the Software nor permit the whole or any part of the Software to be combined with or become incorporated in any other software, nor decompile, disassemble or reverse engineer the Software or attempt to do any such things
                                
                                * Reproduce, copy, distribute, resell or otherwise use the Software for any commercial purpose
                                * Allow any third party to use the Software on behalf of or for the benefit of any third party
                                * Use the Software in any way which breaches any applicable local, national or international law
                                * Use the Software for any purpose that Chatr considers is a breach of this EULA agreement
                                
                                ### Intellectual Property and Ownership
                                
                                Chatr shall at all times retain ownership of the Software as originally downloaded by you and all subsequent downloads of the Software by you. The Software (and the copyright, and other intellectual property rights of whatever nature in the Software, including any modifications made thereto) are and shall remain the property of Chatr.
                                
                                Chatr reserves the right to grant licences to use the Software to third parties.
                                
                                ### Termination
                                
                                This EULA agreement is effective from the date you first use the Software and shall continue until terminated. You may terminate it at any time upon written notice to Chatr.
                                
                                It will also terminate immediately if you fail to comply with any term of this EULA agreement. Upon such termination, the licenses granted by this EULA agreement will immediately terminate and you agree to stop all access and use of the Software. The provisions that by their nature continue and survive will survive any termination of this EULA agreement.
                                
                                ### Governing Law
                                
                                This EULA agreement, and any dispute arising out of or in connection with this EULA agreement, shall be governed by and construed in accordance with the laws of us.
                                
                                ## Contact Us
                                
                                If you have any questions about this Privacy Policy, You can contact us:
                                * By visiting this page on our website: [www.chatr-messaging.com/support](https://www.chatr-messaging.com/support)
                                
                                """#
    )

    static let termsOfServiceMarkdown = Markdown(
                                #"""
                                ## Terms of Service
                                *Last updated: October 05, 2021*
                                
                                Please read these Terms and Conditions ('Terms', 'Terms and Conditions') carefully before using the Chatr mobile application (the 'Service') operated by Chatr ('us', 'we', or 'our').
                                
                                Your access to and use of the Service is conditioned upon your acceptance of and compliance with these Terms. These Terms apply to all visitors, users and others who wish to access or use the Service.
                                
                                ### Communications
                                
                                By creating an Account on our service, you agree to subscribe to newsletters, marketing or promotional materials and other information we may send. However, you may opt out of receiving any, or all, of these communications from us by following the unsubscribe link or instructions provided in any email we send.
                                
                                ### Content
                                
                                Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material ('Content'). You are responsible for the Content that you post on or through the Service, including its legality, reliability, and appropriateness.
                                
                                By posting Content on or through the Service, You represent and warrant that: (i) the Content is yours (you own it) and/or you have the right to use it and the right to grant us the rights and license as provided in these Terms, and (ii) that the posting of your Content on or through the Service does not violate the privacy rights, publicity rights, copyrights, contract rights or any other rights of any person or entity. We reserve the right to terminate the account of anyone found to be infringing on a copyright.
                                
                                You retain any and all of your rights to any Content you submit, post or display on or through the Service and you are responsible for protecting those rights. We take no responsibility and assume no liability for Content you or any third party posts on or through the Service. However, by posting Content using the Service you grant us the right and license to use, modify, perform, display, reproduce, and distribute such Content on and through the Service.
                                
                                Chatr has the right but not the obligation to monitor and edit all Content provided by users.
                                
                                In addition, Content found on or through this Service are the property of Chatr or used with permission. You may not distribute, modify, transmit, reuse, download, repost, copy, or use said Content, whether in whole or in part, for commercial purposes or for personal gain, without express advance written permission from us.
                                
                                ### Accounts
                                
                                When you create an account with us, you guarantee that you are above the age of 13, and that the information you provide us is accurate, complete, and current at all times. Inaccurate, incomplete, or obsolete information may result in the immediate termination of your account on the Service.
                                
                                You are responsible for maintaining the confidentiality of your account and password, including but not limited to the restriction of access to your computer and/or account. You agree to accept responsibility for any and all activities or actions that occur under your account and/or password, whether your password is with our Service or a third-party service. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.
                                
                                You are responsible for maintaining the confidentiality of your account and password, including but not limited to the restriction of access to your computer and/or account. You agree to accept responsibility for any and all activities or actions that occur under your account and/or password, whether your password is with our Service or a third-party service. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.
                                
                                You may not use as a username the name of another person or entity or that is not lawfully available for use, a name or trademark that is subject to any rights of another person or entity other than you, without appropriate authorization. You may not use as a username any name that is offensive, vulgar or obscene.
                                
                                ### Links To Other Web Sites
                                
                                Our Service may contain links to third party web sites or services that are not owned or controlled by Chatr.
                                
                                Chatr has no control over, and assumes no responsibility for the content, privacy policies, or practices of any third party web sites or services. We do not warrant the offerings of any of these entities/individuals or their websites.
                                
                                You acknowledge and agree that Chatr shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with use of or reliance on any such content, goods or services available on or through any such third party web sites or services.
                                
                                We strongly advise you to read the terms and conditions and privacy policies of any third party web sites or services that you visit.
                                
                                ### Termination
                                
                                We may terminate or suspend your account and bar access to the Service immediately, without prior notice or liability, under our sole discretion, for any reason whatsoever and without limitation, including but not limited to a breach of the Terms.
                                
                                If you wish to terminate your account, you may simply discontinue using the Service.
                                
                                All provisions of the Terms which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity and limitations of liability.
                                
                                ### Indemnification
                                
                                You agree to defend, indemnify and hold harmless Chatr and its licensee and licensors, and their employees, contractors, agents, officers and directors, from and against any and all claims, damages, obligations, losses, liabilities, costs or debt, and expenses (including but not limited to attorney's fees), resulting from or arising out of a) your use and access of the Service, by you or any person using your account and password; b) a breach of these Terms, or c) Content posted on the Service.
                                
                                ### Limitation Of Liability
                                
                                In no event shall Chatr, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access to or use of or inability to access or use the Service; (ii) any conduct or content of any third party on the Service; (iii) any content obtained from the Service; and (iv) unauthorized access, use or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence) or any other legal theory, whether or not we have been informed of the possibility of such damage, and even if a remedy set forth herein is found to have failed of its essential purpose.
                                
                                ### Disclaimer
                                
                                Your use of the Service is at your sole risk. The Service is provided on an 'AS IS' and 'AS AVAILABLE' basis. The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance.
                                
                                Chatr its subsidiaries, affiliates, and its licensors do not warrant that a) the Service will function uninterrupted, secure or available at any particular time or location; b) any errors or defects will be corrected; c) the Service is free of viruses or other harmful components; or d) the results of using the Service will meet your requirements.
                                
                                ### Exclusions
                                
                                Some jurisdictions do not allow the exclusion of certain warranties or the exclusion or limitation of liability for consequential or incidental damages, so the limitations above may not apply to you.
                                
                                ### Governing Law
                                
                                These Terms shall be governed and construed in accordance with the laws of New York, United States, without regard to its conflict of law provisions.
                                
                                Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights. If any provision of these Terms is held to be invalid or unenforceable by a court, the remaining provisions of these Terms will remain in effect. These Terms constitute the entire agreement between us regarding our Service, and supersede and replace any prior agreements we might have had between us regarding the Service.
                                
                                ### Changes
                                
                                We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will provide at least 15 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.
                                
                                By continuing to access or use our Service after any revisions become effective, you agree to be bound by the revised terms. If you do not agree to the new terms, you are no longer authorized to use the Service.
                                
                                ## Contact Us
                                
                                If you have any questions about this Privacy Policy, You can contact us:
                                * By visiting this page on our website: [www.chatr-messaging.com/support](https://www.chatr-messaging.com/support)
                                
                                """#
    )
}
