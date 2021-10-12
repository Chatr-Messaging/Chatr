//
//  FullNameView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

struct FullNameFieldView: UIViewRepresentable {
    typealias UIViewType = UITextField
    
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    var textField = UITextField()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        textField.delegate = context.coordinator
        textField.font = .systemFont(ofSize: 20)
        textField.keyboardType = .default
        textField.spellCheckingType = .no
        textField.autocorrectionType = .no
        textField.textAlignment = .center
        textField.autocapitalizationType = .words
        textField.backgroundColor = UIColor(named: "bgColor")
        textField.placeholder = "Full Name"
        textField.smartInsertDeleteType = UITextSmartInsertDeleteType.no

        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<FullNameFieldView>) {
        uiView.text = text
        if uiView.window != nil, isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
    }
    
    class Coordinator : NSObject, UITextFieldDelegate {
        var parent: FullNameFieldView
        var didBecomeFirstResponder = false

        init(_ uiTextField: FullNameFieldView) {
            self.parent = uiTextField
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
             guard let text = textField.text else { return }
             self.parent.text = text
        }
    }
}

