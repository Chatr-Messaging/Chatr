//
//  WebView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/9/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
        
    //MARK:- Member variables
    @Binding var presentAuth: Bool
    
    @Binding var testUserData: InstagramTestUser
    
    @Binding var instagramApi: InstagramApi
    
    //MARK:- UIViewRepresentable Delegate Methods
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        instagramApi.authorizeApp { (url) in
            DispatchQueue.main.async {
                webView.load(URLRequest(url: url!))
            }
        }
    }
    
    //MARK:- Coordinator class
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let request = navigationAction.request
            self.parent.instagramApi.getTestUserIDAndToken(request: request) { (instagramTestUser) in
                UserDefaults.standard.set(Int(instagramTestUser.user_id), forKey: "instagramID")
                UserDefaults.standard.set(instagramTestUser.access_token, forKey: "instagramAuthKey")
                self.parent.testUserData = instagramTestUser
                self.parent.presentAuth = false
            }
            decisionHandler(WKNavigationActionPolicy.allow)
        }
                
    }
    
}

