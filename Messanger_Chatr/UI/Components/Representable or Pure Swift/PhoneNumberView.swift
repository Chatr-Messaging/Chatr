//
//  PhoneNumberView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/4/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import Foundation
import PhoneNumberKit
import Combine
import SwiftUI
import CoreTelephony

struct PhoneNumberTextFieldView: UIViewRepresentable {
    typealias UIViewType = PhoneNumberTextField
    
    @Binding var text: String
    @Binding var isFirstResponder: Bool
    @Binding var doneSuccess: Bool

    var textField: PhoneNumberTextField = MyLocalTextField()
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PhoneNumberTextField {
        self.textField.delegate = context.coordinator
        self.textField.font = .systemFont(ofSize: 20)
        self.textField.withPrefix = false
        self.textField.withFlag = false
        self.textField.withExamplePlaceholder = true
        self.textField.textColor = UIColor(named: "textColor")
        self.textField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        self.textField.textAlignment = .left
        self.textField.addTarget(context.coordinator, action: #selector(context.coordinator.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        return self.textField
    }
    
    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                uiView.becomeFirstResponder()
                context.coordinator.didBecomeFirstResponder = true
            }
        }
    }
    
//    func makeUIViewController(context: Context) -> PhoneNumberTextField {
//
////        textField.delegate = context.coordinator
////        textField.font = .systemFont(ofSize: 20)
////        textField.keyboardType = .numberPad
////        textField.textAlignment = .center
////        textField.backgroundColor = UIColor(named: "bgColor")
////        textField.placeholder = "(123) 456-7890"
////        textField.textColor = UIColor(named: "textColor")
////        textField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
//
//        /*
//         self.otpView.otpEnteredString = { pin in
//              print("The entered pin is \(pin)")
//              self.auth.checkSecurityCode(securityCode: pin)
//         }
//        */
//
//        let controller = SomeCustomeUIViewController()
//        controller.textField.delegate = context.coordinator
//
//        return controller
//    }
//
//    func updateUIViewController(_ someViewController: SomeCustomeUIViewController, context: Context) {
////        uiView.text = text
//
//        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
//                someViewController.textField.becomeFirstResponder()
//                context.coordinator.didBecomeFirstResponder = true
//            }
//        }
//    }
    
    class Coordinator : NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextFieldView
        var didBecomeFirstResponder = false
        var doneSuccess = false
                
        init(_ parent: PhoneNumberTextFieldView) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ textField: UITextField) {
            guard let text = textField.text else { return }
            
            if text.count <= 9 {
                self.doneSuccess = true
            } else {
                self.doneSuccess = false
            }
            
            self.parent.text = text
        }
    }
}

extension String {
    func format(phoneNumber: String, shouldRemoveLastDigit: Bool = false) -> String {
        guard !phoneNumber.isEmpty else { return "" }
        guard let regex = try? NSRegularExpression(pattern: "[\\s-\\(\\)]", options: .caseInsensitive) else { return "" }
        let r = NSString(string: phoneNumber).range(of: phoneNumber)
        var number = regex.stringByReplacingMatches(in: phoneNumber, options: .init(rawValue: 0), range: r, withTemplate: "")

        if number.count > 10 {
            let tenthDigitIndex = number.index(number.startIndex, offsetBy: 10)
            number = String(number[number.startIndex..<tenthDigitIndex])
        }

        if shouldRemoveLastDigit {
            let end = number.index(number.startIndex, offsetBy: number.count-1)
            number = String(number[number.startIndex..<end])
        }

        if number.count < 7 {
            let end = number.index(number.startIndex, offsetBy: number.count)
            let range = number.startIndex..<end
            number = number.replacingOccurrences(of: "(\\d{3})(\\d+)", with: "($1) $2", options: .regularExpression, range: range)

        } else {
            let end = number.index(number.startIndex, offsetBy: number.count)
            let range = number.startIndex..<end
            number = number.replacingOccurrences(of: "(\\d{3})(\\d{3})(\\d+)", with: "($1) $2-$3", options: .regularExpression, range: range)
        }

        return number
    }
    
    func applyPatternOnNumbers(pattern: String, replacmentCharacter: Character) -> String {
        var pureNumber = self.replacingOccurrences( of: "[^0-9]", with: "", options: .regularExpression)
        for index in 0 ..< pattern.count {
            guard index < pureNumber.count else { return pureNumber }
            let stringIndex = String.Index(utf16Offset: index, in: self)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacmentCharacter else { continue }
            pureNumber.insert(patternCharacter, at: stringIndex)
        }
        return pureNumber
    }
}

class SomeCustomeUIViewController: UIViewController {
    var textField: PhoneNumberTextField = MyLocalTextField()
    @EnvironmentObject var auth: AuthModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "bgColor")
        
//        self.textFieldArea = UITextField(frame: CGRect(x: 5, y: 0, width: 80, height: 60))
//        self.textFieldArea.textColor = UIColor(named: "textColor")
//        self.textFieldArea.text = "+1"
//        self.textFieldArea.placeholder = "+1"
//        self.textFieldArea.font = .systemFont(ofSize: 24)
//        self.textFieldArea.smartInsertDeleteType = UITextSmartInsertDeleteType.no
//        self.textFieldArea.textAlignment = .center
//        self.view.addSubview(textFieldArea)

        //self.textField = MyLocalTextField(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 195, height: 50))
        self.textField.frame = CGRect(x: 20, y: 0, width: UIScreen.main.bounds.width - 195, height: 50)
        self.textField.font = .systemFont(ofSize: 20)
        self.textField.withPrefix = false
        self.textField.withFlag = false
        self.textField.withExamplePlaceholder = true
        //self.textField.placeholder = "enter phone number"
        //self.textField.currentRegion = carrier?.first?.value.isoCountryCode?.uppercased() ?? "US"
        self.textField.textColor = UIColor(named: "textColor")
        self.textField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        self.textField.textAlignment = .left
        //self.textField.delegate = self as? UITextFieldDelegate
        //self.textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        self.view.addSubview(self.textField)
        
        print("default regin is: \(self.textField.defaultRegion)")
    }
    
    @objc func textFieldDidChange(_ textField2: PhoneNumberTextField) {
//        self.checkMaxLength(textField: textField2, maxLength: 18)
//        if textField2.text!.count >= 17 {
//            self.view.endEditing(true)
//            if let textPhoneNumber = textField2.text {
//                self.auth.sendVerificationNumber(numberText: textPhoneNumber)
//            }
//        }
    }
    
    func checkMaxLength(textField: UITextField!, maxLength: Int) {
        if (textField.text!.count) > maxLength {
            textField.deleteBackward()
        }
    }
    
    func textField(_ textField: PhoneNumberTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 17
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDissapear \(self)")
    }

    deinit {
        print("DEINIT \(self)")
    }
}

class MyLocalTextField: PhoneNumberTextField {
    let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders
    
    override var defaultRegion: String {
        get {
            return carrier?.first?.value.isoCountryCode?.uppercased() ?? "US"
        }
        set {} // exists for backward compatibility
    }
}
