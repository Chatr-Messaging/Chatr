//
//  AppDelegate.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 11/24/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseAuth
import FirebaseAnalytics
import FirebaseMessaging
import ConnectyCube
import RealmSwift
import CoreData
import PushKit
import Purchases

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [AnalyticsParameterStartDate: "timestamp: \(Date().timeIntervalSince1970)"])

        Settings.applicationID = 1087
        Settings.authKey = "dgcX9HyBrJrmfdJ"
        Settings.authSecret = "ercXbXPpwZ4pJJB"
        Settings.accountKey = "8bjqGu9RdW9ABQ8DF51h"
        Settings.disableFileLogging()
        Settings.disableXMPPLogging()
        
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: "vdUKfGbHolBECPkDCNFidOLFlPMykdTm", appUserID: "\(UserDefaults.standard.integer(forKey: "currentUserID"))")
        
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        self.voipRegistration()
        
        StoreReviewHelper.incrementAppOpenedCount()
        
        Messaging.messaging().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("chat instance did disconnect")
        Chat.instance.disconnect { (error) in
            print("chat instance did disconnect \(String(describing: error?.localizedDescription))")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("chat instance did disconnect")
        Chat.instance.disconnect { (error) in
            print("chat instance did disconnect \(String(describing: error?.localizedDescription))")
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("scene did enter background from AppDelegate")
        //PersistenceManager.shared.save()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("app will enter forground")
    }
    
    func application( _ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data ) {
        let subcription = Subscription()
        subcription.notificationChannel = .APNS
        subcription.deviceToken = deviceToken
        subcription.deviceUDID = UIDevice.current.identifierForVendor?.uuidString
        Request.createSubscription(subcription, successBlock: { (subscriptions) in
            print("created push subscription: \(subcription)")
        }) { (error) in
            print("Failed to create push subscription: \(error.localizedDescription)")
        }
        Purchases.shared.setPushToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Swift.Void) {
        if let info = userInfo["aps"] as? Dictionary<String, AnyObject> {
            if let alertMsg = info["alert"] as? String {
                if let sceneDelegate = application.connectedScenes.first?.delegate as? SceneDelegate {
                    if alertMsg.last == "❤️" || alertMsg.byWords.first == "snap" || alertMsg.byWords.last == "🥳" || alertMsg.byWords.last == "request" {
                        sceneDelegate.environment.notificationtext = alertMsg
                        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                    }
                }
            }
        }
    }
    
    private func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.sound, .badge, .banner])
        } else {
            // Fallback on earlier versions
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func voipRegistration() {
        let mainQueue = DispatchQueue.main
        // Create a push registry object
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceIdentifier: String = UIDevice.current.identifierForVendor!.uuidString
        let subscription: Subscription! = Subscription()
        subscription.notificationChannel = NotificationChannel.APNSVOIP
        subscription.deviceUDID = deviceIdentifier
        subscription.deviceToken = pushCredentials.token

        Request.createSubscription(subscription, successBlock: { (subscriptions) in
            print("created pushRegistry: \(subscriptions)")
        }) { (error) in

        }
    }
    
    private func pushRegistry(registry: PKPushRegistry!, didReceiveIncomingPushWithPayload payload: PKPushPayload!, forType type: String!) {
        print("RECEIVED PSUH REGISTRY: registry: \(String(describing: registry)) & payload: \(String(describing: payload)) & type: \(String(describing: type))")
    }
    
    private func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if let incomingURL = userActivity.webpageURL {
            print("have received incoming link!: \(incomingURL)")
            let linkHandled = DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL, completion: { (dynamicLink, error) in
                guard error == nil else {
                    print("found erre: \(String(describing: error?.localizedDescription))")
                    return
                }

                if let dynamicLink = dynamicLink {
                    self.handleIncomingDynamicLink(dynamicLink)
                }
            })
            if linkHandled {
                return true
            } else {
                return false
            }
        }
        return false
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
            self.handleIncomingDynamicLink(dynamicLink)

            return true
        } else {
            //some other url
            return false
        }
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
    }
}

