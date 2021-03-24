//
//  SceneDelegate.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 11/24/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI
import LocalAuthentication
import RealmSwift
import ConnectyCube
import Firebase
import Purchases

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var environment = AuthModel()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let contentView = HomeView().environmentObject(environment)
        
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            window.tintColor = UIColor(named: "bgColor_opposite")
            self.window = window
            window.makeKeyAndVisible()
        }

        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [AnalyticsParameterStartDate: "timestamp: \(Date().timeIntervalSince1970)"])

        Settings.applicationID = 1087
        Settings.authKey = "dgcX9HyBrJrmfdJ"
        Settings.authSecret = "ercXbXPpwZ4pJJB"
        Settings.accountKey = "8bjqGu9RdW9ABQ8DF51h"
        
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "vdUKfGbHolBECPkDCNFidOLFlPMykdTm", appUserID: "\(UserDefaults.standard.integer(forKey: "currentUserID"))")

        //guard let userActivity = connectionOptions.userActivities.first(where: { $0.webpageURL != nil }) else { return }
        //print("dynamic link url topppp: \(userActivity.webpageURL!)")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("scene did disconnect")
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let incomingURL = userActivity.webpageURL {
            print("have received incoming link!: \(incomingURL)")
            DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL, completion: { (dynamicLink, error) in
                guard error == nil else {
                    print("found erre: \(String(describing: error?.localizedDescription))")
                    return
                }
                if let dynamicLink = dynamicLink {
                    self.environment.handleIncomingDynamicLink(dynamicLink)
                }
            })
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("scene did become active")
        //if self.environment.isUserAuthenticated == .signedIn {
            //changeContactsRealmData.shared.updateContacts(contactList: Chat.instance.contactList?.contacts ?? [], completion: { _ in })
//            changeContactsRealmData.shared.observeQuickSnaps()
//            changeProfileRealmDate.shared.observeFirebaseUser()
            //ChatrApp.connect()
//            changeDialogRealmData.shared.fetchDialogs(completion: { _ in
//                changeContactsRealmData.shared.observeQuickSnaps()
//                changeProfileRealmDate.shared.observeFirebaseUser()
//                self.environment.initIAPurchase()
//            })
        //}
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("scene will resign active")
        if self.environment.isUserAuthenticated == .signedIn {
            if self.environment.profile.results.first?.isLocalAuthOn ?? false {
                self.environment.isLoacalAuth = true
            }
            if let dialog = self.environment.selectedConnectyDialog {
                dialog.sendUserStoppedTyping()
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("scene will enter foreground \(Thread.isMainThread)")

        self.environment.configureFirebaseStateDidChange()
        if self.environment.isUserAuthenticated == .signedIn {
            ChatrApp.connect()
            DispatchQueue.main.async {
                self.sendLocalAuth()
                UserDefaults.standard.set(Session.current.currentUserID, forKey: "currentUserID")
            }
        }

        DispatchQueue.main.async {
            StoreReviewHelper.incrementAppOpenedCount()
            StoreReviewHelper.checkAndAskForReview()
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        DispatchQueue.main.async {
            print("scene did enter background")
            if self.environment.isUserAuthenticated == .signedIn {
                var badgeNum: Int = 0
                if let dialog = self.environment.selectedConnectyDialog {
                    dialog.sendUserStoppedTyping()
                }
                Chat.instance.disconnect { (error) in
                    print("chat instance did disconnect \(String(describing: error?.localizedDescription))")
                }
                for dia in DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self)).results.filter({ $0.isDeleted != true }) {
                    badgeNum += dia.notificationCount
                }
                UIApplication.shared.applicationIconBadgeNumber = badgeNum + (self.environment.profile.results.first?.contactRequests.count ?? 0)
            }
        }
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    private func sendLocalAuth() {
        print("Scene AppDelegate Used")
        if self.environment.profile.results.first?.isLocalAuthOn ?? false {
            print("Scene AppDelegate - Realm True")
            self.environment.isLoacalAuth = true
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Identify yourself!"
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    
                    DispatchQueue.main.async {
                        if success {
                            self.environment.isLoacalAuth = false
                        } else {
                            // error
                            print("error! logging in")
                        }
                    }
                }
            } else {
                // no biometry
                print("error with biometry!")
            }
        }
    }
}

