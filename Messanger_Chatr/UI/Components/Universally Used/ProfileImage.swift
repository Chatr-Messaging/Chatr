//
//  ProfileImage.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/15/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import RealmSwift

struct ProfileImage: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var size: CGFloat
    @Binding var alertCount: Int
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))

    var body: some View {
        ZStack {
            if let avatarURL = self.profile.results.first?.avatar {
                WebImage(url: URL(string: avatarURL))
                    .resizable()
                    .placeholder{ Image("empty-profile").resizable().frame(width: size, height: size, alignment: .center).scaledToFill() }
                    .indicator(.activity)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: size, height: size, alignment: .center)
                    .shadow(color: Color("buttonShadow_Deeper"), radius: 10, x: 0, y: 8)
            }
            
            ZStack(alignment: .center) {
                HStack {
                    Text(String(self.auth.profile.results.first?.contactRequests.count ?? 0))
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .font(.footnote)
                        .padding(.horizontal, 5)

                }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 5, x: 0, y: 5))
            }.offset(x: -(size * 0.35), y: -(size * 0.35))
            .opacity((self.auth.profile.results.first?.contactRequests.count ?? 0) > 0 ? 1 : 0)
        }
    }
}
