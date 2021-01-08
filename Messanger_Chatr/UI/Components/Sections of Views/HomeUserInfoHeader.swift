//
//  HomeUserInfoHeader.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift

// MARK: Home Header Section
struct HomeHeaderSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var showUserProfile: Bool
    @State private var highlighted: Bool = false
    @State var alertNum: Int = 0
    @State var profileImgSize = CGFloat(50)

    var body: some View {
         HStack {
            VStack(alignment: .leading) {
                Text("Welcome Back,")
                    .font(.system(size: 16))
                    .foregroundColor(Color.secondary)
                    .offset(y: UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") ? 3 : 0)
                
                HStack(alignment: .center, spacing: 5) {
                    if UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") {
                        Image(systemName: "checkmark.seal")
                            .resizable()
                            .scaledToFit()
                            .font(Font.title.weight(.semibold))
                            .frame(width: 24, height: 24, alignment: .center)
                            .foregroundColor(Color("main_blue"))
                    }
                    
                    Text(self.auth.profile.results.first?.fullName ?? "Chatr Name")
                        .font(.system(size: 24))
                        .fontWeight(.medium)
                        .foregroundColor(Color.primary)
                }.offset(y: UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") ? -3 : 0)
            }

            Spacer()
            ProfileImage(size: self.$profileImgSize, alertCount: self.$alertNum)
                .environmentObject(self.auth)
                .onAppear(){
                    self.alertNum = (self.auth.profile.results.first?.contactRequests.count ?? 0)
                }
         }.contentShape(Rectangle())
         .padding(.horizontal, 5)
         .padding(.vertical, 10)
         .scaleEffect(self.highlighted ? 0.975 : 1.0)
         .background(RoundedRectangle(cornerRadius: 20).fill(self.highlighted ? Color("bgColor_light") : Color.clear).animation(.none))
         .animation(.spring(response: 0.1, dampingFraction: 0.75, blendDuration: 0))
         .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged({ _ in
                    self.highlighted = true
                })
                .onEnded({ value in
                    self.highlighted = false
                    if value.translation.width < 20 && value.translation.height < 20 {
                        self.showUserProfile.toggle()
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }
                }))
    }
}
