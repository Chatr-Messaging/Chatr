//
//  VerifyCodeView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/12/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

struct VerifyCodeTextFieldView: UIViewRepresentable {
    typealias UIViewType = UITextField
    
    @EnvironmentObject var auth: AuthModel
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    var textField = UITextField()

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 22, weight: .medium)
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.backgroundColor = UIColor(named: "bgColor")
        textField.placeholder = "enter 6 diget code"
        textField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        textField.defaultTextAttributes.updateValue(20, forKey: NSAttributedString.Key.kern)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<VerifyCodeTextFieldView>) {
        uiView.text = text
        if uiView.window != nil, isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        } else {
            context.coordinator.didBecomeFirstResponder = false
        }
    }
    
    class Coordinator : NSObject, UITextFieldDelegate {
        var parent: VerifyCodeTextFieldView
        var didBecomeFirstResponder = false

        init(_ uiTextField: VerifyCodeTextFieldView) {
            self.parent = uiTextField
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            if textField.text!.count >= 6 && self.parent.auth.verifyCodeStatus != .loading {
                UIApplication.shared.endEditing(true)
                self.parent.auth.checkSecurityCode(securityCode: textField.text ?? "") { _ in }
            }
        }
    }
}
