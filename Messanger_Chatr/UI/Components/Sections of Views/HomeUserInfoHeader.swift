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
    @Environment(\.presentationMode) var presentationMode
    @Binding var showUserProfile: Bool
    @State var alertNum: Int = 0
    @State var profileImgSize = CGFloat(50)
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))

    var body: some View {
        //header section
        GeometryReader { geo in
             HStack {
                VStack(alignment: .leading) {
                    Text("Welcome Back,")
                        .font(.system(size: 16))
                        .foregroundColor(Color.secondary)
                        //.padding(.bottom, 1)
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
                        
                        Text(self.profile.results.first?.fullName ?? "Chatr Name")
                            .font(.system(size: 24))
                            .fontWeight(.medium)
                            .foregroundColor(Color.primary)
                    }.offset(y: UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") ? -3 : 0)

                }.offset(y: geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY + 60 : (geo.frame(in: .global).minY < 60 ? 60 : -geo.frame(in: .global).minY + 60))
                .onTapGesture {
                    self.showUserProfile.toggle()
                }

                Spacer()
                
                ProfileImage(size: self.$profileImgSize, alertCount: self.$alertNum)
                    .environmentObject(self.auth)
                    .offset(x: -8.25, y: -4)
                    .offset(y: geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY + 60 : (geo.frame(in: .global).minY < 60 ? 60 : -geo.frame(in: .global).minY + 60))
                    .onTapGesture { self.showUserProfile.toggle() }
                    .onAppear(){
                        self.alertNum = (self.auth.profile.results.first?.contactRequests.count ?? 0)
                    }
            }
        }
    }
}
