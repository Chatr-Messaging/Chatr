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
import Uploadcare

enum AuthState {
    case undefined, signedOut, signedIn, error
}

enum PhoneNumberStatus {
    case undefined, success, loading, error
}

enum connectionState {
    case connected, disconnected, loading, error
}

enum NetworkStatus: String {
    case connected, disconnected
}

enum messageKind: String {
    case text, image, gif, contact, attachment, location, removed
}

enum messageStatus: String {
    case delivered, sent, sending, read, isTyping, removedTyping, edited, deleted, error
}

enum messagePosition {
    case left, right, unknown
}

enum visitUserState {
    case unknown, fromContacts, fromSearch, fromRequests, fromDynamicLink, fromGroupDialog
}

enum visitPublicDialogState {
    case unknown, fromDiscover, fromDialogCell, fromDynamicLink, fromSharedMessage
}

enum openProfileSocialLink {
    case instagram, facebook, twitter, none
}

enum visitContactRelationship {
    case unknown, contact, notContact, pendingRequest, pendingRequestForYou
}

enum visitDialogRelationship {
    case unknown, subscribed, notSubscribed, admin, group, error
}

enum morePublicListRelationship {
    case unknown, tags, popular, newest
}

enum StorageType {
    case userDefaults
    case fileSystem
}

enum PremiumSubscriptionStatus {
    case subscribed, notSubscribed
}

class AuthModel: NSObject, ObservableObject {
    @Published var currentTask: UploadTaskResumable?
    @Published var networkStatus: NetworkStatus = .connected

    @Published var attempted: Bool = false
    @Published var preventDismissal: Bool = false
        
    @Published var isUserAuthenticated: AuthState = .undefined
    @Published var verifyPhoneNumberStatus: PhoneNumberStatus = .undefined
    @Published var verifyCodeStatus: PhoneNumberStatus = .undefined
    @Published var haveUserFullName = false
    @Published var haveUserProfileImg = false
    @Published var isFirstTimeUser = false
    @Published var verifyCodeStatusKeyboard = false
    @Published var verifyPhoneStatusKeyboard = false
    
    @Published var isLocalAuth = false
    @Published var visitContactProfile: Bool = false
    @Published var visitPublicDialogProfile: Bool = false
    @Published var dynamicLinkContactID: Int = 0
    @Published var dynamicLinkPublicDialogID: String = ""
    @Published var selectedConnectyDialog: ChatDialog?
    
    @Published public var monthlySubscription: Purchases.Package?
    @Published public var threeMonthSubscription: Purchases.Package?
    @Published public var yearlySubscription: Purchases.Package?
    @Published public var inPaymentProgress = false
    @Published public var subscriptionStatus: PremiumSubscriptionStatus = UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") ? .subscribed : .notSubscribed

    @Published var avatarProgress: CGFloat = CGFloat(0.0)

    @Published var delegateConnectionState: ((_ connectState: connectionState) -> ())?
    
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    @ObservedObject var contacts = ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))
    @ObservedObject var messages = MessagesRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(MessageStruct.self))
    @ObservedObject var addressBook = AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self))
    @ObservedObject var quickSnaps = QuickSnapsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(QuickSnapsStruct.self))
    
    @Published var userHasiOS15: Bool = false
    var anyCancellable: AnyCancellable? = nil
    
//    private let monitor = NWPathMonitor()
//    private let queue = DispatchQueue(label: "Monitor")

    override init() {
        super.init()
        anyCancellable = profile.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        anyCancellable = messages.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
        anyCancellable = contacts.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }

//        monitor.pathUpdateHandler = { [weak self] path in
//            guard let self = self else { return }
//
//            DispatchQueue.main.async {
//                if path.status == .satisfied {
//                    print("We're connected!")
//                    self.networkStatus = .connected
//                } else {
//                    print("No connection....")
//                    self.networkStatus = .disconnected
//                }
//            }
//        }
//
//        monitor.start(queue: queue)
     }
    
    // MARK: - Auth
    func configureFirebaseStateDidChange() {
        if Auth.auth().currentUser != nil && self.profile.results.count > 0 {
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
                self.verifyPhoneNumberStatus = .error
            } else {
                self.verifyPhoneNumberStatus = .success
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
                self.verifyCodeStatus = .error
                completion(false)
            
                return
           } else {
                //Save to firestore...
                UserDefaults.standard.set(userz!.user.phoneNumber, forKey: "phoneNumber")
                let data: [String: Any] = ["providerID" : userz!.user.providerID, "phoneNumber" : userz!.user.phoneNumber ?? "", "localAuth" : false]
                AuthModel.mergeProfile(data, uid: userz?.user.phoneNumber ?? "") { result in
                    if result != true {
                        self.verifyCodeStatus = .error
                        completion(false)
                        
                        return
                    }

                    Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
                        if error != nil {
                            // Handle error
                            self.verifyCodeStatus = .error
                            completion(false)
                            return
                        } else {
                            //Save ConnectyCube tokenID & log-into ConnectyCube then save & notify
                            //UserDefaults.standard.set(idToken, forKey: "tokenID")
                            Request.logIn(withFirebaseProjectID: Constants.FirebaseProjectID, accessToken: idToken ?? "", successBlock: { (user) in
                                UserDefaults.standard.set(user.id, forKey: "currentUserID")
                                if (userz?.additionalUserInfo?.isNewUser ?? true) == false {
                                    self.isFirstTimeUser = false
                                    Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "Phone Number Security Code - from LogIn"])
                                    if user.fullName != nil {
                                        self.haveUserFullName = true
                                    }

                                    if user.avatar != nil {
                                        self.haveUserProfileImg = true
                                    }
                                } else {
                                    self.isFirstTimeUser = true
                                    changeAddressBookRealmData.shared.removeAllAddressBook(completion: { _ in
                                        Analytics.logEvent(AnalyticsEventSignUp, parameters: [AnalyticsParameterMethod: "Phone Number Security Code - from Sign Up"])
                                        self.fetchTotalUserCount(completion: { count in
                                            Database.database().reference().child("Users").child("\(user.id)").updateChildValues(["userNumber" : count])
                                            if count <= Constants.maxNumberEarlyAdopters {
                                                UserDefaults.standard.set(true, forKey: "isEarlyAdopter")
                                            }
                                        })
                                    })
                                }

                                self.profile.updateProfile(user, completion: {
                                    //Update Firebase Analytics log events by checking Firebase new user
                                    Chat.instance.connect(withUserID: UInt(user.id), password: Session.current.sessionDetails?.token ?? "") { (error) in
                                        if error != nil {
                                            self.verifyCodeStatus = .error
                                        } else {
                                            self.verifyPhoneStatusKeyboard = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                self.verifyCodeStatus = .success
                                                if user.fullName == nil {
                                                    self.verifyCodeStatusKeyboard = true
                                                }
                                            }
                                        }
                                    }
                                })
                                completion(true)
                            }) { (error) in
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
            if error == nil {
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
            self.processInfo(info: purchaserInfo)
        }
    }
    
    public func refreshSubscription() {
        Purchases.shared.purchaserInfo { (info, error) in
            self.processInfo(info: info)
        }
    }
    
    public func restorePurchase() {
        Purchases.shared.restoreTransactions { (info, _) in
            self.processInfo(info: info)
        }
    }

    private func processInfo(info: Purchases.PurchaserInfo?) {
        if info?.entitlements.all["Premium"]?.isActive == true {
            self.subscriptionStatus = .subscribed
            UserDefaults.standard.set(true, forKey: "premiumSubscriptionStatus")
            Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isPremium" : true])
        } else {
            self.subscriptionStatus = .notSubscribed
            UserDefaults.standard.set(false, forKey: "premiumSubscriptionStatus")
            Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["isPremium" : false])
        }
        inPaymentProgress = false
    }

    func handleIncomingDynamicLink(_ dynamicLink: DynamicLink) {
        guard let url = dynamicLink.url, (dynamicLink.matchType == .unique || dynamicLink.matchType == .default), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { return }

        if components.path == "/contact" {
            if let postIdQueryItem = queryItems.first(where: {$0.name == "contactID"}) {
                guard let contactId = postIdQueryItem.value else { return }

                if self.isUserAuthenticated == .signedIn {
                    self.dynamicLinkContactID = Int(contactId) ?? 0
                    self.visitContactProfile = true
                }
            }
        } else if components.path == "/publicDialog" {
            if let postIdQueryItem = queryItems.first(where: {$0.name == "publicDialogID"}) {
                guard let dialogId = postIdQueryItem.value else { return }

                if self.isUserAuthenticated == .signedIn {
                    self.dynamicLinkPublicDialogID = dialogId
                    self.visitPublicDialogProfile = true
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
            //self.persistenceManager.setCubeProfile(user)
            self.profile.updateProfile(user, completion: {
                //upload that data to firebase firestore
                if let phoneNum = user.phone {
                    let reference = Firestore.firestore().collection("Profiles").document(phoneNum)
                    reference.updateData(["fullName" : user.fullName ?? "New Chatr User"], completion: { (error) in
                        if error == nil {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    })
                }
            })
        }) { (error) in
            print("the error in full name is: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func setUserAvatar(imageId: String, oldLink: String, completion: @escaping (Bool) -> Void) {
        //First check if current profile image has a photo to delete from backend
//        DispatchQueue.main.async {
//            self.removeOldProfileImage(oldString: oldLink, completion: { didWork in
//                print("did delete upload image: \(didWork)")
//            })
//        }
        
        //Next update connecty cube personal profile
        let parameters = UpdateUserParameters()
        parameters.avatar = Constants.uploadcareBaseUrl + imageId + Constants.uploadcareStandardTransform

        Request.updateCurrentUser(parameters, successBlock: { (user) in
            self.profile.updateProfile(user, completion: {
                self.haveUserProfileImg = true
                completion(true)
            })
        }, errorBlock: { (error) in
            completion(false)
        })
    }
    
    func removeOldProfileImage(oldString: String, completion: @escaping (Bool) -> Void) {
        guard oldString != "" else {
            completion(false)
            return
        }
  
        let semaphore = DispatchSemaphore(value: 0)
        let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
        let trimmedString = oldString.replacingOccurrences(of: Constants.uploadcareBaseUrl, with: "").replacingOccurrences(of: Constants.uploadcareStandardTransform, with: "").replacingOccurrences(of: "/", with: "")

        uploadcare.deleteFile(withUUID: trimmedString, { (file, error) in
            defer {
                semaphore.signal()
            }
            
            if error != nil {
                completion(false)
                return
            }

            completion(true)
        })
        
        semaphore.wait()
    }
    
    func removeContactRequest(userID: UInt) {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let oldData = realm.object(ofType: ProfileStruct.self, forPrimaryKey: UserDefaults.standard.integer(forKey: "currentUserID")) {
                try realm.safeWrite ({
                    if let index = oldData.contactRequests.firstIndex(of: Int(userID)) {
                        oldData.contactRequests.remove(at: index)
                    }
                    realm.add(oldData, update: .all)    
                })
            }
        } catch {  }
    }
    
    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center) {
            VStack(spacing: 0) {
                content()
            }.padding(.vertical, 10)
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
    
    // MARK: - Upload Care Functions
    
    func uploadFile(_ url: URL, completionHandler: @escaping (String) -> Void) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            completionHandler("")
            return
        }
        
        self.avatarProgress = 0
        let filename = url.lastPathComponent

        if data.count < UploadAPI.multipartMinFileSize {
            self.performDirectUpload(filename: filename, data: data, completionHandler: completionHandler)
        } else {
            self.performMultipartUpload(filename: filename, fileUrl: url, completionHandler: completionHandler)
        }
    }
    
    func performDirectUpload(filename: String, data: Data, completionHandler: @escaping (String) -> Void) {
        let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
        let semaphore = DispatchSemaphore(value: 0)
        
        uploadcare.uploadAPI.upload(files: [filename: data], store: .store, { (progress) in
            DispatchQueue.main.async { [weak self] in
                self?.avatarProgress = CGFloat(progress)
            }
        }) { (resultDictionary, error) in
            defer {
                semaphore.signal()
            }
            
            if error != nil {
                completionHandler("")
                return
            }

            guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                completionHandler("")
                return
            }
            
            completionHandler(fileId)
        }
        
        semaphore.wait()
    }
    
    func performMultipartUpload(filename: String, fileUrl: URL, completionHandler: @escaping (String) -> Void) {
        let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)

        let onProgress: (Double)->Void = { (progress) in
            DispatchQueue.main.async { [weak self] in
                self?.avatarProgress = CGFloat(progress)
                
//                switch UIApplication.shared.applicationState {
//                case .background:
//                    let remain = UIApplication.shared.backgroundTimeRemaining.rounded(toPlaces: 2)
//                    DLog("Background time remaining = \(remain) seconds")
//                default: break
//                }
            }
        }

        guard let fileForUploading = uploadcare.uploadAPI.file(withContentsOf: fileUrl) else {
            assertionFailure("file not found")
            return
        }
        
        self.currentTask = fileForUploading.upload(withName: filename, store: .store, onProgress, { (file, error) in
            defer {
                self.currentTask = nil
            }
            
            if error != nil {
                return
            }
            
            guard let file = file else { return }

            completionHandler(file.fileId)
        })
    }
    
    // MARK: - Save User Image
    
    func store(image: UIImage, compression: Double, forKey key: String, withStorageType storageType: StorageType) {
        if let pngRepresentation = image.jpegData(compressionQuality: CGFloat(compression)) {
            switch storageType {
            case .fileSystem:
                if imageComparison(image1: image, isEqualTo: self.retrieveImage(forKey: key, inStorageType: .fileSystem) ?? UIImage()) {
                    //print("you already have this image saved...")
                } else {
                    //print("success saving image to file system")
                    if let filePath = filePath(forKey: key) {
                        do  {
                            if key == "userImage" {
                                //self.avitarImg = image
                            }
                            try pngRepresentation.write(to: filePath, options: .atomic)
                        } catch {  }
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
                    //self.avatarImg = image
                }
                return image
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
    
    func fetchTotalUserCount(completion: @escaping (Int) -> Void) {
        Database.database().reference().child("Users").observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }

    func fetchTotalQuickSnapCount(completion: @escaping (Int) -> Void) {
        Database.database().reference().child("Quick Snaps").observe(.value, with: {
            snapshot in
            let count = Int(snapshot.childrenCount)
            completion(count)
        })
    }

    // MARK: - Logout Firebase & Connectycube
    func logOutConnectyCube() {
//        Request.unregisterSubscription(forUniqueDeviceIdentifier: UIDevice.current.identifierForVendor!.uuidString, successBlock: nil)
        Request.logOut(successBlock: {
            self.verifyPhoneNumberStatus = .undefined
            self.profile.removeAllProfile()
            self.messages.removeAllMessages(completion: { _ in
                self.dialogs.removeAllDialogs()
                self.contacts.removeAllContacts()
                self.quickSnaps.removeAllQuickSnaps()
            })
        })

        Chat.instance.disconnect { _ in }
    }
    
    func logOutFirebase(completion: @escaping () -> Void) {
        let firebaseAuth = Auth.auth()
        self.preventDismissal = true
        do {
            try firebaseAuth.signOut()
            Database.database().reference().child("Users").removeAllObservers()
            self.isUserAuthenticated = .signedOut
            //self.configureFirebaseStateDidChange()
            UserDefaults.standard.set(0, forKey: "selectedWallpaper")
            
            completion()
        } catch {
            completion()
        }
    }
    
    func leaveDialog() {
        guard let dialog = self.selectedConnectyDialog, dialog.isJoined() else {
            return
        }

        dialog.sendUserStoppedTyping()
        dialog.leave { _ in }
    }
    
    func createTopFloater(alertType: String, message: String) -> some View {
        HStack() {
            Image(systemName: alertType == "error" ? "xmark.octagon" : alertType == "success" ? "checkmark.circle" : alertType == "bellOn" ? "bell.fill" : alertType == "bellOff" ? "bell.slash.fill" : alertType == "report" ? "exclamationmark.octagon.fill" : "bell.badge.fill")
                .resizable()
                .foregroundColor(alertType == "error" || alertType == "report" ? .red : alertType == "success" ? .green : .primary)
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
    
    public func sendPushNoti(userIDs: [NSNumber], title: String, message: String) {
        let event = Event()
        event.notificationType = .push
        event.usersIDs = userIDs
        event.type = .oneShot
        event.name = title

        var pushParameters = [String : String]()
        pushParameters["title"] = title
        pushParameters["message"] = message
        pushParameters["ios_sound"] = "app_sound.wav"

        if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
            let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)
            event.message = jsonString

            Request.createEvent(event, successBlock: { _ in })
        }
    }
    
//    func joinDialog(dialogModel: DialogStruct) {
//        let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]
//        Request.dialogs(with: Paginator.limit(100, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
//            for dialog in dialogs {
//                if dialog.id == dialogModel.id {
//                    self.selectedConnectyDialog = dialog
//                    
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
        UIApplication.shared.setAlternateIconName(name ?? nil) { _ in }
    }
}

//MARK: ChatDelegate
extension AuthModel: ChatDelegate {
    
    func chatDidConnect() {
        print("Chat did Connect!!! \(String(describing: Session.current.sessionDetails?.userID))")
        //self.connectionState = .connected
        delegateConnectionState?(.connected)
    }

    func chatDidReconnect() {
        print("Chat did Reconnect")
        //self.connectionState = .connected
        delegateConnectionState?(.connected)
    }

    func chatDidDisconnectWithError(_ error: Error) {
        //print("Chat did Disconnect: \(error.localizedDescription.description)")
        //self.connectionState = .disconnected
        delegateConnectionState?(.disconnected)
    }

    func chatDidNotConnectWithError(_ error: Error) {
        print("Chat did not connect: \(error.localizedDescription.description)")
        //self.connectionState = .disconnected
        self.configureFirebaseStateDidChange()

        delegateConnectionState?(.disconnected)
    }

    func chatDidReceiveContactAddRequest(fromUser userID: UInt) {
        self.profile.addContactRequest(userID: userID)
        
        print("chat did receive Contact Request userID: \(userID) & \(String(describing: self.profile.results.first?.contactRequests)) & \(String(describing: self.profile.results.first?.contactRequests.contains(Int(userID))))")
    }
    
    func chatDidReceiveAcceptContactRequest(fromUser userID: UInt) {
        self.contacts.updateSingleRealmContact(userID: Int(userID), completion: { _ in })
        self.profile.removeContactRequest(userID: userID)
    }
    
    func chatDidReceiveRejectContactRequest(fromUser userID: UInt) {
        print("chat did receive REJECTED Contact request! userID: \(userID)")

        self.profile.removeContactRequest(userID: userID)
    }
    
    func chatContactListDidChange(_ contactList: ContactList) {
        print("contact list did change: \(contactList.contacts.count)")

        if contactList.contacts.count > 0 {
            self.contacts.updateContacts(contactList: contactList.contacts, completion: { _ in })
        }
    }
    
    func chatDidReceiveContactItemActivity(_ userID: UInt, isOnline: Bool, status: String?) {
        self.contacts.updateContactOnlineStatus(userID: userID, isOnline: isOnline)
    }
    
    func chatDidDeliverMessage(withID messageID: String, dialogID: String, toUserID userID: UInt) {
        print("message delivered is: \(messageID) & to user: \(userID)")

        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let deliveredMessage = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageID) {
                try? realm.safeWrite {
                    deliveredMessage.messageState = .delivered
                    realm.add(deliveredMessage, update: .all)
                }
            }
        } catch {  }
    }
    
    func chatDidReadMessage(withID messageID: String, dialogID: String, readerID: UInt) {
        print("message read: \(messageID) & by user: \(readerID)")

        if readerID != UserDefaults.standard.integer(forKey: "currentUserID") {
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
            } catch {  }
        }
    }
    
    func chatDidReceive(_ message: ChatMessage) {
        print("received new message: \(String(describing: message.text)) from: \(message.senderID)")

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if UserDefaults.standard.bool(forKey: "localOpen") {
            if (!message.removed) {
                self.messages.insertMessage(message, completion: { })
                
                if message.senderID != UserDefaults.standard.integer(forKey: "currentUserID") {
                    Chat.instance.read(message) { _ in }
                }
            }
        } else {
            self.dialogs.fetchDialogs(completion: { _ in })
        }

        if (message.removed) {
            self.messages.updateMessageState(messageID: message.id ?? "", messageState: .deleted)
        } else if (message.edited) {
            self.messages.updateMessageState(messageID: message.id ?? "", messageState: .edited)
        } else if (message.delayed) {
            self.messages.updateMessageDelayState(messageID: message.id ?? "", messageDelayed: true)
        }
    }

    func chatRoomDidReceive(_ message: ChatMessage, fromDialogID dialogID: String) {
        print("received new GROUP message: \(String(describing: message.text)) for dialogID: \(dialogID)")

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        self.messages.updateMessageState(messageID: message.id ?? "", messageState: .delivered)

        if UserDefaults.standard.bool(forKey: "localOpen") {
            if (!message.removed) {
                Chat.instance.read(message) { (error) in
                    self.messages.insertMessage(message, completion: { })
                }
            }
        } else {
            self.dialogs.fetchDialogs(completion: { _ in })
        }

        if (message.removed) {
            self.messages.updateMessageState(messageID: message.id ?? "", messageState: .deleted)
        } else if (message.edited) {
            self.messages.updateMessageState(messageID: message.id ?? "", messageState: .edited)
        } else if (message.delayed) {
            self.messages.updateMessageDelayState(messageID: message.id ?? "", messageDelayed: true)
        }
    }
    
    func chatDidReceivePresence(withStatus status: String, fromUser userID: Int) {
        print("chatDidReceivePresence: \(status)")
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
