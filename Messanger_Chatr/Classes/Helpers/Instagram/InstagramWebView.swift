//
//  WebView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/9/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import WebKit
import FirebaseDatabase
import ConnectyCube

struct InstagramWebView: UIViewRepresentable {
        
    //MARK:- Member variables
    @Binding var presentAuth: Bool
        
    @Binding var instagramApi: InstagramApi
    
    //@Binding var testUserData: InstagramTestUser
    
    //MARK:- UIViewRepresentable Delegate Methods
    func makeCoordinator() -> InstagramWebView.Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<InstagramWebView>) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<InstagramWebView>) {
        instagramApi.authorizeApp { (url) in
            DispatchQueue.main.async {
                webView.load(URLRequest(url: url!))
            }
        }
    }
    
    //MARK:- Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: InstagramWebView
        
        init(parent: InstagramWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let request = navigationAction.request
            self.parent.instagramApi.getTestUserIDAndToken(request: request) { (instagramTestUser) in
                UserDefaults.standard.set(Int(instagramTestUser.user_id), forKey: "instagramID")
                UserDefaults.standard.set(instagramTestUser.access_token, forKey: "instagramAuthKey")
                Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["instagramAccessToken" : instagramTestUser.access_token])
                Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["instagramId" : instagramTestUser.user_id])
                //self.parent.testUserData = instagramTestUser
                self.parent.presentAuth = false
            }
            decisionHandler(WKNavigationActionPolicy.allow)
        }
                
    }
    
}

