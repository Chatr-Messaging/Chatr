//
//  Auth.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/15/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseDatabase
import ConnectyCube
import RealmSwift
import Photos
import CoreLocation
import Contacts
import UserNotifications
import Purchases

enum AuthState {
    case undefined, signedOut, signedIn, error
}

enum PhoneNumberStatus {
    case undefined, success, loading, error
}

enum messageKind: String {
    case text, image, gif, contact, attachment, location, removed
}

enum messageStatus: String {
    case delivered, sent, sending, read, isTyping, editied, deleted, error
}

enum messagePosition {
    case left, right, unknown
}

enum visitUserState {
    case unknown, fromContacts, fromSearch, fromRequests, fromDynamicLink
}

enum visitContactRelationship {
    case unknown, contact, notContact, pendingRequest, pendingRequestForYou
}

enum visitDialogRelationship {
    case unknown, subscribed, notSubscribed
}

enum StorageType {
    case userDefaults
    case fileSystem
}

enum PremiumSubscriptionStatus {
    case subscribed, notSubscribed
}

class AuthModel: NSObject, ObservableObject {
    @Published var attempted: Bool = false
    @Published var preventDismissal: Bool = false
        
    @Published var isUserAuthenticated: AuthState = .undefined
    @Published var verifyPhoneNumberStatus: PhoneNumberStatus = .undefined
    @Published var verifyCodeStatus: PhoneNumberStatus = .undefined
    @Published var haveUserFullName = false
    @Published var haveUserProfileImg = false
    @Published var verifyCodeStatusKeyboard = false
    @Published var verifyPhoneStatusKeyboard = false
    
    @Published var notificationPermission = false
    @Published var photoPermission = false
    @Published var locationPermission = false
    @Published var contactsPermission = false
    @Published var cameraPermission = false
    @Published var isLoacalAuth = false
    @Published var visitContactProfile: Bool = false
    @Published var dynamicLinkContactID: Int = 0
    @Published var selectedConnectyDialog: ChatDialog?
    
    @Published public var monthlySubscription: Purchases.Package?
    @Published public var threeMonthSubscription: Purchases.Package?
    @Published public var yearlySubscription: Purchases.Package?
    @Published public var inPaymentProgress = false
    @Published public var subscriptionStatus: PremiumSubscriptionStatus = UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") ? .subscribed : .notSubscribed
    @Published public var notificationtext: String = ""
    
    @Published var avitarProgress: CGFloat = CGFloat(0.0)
    @Published var acceptScrolls: Bool = true
    @Published var onlineCount: Int = 0
    
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    @ObservedObject var contacts = ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
    @ObservedObject var messages = MessagesRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(MessageStruct.self))
    
    var anyCancellable: AnyCancellable? = nil
    var anyCancellable1: AnyCancellable? = nil
    var locationManager: CLLocationManager = CLLocationManager()
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    var persistenceManager: PersistenceManager = PersistenceManager()

    override init() {
        super.init()
        self.locationManager.delegate = self
        
        anyCancellable = profile.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
        anyCancellable1 = contacts.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
     }
    
    // MARK: - Auth
    func configureFirebaseStateDidChange() {
        if self.profile.results.count > 0 {
            self.isUserAuthenticated = .signedIn
        } else {
            self.preventDismissal = true
            self.isUserAuthenticated = .signedOut
        }
    }

    func sendVerificationNumber(numberText: String) {
        self.verifyPhoneNumberStatus = .loading
        PhoneAuthProvider.provider().verifyPhoneNumber(numberText.trimmingCharacters(in: .whitespacesAndNewlines), uiDelegate: nil, completion: {(verificationID, error) in
            if error != nil {
                print("error with sending verification: \(String(describing: error?.localizedDescription)))")
                self.verifyPhoneNumberStatus = .error
            } else {
                self.verifyPhoneNumberStatus = .success
                print("success sending!! es")
                UserDefaults.standard.set(verificationID, forKey: "authID")
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    self.verifyPhoneStatusKeyboard = true
                }
            }
        })
    }
    
    func checkSecurityCode(securityCode: String, completion: @escaping (Bool) -> ()) {
        UserDefaults.standard.set(securityCode, forKey: "securityCode")
        UserDefaults.standard.set(false, forKey: "localOpen")
        self.verifyCodeStatus = .loading
        let credential: PhoneAuthCredential = PhoneAuthProvider.provider().credential(withVerificationID: UserDefaults.standard.string(forKey: "authID") ?? "", verificationCode: securityCode)
        
        //login & check firebase pin code
        Auth.auth().signIn(with: credential) { (userz, error) in
           if error != nil {
                print("error: \(String(describing: error?.localizedDescription))")
                self.verifyCodeStatus = .error
                completion(false)
                return
           } else {
                //Save to firestore...
                UserDefaults.standard.set(userz!.user.phoneNumber, forKey: "phoneNumber")
                let data: [String: Any] = ["providerID" : userz!.user.providerID, "phoneNumber" : userz!.user.phoneNumber ?? "", "localAuth" : false]
                AuthModel.mergeProfile(data, uid: userz?.user.phoneNumber ?? "") { result in
                    if result != true {
                        print("error when adding the user to firestore: \(result)")
                        self.verifyCodeStatus = .error
                        completion(false)
                        return
                    }
                    print("you have successfuly added the user to firestore: \(result)... onto merging to ConnectyCube")
                    Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                        if error != nil {
                            // Handle error
                            self.verifyCodeStatus = .error
                            completion(false)
                            return
                        } else {
                            //Save ConnectyCube tokenID & loginto ConnectyCube then save & notify
                            UserDefaults.standard.set(idToken, forKey: "tokenID")
                            Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: idToken ?? "", successBlock: { (user) in
                                print("You are now loged in with ConnectyCube: \(String(describing: user.password)) created at: \(String(describing: user.createdAt)) & last sesh at: \(String(describing: user.lastRequestAt?.getElapsedInterval(lastMsg: "now"))) with the name of: \(String(describing: user.fullName?.description))")
                                UserDefaults.standard.set(user.id, forKey: "currentUserID")
                                if (userz?.additionalUserInfo?.isNewUser ?? true) == false {
                                    if Chat.instance.isConnected {
                                        Chat.instance.disconnect { (error) in
                                            print("chat did disconnect. error?: \(String(describing: error?.localizedDescription))")
                                        }
                                    }
                                } else {
                                    changeAddressBookRealmData().removeAllAddressBook(completion: { _ in })
                                }
                                changeProfileRealmDate().updateProfile(user, completion: {
                                    //Update Firebase Analitics log events by checking Firebase new user
                                    Chat.instance.connect(withUserID: UInt(user.id), password: Session.current.sessionDetails?.token ?? "") { (error) in
                                        if error != nil {
                                            print("there is a error connecting to session! \(String(describing: error))")
                                        } else {
                                            print("Success joining session from Login! the current user: \(String(describing: Session.current.currentUserID))")
                                        }
                                    }
                                    Purchases.shared.identify(userz!.user.uid, { (info, error) in
                                        if let e = error {
                                            print("Sign in error: \(e.localizedDescription)")
                                        } else {
                                            print("User \(userz!.user.uid) signed in")
                                        }
                                    })
                                    if (userz?.additionalUserInfo?.isNewUser ?? true) {
                                        Analytics.logEvent(AnalyticsEventSignUp, parameters: [AnalyticsParameterMethod: "Phone Number Security Code - from Sign Up"])
                                    } else {
                                        Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "Phone Number Security Code - from LogIn"])
                                        if user.fullName != nil {
                                            self.haveUserFullName = true
                                            //print("user has full name... name: \(String(describing: user.fullName))")
                                        }
                                        if self.persistenceManager.getCubeProfileImage(usersID: user) != nil {
                                            self.haveUserProfileImg = true
                                            //print("user has profile image too... link: \(String(describing: self.persistenceManager.getCubeProfileImage(usersID: user)))")
                                        }
                                    }
                                   self.verifyCodeStatus = .success
                                })

                               completion(true)
                            }) { (error) in
                                //print("Error in the connectycube login... error: \(error.localizedDescription)")
                               self.verifyCodeStatus = .error
                               completion(false)
                               return
                           }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: IN APP PURCHASE
    public func initIAPurchase() {
        Purchases.shared.offerings { (offerings, error) in
            if error != nil {
                print("error getting IAP offerings: \(String(describing: error?.localizedDescription))")
            } else {
                print("received the IAP offerings: \(String(describing: offerings?.current))")
                self.monthlySubscription = offerings?.current?.monthly
                self.threeMonthSubscription = offerings?.current?.threeMonth
                self.yearlySubscription = offerings?.current?.annual
            }
        }
        refreshSubscription()
    }
    
    public func purchase(source: String, product: Purchases.Package) {
        guard !inPaymentProgress else { return }
        self.inPaymentProgress = true
        Purchases.shared.setAttributes(["source": source])
        Purchases.shared.purchasePackage(product) { (transaction, purchaserInfo, error, userCancelled) in
            print("error purchasing? : \(String(describing: error?.localizedDescription))")
            self.processInfo(info: purchaserInfo)
        }
    }
    
    public func refreshSubscription() {
        Purchases.shared.purchaserInfo { (info, error) in
            if let e = error {
                print("error getting purcherser \(e.localizedDescription)")
            }
            self.processInfo(info: info)
            print("the purchaser info is: \(String(describing: info))")
        }
    }
    
    public func restorePurchase() {
        Purchases.shared.restoreTransactions { (info, _) in
            self.processInfo(info: info)
            print("the user is subed? :\(self.subscriptionStatus)")
        }
    }
    
    private func processInfo(info: Purchases.PurchaserInfo?) {
        if info?.entitlements.all["Premium"]?.isActive == true {
            print("has purched")
            self.subscriptionStatus = .subscribed
            UserDefaults.standard.set(true, forKey: "premiumSubscriptionStatus")
            Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isPremium" : true])
        } else {
            print("has NOT purched: \(String(describing: info?.entitlements.all)) && \(String(describing: info?.entitlements.all["Premium"]?.isSandbox))")
            self.subscriptionStatus = .notSubscribed
            UserDefaults.standard.set(false, forKey: "premiumSubscriptionStatus")
            Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isPremium" : false])
        }
        inPaymentProgress = false
    }

    func handleIncomingDynamicLink(_ dynamicLink: DynamicLink) {
        guard let url = dynamicLink.url else {
            print("weird, my link object has no url")
            return
        }
        print("Your incoming link is: \(url.absoluteString)")
        
        guard (dynamicLink.matchType == .unique || dynamicLink.matchType == .default) else {
            print("not a string enough match type to continue")
            return
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return }
        
        if components.path == "/contact" {
            if  let postIdQueryItem = queryItems.first(where: {$0.name == "contactID"}) {
                guard let contactId = postIdQueryItem.value else { return }
                print("WE MADE IT TO GOING INTO A CONTACT: \(Int(contactId) ?? 0)")
                if self.isUserAuthenticated == .signedIn {
                    self.dynamicLinkContactID = Int(contactId) ?? 0
                    self.visitContactProfile = true
                } else {
                    print("user is logged out")
                }
            }
        }
    }
    
    // MARK: - Set Profile
    static func mergeProfile(_ data: [String: Any], uid: String, completion: @escaping (Bool) -> Void) {
        let reference = Firestore.firestore().collection("Profiles").document(uid)
        reference.setData(data, merge: true) { (err) in
            if err != nil {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func updateFullName(phoneNumber: String, fullName: String, completion: @escaping (Bool) -> Void) {
        let updateParameters = UpdateUserParameters()
        updateParameters.fullName = fullName

        Request.updateCurrentUser(updateParameters, successBlock: { (user) in
            //success updating name..now save to core data
            //self.persistenceManager.setCubeProfile(user)
            changeProfileRealmDate().updateProfile(user, completion: {
                
            })
            self.haveUserFullName = true
            //upload that data to firebase firestore
            if let phoneNum = user.phone {
                let reference = Firestore.firestore().collection("Profiles").document(phoneNum)
                reference.updateData(["fullName" : user.fullName ?? "New Chatr User"], completion: { (error) in
                    if error == nil {
                        print("success adding name to firebase")
                        self.haveUserFullName = true
                    } else {
                        print("error adding name to firebase")
                        self.haveUserFullName = false
                    }
                })
            }
            print("success upllading full name \(String(describing: user.fullName))")
            completion(true)
        }) { (error) in
            print("the error in full name is: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func setUserAvatar(image: UIImage, completion: @escaping (Bool) -> Void) {
        let image = image
        let data = image.jpegData(compressionQuality: 0.2)
        
        Request.uploadFile(with: data!, fileName: "user's_profileImg", contentType: "image/jpeg", isPublic: false, progressBlock: { (progress) in
            //set progress here
            print("the upload progress is: \(progress)")
            self.avitarProgress = CGFloat(progress)
            
        }, successBlock: { (blob) in
            let parameters = UpdateUserParameters()
            let customData = ["avatar_uid" : blob.uid]
            if let theJSONData = try? JSONSerialization.data(withJSONObject: customData, options: .prettyPrinted) {
                parameters.customData = String(data: theJSONData, encoding: .utf8)
            }
            Request.updateCurrentUser(parameters, successBlock: { (user) in
                //self.persistenceManager.setCubeProfile(user)
                changeProfileRealmDate().updateProfile(user, completion: {
                    
                })
                self.haveUserProfileImg = true
                //self.store(image: image, compression: 1.0, forKey: "userImage", withStorageType: .fileSystem)
                completion(true)
            }, errorBlock: { (error) in
                completion(false)
            })
        }) { (error) in
            print("error somehow uploading...\(error.localizedDescription)")
            completion(false)
        }
    }
    
    // MARK: - Save User Image
    
    func store(image: UIImage, compression: Double, forKey key: String, withStorageType storageType: StorageType) {
        if let pngRepresentation = image.jpegData(compressionQuality: CGFloat(compression)) {
            switch storageType {
            case .fileSystem:
                if imageComparison(image1: image, isEqualTo: self.retrieveImage(forKey: key, inStorageType: .fileSystem) ?? UIImage()) {
                    print("you already have this image saved...")
                } else {
                    print("success saving image to file system")
                    if let filePath = filePath(forKey: key) {
                        do  {
                            if key == "userImage" {
                                //self.avitarImg = image
                            }
                            try pngRepresentation.write(to: filePath, options: .atomic)
                        } catch let err {
                            print("Saving file resulted in error: ", err)
                        }
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation, forKey: key)
            }
        }
    }
    
    func retrieveImage(forKey key: String, inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
                let fileData = FileManager.default.contents(atPath: filePath.path),
                let image = UIImage(data: fileData) {
                if key == "userImage" {
                    //self.avitarImg = image
                }
                return image
            } else {
                print("The image had an error loading the local image")
            }
            
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
    
    private func imageComparison(image1: UIImage, isEqualTo image2: UIImage) -> Bool {
        let data1: NSData = image1.pngData()! as NSData
        let data2: NSData = image2.pngData()! as NSData
        return data1.isEqual(data2)
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first else { return nil }
        
        return documentURL.appendingPathComponent(key + ".png")
    }

    // MARK: - Logout Firebase & Connectycube
    func logOutConnectyCube() {
        Chat.instance.disconnect { (error) in
            if error != nil {
                print("error disconnecting from connecty cube: \(String(describing: error?.localizedDescription))")
            }
        }
//        Request.unregisterSubscription(forUniqueDeviceIdentifier: UIDevice.current.identifierForVendor!.uuidString, successBlock: nil)
        Request.logOut(successBlock: {
            print("success logging out of connecty cube")
            self.verifyPhoneNumberStatus = .undefined
            changeProfileRealmDate().removeAllProfile()
            changeMessageRealmData.removeAllMessages(completion: { _ in })
            changeDialogRealmData().removeAllDialogs()
            changeContactsRealmData().removeAllContacts()
            changeQuickSnapsRealmData().removeAllQuickSnaps()
        }) { (error) in
            print("Error logging out of ConnectyCube: \(error.localizedDescription)")
        }
    }
    
    func logOutFirebase() {
        let firebaseAuth = Auth.auth()
        self.preventDismissal = true
        do {
            try firebaseAuth.signOut()
            Database.database().reference().child("Users").removeAllObservers()
            self.isUserAuthenticated = .signedOut
            //self.configureFirebaseStateDidChange()
            UserDefaults.standard.set(0, forKey: "selectedWallpaper")
            print("done logging out firebase!")
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    func leaveDialog() {
        if let dialog = self.selectedConnectyDialog {
            if dialog.type == .group || dialog.type == .public{
                dialog.leave { (error) in
                    self.onlineCount = 0
                    print("just left dialog! error?: \(String(describing: error?.localizedDescription))")
                }
            }
            dialog.sendUserStoppedTyping()
        }
    }
    
    public func setOnlineCount() {
        if let dialog = self.selectedConnectyDialog {
            if dialog.type == .group || dialog.type == .public {
                self.onlineCount = 0
                dialog.requestOnlineUsers(completionBlock: { (online, error) in
                    self.onlineCount = online?.count ?? 0
                    print("the online count is: \(self.onlineCount)")
                })
                print("done getting online")
            } else {
                print("not a group dialog \(String(describing: self.selectedConnectyDialog?.type))")
            }
        }
    }
    
    func createTopFloater(alertType: String, message: String) -> some View {
        HStack() {
            Image(systemName: alertType == "error" ? "xmark.octagon" : alertType == "success" ? "checkmark.circle" : "bell.badge.fill")
                .resizable()
                .foregroundColor(alertType == "error" ? .red : alertType == "success" ? .green : .primary)
                .aspectRatio(contentMode: ContentMode.fill)
                .frame(width: 25, height: 25)
                .padding(.horizontal, 5)
            
            Text(message)
                .font(.none)
                .foregroundColor(.primary)
            Spacer()
        }.padding(.horizontal)
        .frame(width: Constants.screenWidth - 35, height: 70)
        .background(BlurView(style: .systemMaterial))
        .cornerRadius(15)
    }
    
    public func sendPushNoti(userIDs: [NSNumber], message: String) {
        let event = Event()
        event.notificationType = .push
        event.usersIDs = userIDs
        event.type = .oneShot
        event.name = "Liked Quick Snap"

        var pushParameters = [String : String]()
        pushParameters["message"] = message
        pushParameters["ios_sound"] = "app_sound.wav"
        pushParameters["title"] = "Liked Quci Snap"

        if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
            let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

            event.message = jsonString

            Request.createEvent(event, successBlock: {(events) in
                print("sent push notification!! \(events)")
            }, errorBlock: {(error) in
                print("error sending noti: \(error.localizedDescription)")
            })
        }
    }
    
//    func joinDialog(dialogModel: DialogStruct) {
//        let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]
//        Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
//            for dialog in dialogs {
//                if dialog.id == dialogModel.id {
//                    self.selectedConnectyDialog = dialog
//                    
//                    self.setOnlineCount()
//                    self.selectedConnectyDialog?.onUserIsTyping = { (userID: UInt) in
//                        print("this dude is typing!!: \(userID)")
//                    }
//                    
//                    self.selectedConnectyDialog?.onUserStoppedTyping = { (userID: UInt) in
//                        print("this dude STOPPED typing!!: \(userID)")
//                    }
//                    
//                    if dialogModel.dialogType == "group" || dialogModel.dialogType == "public" {
//                        if !dialog.isJoined() {
//                            dialog.join(completionBlock: { error in
//                                print("we ahve joined the dialog!!")
//                            })
//                        }
//                    }
//
//                    break
//                }
//            }
//        })
//    }
    
    // MARK: - Icons
    func changeHomeIconTo(name: String?) {
        UIApplication.shared.setAlternateIconName(name ?? nil) { error in
            if let error = error {
                print("the error changing the icon is:" + error.localizedDescription)
            } else {
                print("Success! Changed the home icon to: \(String(describing: name ?? "default app icon"))")
            }
        }
    }
        
    // MARK: - Noti Permission
    func checkNotiPermission() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                print("Noti permission is .notDermined")
                self.notificationPermission = false
            } else if settings.authorizationStatus == .denied {
                print("Noti permission is .denied")
                self.notificationPermission = false
            } else if settings.authorizationStatus == .authorized {
                print("Noti permission is .auth")
                self.notificationPermission = true
            }
        })
    }
    
    // MARK: - Photo Permission
    func checkPhotoPermission() {
        // Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
            self.photoPermission = true
        } else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
            self.photoPermission = false
        }
    }
    
    // MARK: - Camera Permission
    func checkCameraPermission() {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
            self.cameraPermission = true
        } else {
            self.cameraPermission = false
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
           if granted == true {
            self.cameraPermission = true
           } else {
            self.cameraPermission = false
           }
        })
    }
    
    // MARK: - Location Permission
    
    func requestLocationPermission() {
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationPermission = true
    }
    
    func checkLocationPermission() {
        let manager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
                case .notDetermined, .restricted, .denied:
                    print("No access to location")
                    self.locationPermission = false
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Access location true")
                    self.locationPermission = true
                @unknown default:
                break
            }
        } else {
            print("Location services are not enabled")
            self.locationPermission = false
        }
    }
    
    // MARK: - Contacts Permission

    func requestContacts() {
        let store = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            store.requestAccess(for: .contacts){succeeded, err in
                guard err == nil && succeeded else {
                    self.contactsPermission = false
                    return
                }
                if succeeded {
                    self.contactsPermission = true
                }
            }
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            print("Contacts are authorized")
            self.contactsPermission = true

        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.contactsPermission = false
        }
    }
    
    func checkContactsPermission() {
       if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            print("Contacts are notDetermined")
            self.contactsPermission = false
       } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
           print("Contacts are authorized")
           self.contactsPermission = true
       }
    }
}

extension AuthModel: CLLocationManagerDelegate {
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == CLAuthorizationStatus.denied) {
            self.locationPermission = false
            print("Location deniedddddddd")
        } else if (status == CLAuthorizationStatus.authorizedAlways) {
            self.locationPermission = true
            print("Location is AUTHHHHHHHHH")
        }
    }
}


//MARK: ChatDelegate
extension AuthModel: ChatDelegate {
    
    func chatDidConnect() {
        print("Chat did Connect!!! \(String(describing: Session.current.sessionDetails?.userID))")
    }

    func chatDidReconnect() {
        print("Chat did Reconnect")
    }

    func chatDidDisconnectWithError(_ error: Error) {
        print("Chat did Disconnect:")
    }

    func chatDidNotConnectWithError(_ error: Error) {
        print("Chat did not connect:")
    }
    
    func chatDidReceiveContactAddRequest(fromUser userID: UInt) {
        self.profile.addContactRequest(userID: userID)
        
        print("chat did receive Contact Request userID: \(userID) & \(String(describing: self.profile.results.first?.contactRequests)) & \(String(describing: self.profile.results.first?.contactRequests.contains(Int(userID))))")
    }
    
    func chatDidReceiveAcceptContactRequest(fromUser userID: UInt) {
        print("chat did receive ACCEPTED new Contact! userID: \(userID)")
        changeContactsRealmData().updateSingleRealmContact(userID: Int(userID), completion: { _ in })
        self.profile.removeContactRequest(userID: userID)
    }
    
    func chatDidReceiveRejectContactRequest(fromUser userID: UInt) {
        print("chat did receive REJECTED Contact request! userID: \(userID)")
        self.profile.removeContactRequest(userID: userID)
    }
    
    func chatContactListDidChange(_ contactList: ContactList) {
        print("contact list did change: \(contactList.contacts.count)")
        if contactList.contacts.count > 0 {
            changeContactsRealmData().updateContacts(contactList: contactList.contacts, completion: { _ in })
        } else {
//                changeContactsRealmData().removeAllContacts()
        }
    }
    
    func chatDidReceiveContactItemActivity(_ userID: UInt, isOnline: Bool, status: String?) {
        print("contact list did receive new activity from: \(userID). Is online: \(isOnline). Status: \(String(describing: status))")
        self.setOnlineCount()
        changeContactsRealmData().updateContactOnlineStatus(userID: userID, isOnline: isOnline)
    }
    
    func chatDidDeliverMessage(withID messageID: String, dialogID: String, toUserID userID: UInt) {
        print("messgae delivered is: \(messageID) & to user: \(userID)")
        self.acceptScrolls = false
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let deliveredMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try? realm.safeWrite {
                    deliveredMessage.messageState = .delivered
                    realm.add(deliveredMessage, update: .all)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func chatDidReadMessage(withID messageID: String, dialogID: String, readerID: UInt) {
        print("messgae read: \(messageID) & by user: \(readerID)")
        if readerID != UserDefaults.standard.integer(forKey: "currentUserID") {
            self.acceptScrolls = false
            let config = Realm.Configuration(schemaVersion: 1)
            do {
                let realm = try Realm(configuration: config)
                if let readMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                    try? realm.safeWrite {
                        readMessage.messageState = .read
                        readMessage.readIDs.append(Int(readerID))
                        realm.add(readMessage, update: .all)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("the message was read by yourself!")
        }
    }
    
    func chatDidReceive(_ message: ChatMessage) {
        print("receved new message: \(String(describing: message.text)) from: \(message.senderID)")
        self.acceptScrolls = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if UserDefaults.standard.bool(forKey: "localOpen") {
            if (!message.removed) {
                changeMessageRealmData.insertMessage(message, completion: { })
                
                if message.senderID != UserDefaults.standard.integer(forKey: "currentUserID") {
                    Chat.instance.read(message) { (error) in
                        print("read chat message! error?? \(String(describing: error?.localizedDescription))")
                    }
                }
            }
        } else {
            changeDialogRealmData.fetchDialogs(completion: { _ in })
        }
        if (message.removed) {
            changeMessageRealmData.updateMessageState(messageID: message.id ?? "", messageState: .deleted)
        } else if (message.edited) {
            changeMessageRealmData.updateMessageState(messageID: message.id ?? "", messageState: .editied)
        } else if (message.delayed) {
            changeMessageRealmData.updateMessageDelayState(messageID: message.id ?? "", messageDelayed: true)
        }
        self.acceptScrolls = false
    }
    
    func chatRoomDidReceive(_ message: ChatMessage, fromDialogID dialogID: String) {
        print("receved new GROUP message: \(String(describing: message.text)) for dialogID: \(dialogID)")
        //self.acceptScrolls = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        changeMessageRealmData.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
        if UserDefaults.standard.bool(forKey: "localOpen") {
            if (!message.removed) {
                Chat.instance.read(message) { (error) in
                    changeMessageRealmData.insertMessage(message, completion: { })
                }
            }
            self.setOnlineCount()
        } else {
            changeDialogRealmData.fetchDialogs(completion: { _ in })
        }
        if (message.removed) {
            changeMessageRealmData.updateMessageState(messageID: message.id ?? "", messageState: .deleted)
        } else if (message.edited) {
            changeMessageRealmData.updateMessageState(messageID: message.id ?? "", messageState: .editied)
        } else if (message.delayed) {
            changeMessageRealmData.updateMessageDelayState(messageID: message.id ?? "", messageDelayed: true)
        }
        //self.acceptScrolls = false
    }
        
    //MARK: BLOCK LIST DELEGATE
    func chatDidSetPrivacyList(withName name: String) {
        print("did set privacy list: \(name)")
    }
    
    func chatDidNotSetPrivacyList(withName name: String, error: Error) {
        print("did set privacy list \(name) & error: \(error.localizedDescription)")
    }
    
    func chatDidSetDefaultPrivacyList(withName name: String) {
        print("did set DEFAULT privacy list: \(name) & the names are: \(Chat.instance.retrievePrivacyListNames())")
    }
    
    func chatDidNotSetDefaultPrivacyList(withName name: String, error: Error) {
        print("did NOT set DEFAULT privacy list: \(name) & error: \(error.localizedDescription)")
    }
    
    func chatDidReceivePrivacyListNames(_ listNames: [String]) {
        print("did receive privacy list names:")
        for i in listNames {
            print("privacy name: \(i)")
        }
    }
    
    func chatDidNotReceivePrivacyListNamesDue(toError error: Error) {
        print("did NOT receive privacy list names because: \(error.localizedDescription)")
    }
    
    func chatDidReceive(_ privacyList: PrivacyList) {
        print("did receive privacy list: \(privacyList.name)")
    }
    
    func chatDidNotReceivePrivacyList(withName name: String, error: Error) {
        print("did NOT receive privacy list: \(name) & error: \(error.localizedDescription)")
    }
    
    func chatDidRemovedPrivacyList(withName name: String) {
        print("did REMOVE privacy list: \(name)")
    }
}