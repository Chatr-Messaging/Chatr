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
    @State var logoutActionSheet: Bool = false

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
                .padding(.bottom)
                                    
            Button(action: {
                let context = LAContext()
                var error: NSError?

                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Identify yourself!") { success, _ in
                        DispatchQueue.main.async {
                            if success {
                                self.auth.isLocalAuth = false
                                ChatrApp.connect()
                            }
                        }
                    }
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
            .frame(minWidth: 180, maxWidth: 240)
            .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
            .padding()
            
            Button(action: {
                self.logoutActionSheet.toggle()
            }) {
                Text("Log Out")
                    .font(.body)
                    .foregroundColor(.red)
                    .padding()
            }.actionSheet(isPresented: self.$logoutActionSheet) {
                ActionSheet(title: Text("Are you sure you want to log out?"), message: nil, buttons: [
                    .destructive(Text("Log Out"), action: {
                        self.auth.preventDismissal = true
                        self.auth.isUserAuthenticated = .signedOut
                        self.auth.logOutFirebase(completion: {
                            self.auth.logOutConnectyCube()
                        })
                    }),
                    .cancel()
                ])
            }

            Text("To disable this feature, please \ngo to Profile -> Security/Privacy.")
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
            
        }.frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
        .background(Color("bgColor"))
        .padding(.horizontal)
    }
}




