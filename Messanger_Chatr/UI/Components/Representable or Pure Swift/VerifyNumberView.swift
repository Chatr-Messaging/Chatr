//
//  VerifyNumberView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/4/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import Foundation
import SwiftUI
import SROTPView

struct VerifyNumberViewController: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> VerifyUIViewController {
        let vc =  VerifyUIViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: VerifyUIViewController, context: Context) {
        //print("updateUIViewController \(uiViewController)")
    }
}

class VerifyUIViewController: UIViewController {
    var otpView: SROTPView = SROTPView()
    var authM: AuthModel = AuthModel()

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
        //view.backgroundColor = UIColor(named: "bgColor")
        
        self.otpView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.otpView.otpTextFieldsCount = 6
        self.otpView.otpTextFieldActiveBorderColor = UIColor(named: "textColor")!
        self.otpView.otpTextFieldDefaultBorderColor = UIColor(named: "textColor")!
        self.otpView.otpTextFieldFontColor = UIColor(named: "textColor")!
        //self.otpView.cursorColor = UIColor(named: "textColor")!
        //self.otpView.otpTextFieldBorderWidth = 2
        // self.otpView.becomeFirstResponder()
        self.otpView.otpEnteredString = { _ in
            //self.authM.checkSecurityCode(securityCode: pin)
        }
        self.view.addSubview(self.otpView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        otpView.initializeUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.otpView.removeFromSuperview()
    }

    deinit {
        //print("DEINIT \(self)")
    }
}
