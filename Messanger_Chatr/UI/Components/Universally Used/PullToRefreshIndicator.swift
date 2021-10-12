//
//  PullToRefreshIndicator.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct PullToRefreshIndicator: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isLoading: Bool
    @Binding var preLoading: Bool
    @Binding var localOpen: Bool
    @State var startLocation: CGFloat = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if geometry.frame(in: .global).minY > self.startLocation || self.isLoading && !self.localOpen {
                    Circle()
                        .trim(from: 0, to: geometry.frame(in: .global).minY > self.startLocation + 50 || self.isLoading ? 0.8 : (geometry.frame(in: .global).minY - self.startLocation) / 62.5)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 25, height: 25)
                        .frame(maxWidth: Constants.screenWidth, alignment: .center)
                        .rotationEffect(.degrees(self.isLoading ? 360 : 0))
                        .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                        .opacity(self.preLoading ? self.isLoading && !self.localOpen ? 1 : Double((geometry.frame(in: .global).minY - self.startLocation) / 5) : 0)
                        .scaleEffect(self.isLoading ? 1 : geometry.frame(in: .global).minY / self.startLocation + 50)
                        .padding(.bottom, 75)
                        //.offset(y: -geometry.frame(in: .global).minY + 158)
                        .onAppear {
                            //self.preLoading = true
                            if self.startLocation == .zero {
                                self.startLocation = geometry.frame(in: .global).minY
                            }
                            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                        }
                }
//                if geometry.frame(in: .global).minY > self.startLocation + 50 && !self.localOpen && self.startLocation != .zero {
//                    Text("")
//                        .onAppear {
//                            if self.isLoading != true {
//                                self.isLoading = true
//                                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
//                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                                self.auth.dialogs.fetchDialogs(completion: { result in
//                                    print("pull to refresh is at: \(geometry.frame(in: .global).minY)")
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
//                                        self.isLoading = false
//                                    }
//                                })
//                            }
//                        }
//                }
            }.onAppear {
                if self.startLocation == .zero {
                    self.startLocation = geometry.frame(in: .global).minY
                    self.preLoading = true
                }
            }
        }.animation(nil)
    }
}
