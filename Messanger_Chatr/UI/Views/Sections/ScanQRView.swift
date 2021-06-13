//
//  ScanQRView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/30/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVFoundation
import SwiftUI
import RealmSwift
import FirebaseDynamicLinks
import CarBode
import SDWebImageSwiftUI

struct ScanQRView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dimissView: Bool
    @State var torchIsOn = false
    @State var foundUser = false
    
    var body: some View {
        //MARK: Scan View
        ZStack(alignment: .center) {
            ZStack(alignment: .bottomTrailing) {
                CBScanner(supportBarcode: .constant([.qr, .code128]), torchLightIsOn: self.$torchIsOn, scanInterval: .constant(0.5)) {
                    if self.foundUser == false {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        self.foundUser = true
                        //print("BarCodeType =",$0.type.rawValue, "Value =",$0.value)
                        
                        //print("have received incoming link!: \(String(describing: $0.value))")
                        DynamicLinks.dynamicLinks().handleUniversalLink((URL(string: String(describing: $0.value)) ?? URL(string: ""))!, completion: { (dynamicLink, error) in
                            guard error == nil else {
                                print("found erre: \(String(describing: error?.localizedDescription))")
                                return
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.25) {
                                if let dynamicLink = dynamicLink {
                                    self.auth.handleIncomingDynamicLink(dynamicLink)
                                }
                            }
                        })
                    }
                }.frame(minWidth: 0, maxWidth: .infinity)
                .frame(minHeight: 0, maxHeight: .infinity)
                .foregroundColor(Color("bgColor"))
                
                HStack {
                    Button(action: {
                        self.torchIsOn.toggle()
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }) {
                        ZStack {
                            BlurView(style: .systemUltraThinMaterial)
                                .frame(width: 50, height: 50)
                                .cornerRadius(15)
                                .foregroundColor(Color("bgColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                            
                            Image(systemName: self.torchIsOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .frame(width: 25, height: 25, alignment: .center)
                        }
                    }.buttonStyle(ClickMiniButtonStyle())
                }.padding(.all, 10)
            }
            
            if self.foundUser {
                VStack {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55, alignment: .center)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                        .padding(.bottom, 10)
                    
                    Text("Found QR Code!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                        
                    Text("redirecting shortly...")
                        .font(.subheadline)
                        .fontWeight(.none)
                        .foregroundColor(.white)
                        .opacity(0.8)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                }.animation(.linear)
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.foundUser = false
                        withAnimation {
                            self.dimissView.toggle()
                        }
                    }
                }
            }
        }
    }
}

