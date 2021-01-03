//
//  StoreReviewHelper.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/3/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import StoreKit

struct StoreReviewHelper {
    static func incrementAppOpenedCount() { // called from appdelegate didfinishLaunchingWithOptions:
        guard var appOpenCount = UserDefaults.standard.value(forKey: "APP_OPENED_COUNT") as? Int else {
            UserDefaults.standard.set(1, forKey: "APP_OPENED_COUNT")
            return
        }
        appOpenCount += 1
        UserDefaults.standard.set(appOpenCount, forKey: "APP_OPENED_COUNT")
    }

    static func checkAndAskForReview() {
        // this will not be shown everytime. Apple has some internal logic on how to show this.
        guard let appOpenCount = UserDefaults.standard.value(forKey: "APP_OPENED_COUNT") as? Int else {
            UserDefaults.standard.set(1, forKey: "APP_OPENED_COUNT")
            return
        }
        print("App run count is: \(appOpenCount)")

        switch appOpenCount {
        case 5, 50:
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                StoreReviewHelper.requestReview()
            }
        case _ where appOpenCount % 100 == 0 :
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                StoreReviewHelper.requestReview()
            }
        default:
            //print("App run count is: \(appOpenCount)")
            break;
        }
        
    }

    static func requestReview() {
        if #available(iOS 10.3, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else if let url = URL(string: "itms-apps://itunes.apple.com/app/" + "1531056110") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
