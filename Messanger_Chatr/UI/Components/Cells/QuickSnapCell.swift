//
//  QuickSnapCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/31/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import RealmSwift

struct QuickSnapCell: View {
    @Binding var viewState: QuickSnapViewingState
    @State var quickSnap: ContactStruct = ContactStruct()
    @Binding var selectedQuickSnapContact: ContactStruct 

    var body: some View {
        VStack {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                self.selectedQuickSnapContact = self.quickSnap
                self.viewState = self.selectedQuickSnapContact.quickSnaps.count > 0 ? .viewing : .camera
            }) {
                ZStack(alignment: .center) {
                    if self.quickSnap.quickSnaps.count > 0 {
                        Circle()
                            .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: Constants.quickSnapBtnSize + 8, height: Constants.quickSnapBtnSize + 8)
                            .frame(maxWidth: Constants.screenWidth, alignment: .center)
                            .foregroundColor(.clear)
                            .background(Color.clear)
                    }
                    
                    if let avitarURL = quickSnap.avatar, avitarURL != "" {
                        WebImage(url: URL(string: avitarURL))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: Constants.quickSnapBtnSize, height: Constants.quickSnapBtnSize, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.01)), removal: AnyTransition.identity))
                            .scaledToFill()
                            .frame(width: Constants.quickSnapBtnSize, height: Constants.quickSnapBtnSize, alignment: .center)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 6)
                    } else {
                        Circle()
                            .frame(width: Constants.quickSnapBtnSize, height: Constants.quickSnapBtnSize, alignment: .center)
                            .foregroundColor(Color("emptyProfileBG_0"))

                        Text("".firstLeters(text: quickSnap.fullName))
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                    
                    if self.quickSnap.quickSnaps.count == 0 {
                        Circle()
                            .frame(width: Constants.quickSnapBtnSize, height: Constants.quickSnapBtnSize, alignment: .center)
                            .foregroundColor(.black)
                            .opacity(0.35)
                        
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 22, alignment: .center)
                            .foregroundColor(.white)
                            .opacity(0.75)
                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    }
                    
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: 10, height: 10)
                        .foregroundColor(.green)
                        .overlay(Circle().stroke(Color("bgColor"), lineWidth: 2))
                        .opacity(quickSnap.isOnline ? 1 : 0)
                        .offset(x: 19, y: 19)
                    
                    Image(systemName: "star.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .foregroundColor(.yellow)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(7.5)
                        .opacity(quickSnap.isFavourite ? 1 : 0)
                        .offset(x: -20, y: 20)
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                }.scaleEffect(UserDefaults.standard.bool(forKey: "localOpen") ? 0.85 : 1)
            }.buttonStyle(ClickButtonStyle())
            .offset(y: 1)
            
            Text(self.quickSnap.fullName.components(separatedBy: " ").first ?? " ")
                .font(.caption)
                .fontWeight(.none)
                .foregroundColor(.secondary)
                .frame(minWidth: Constants.quickSnapBtnSize + 20, maxWidth: Constants.quickSnapBtnSize + 25)
                .padding(.top, UserDefaults.standard.bool(forKey: "localOpen") ? 0 : 3)
                .offset(y: self.quickSnap.quickSnaps.count > 0 ? -8 : 0)
        }.frame(height: UserDefaults.standard.bool(forKey: "localOpen") ? 70 * 0.85 : 70)
        .offset(y: UserDefaults.standard.bool(forKey: "localOpen") ? (UIDevice.current.hasNotch ? 5 : 0) : 0)
    }
}
