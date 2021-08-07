//
//  LockedOutView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import LocalAuthentication

struct LockedOutView: View {
    @EnvironmentObject var auth: AuthModel
    @State var lockedOutText: String = String()

    var body: some View {
        VStack(alignment: .center) {
            Text("Sorry,  you're \nlocked out")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding(.top, 50)
                .padding(.horizontal, 40)
            
            Text("Please use \(self.lockedOutText) to acsess \nyour Chatr account.")
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .padding(.top, 10)
                .padding(.bottom, 15)
                                
            Image("Locked Out")
                .resizable()
                .scaledToFit()
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                .padding(.horizontal, 5)

            
            HStack {
                Button(action: {
                    self.auth.preventDismissal = true
                    self.auth.isUserAuthenticated = .signedOut
                    self.auth.logOutFirebase(completion: {
                        self.auth.logOutConnectyCube()
                    })
                }) {
                    Text("Log Out")
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                }
                                        
                Button(action: {
                    let context = LAContext()
                    var error: NSError?

                    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                        let reason = "Identify yourself!"

                        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in

                            DispatchQueue.main.async {
                                if success {
                                    self.auth.isLoacalAuth = false
                                    ChatrApp.connect()
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
                }) {
                    HStack {
                        Image(systemName: self.lockedOutText == "Touch ID" ? "viewfinder.circle" : "faceid")
                            .resizable()
                            .frame(width: 25, height: 25, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.trailing, 5)
                        
                    Text(self.lockedOutText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .onAppear() {
                            switch(LAContext().biometryType) {
                            case .none:
                                self.lockedOutText = "Sign In"
                            case .touchID:
                                self.lockedOutText = "Touch ID"
                            case .faceID:
                                self.lockedOutText = "Face ID"
                            @unknown default:
                                print("unknown locked out method")
                            }
                        }
                    }
                }.buttonStyle(MainButtonStyle())
                .frame(height: 45)
                .frame(minWidth: 150, maxWidth: 200)
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                .padding()
            }.padding(.all, 25)
            
            Text("To disable this feature, please \ngo to Profile -> Security/Privacy.")
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
        }.frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
        .padding(.horizontal)
    }
}




