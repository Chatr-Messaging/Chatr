//
//  EditProfileViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/10/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube

class EditProfileViewModel: ObservableObject {
    @Published var inputImage: UIImage? = nil

    private let instagramApi = InstagramApi.shared
    
    var testUserData: InstagramTestUser {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let foundContact = realm.object(ofType: ProfileStruct.self, forPrimaryKey: Session.current.currentUserID) {
                return InstagramTestUser(access_token: foundContact.instagramAccessToken, user_id: foundContact.instagramId)
            }
        } catch {
            print(error.localizedDescription)
            return InstagramTestUser(access_token: "", user_id: 0)
        }
        return InstagramTestUser(access_token: "", user_id: 0)
    }
    
    func pullInstagramUser(completion: @escaping (String) -> ()) {
        self.instagramApi.getInstagramUser(testUserData: self.testUserData) { (user) in
            completion(user.username)
        }
    }
    
    func pullInstagramUserFromDefaults(completion: @escaping (String) -> ()) {
        self.instagramApi.getInstagramUser(testUserData: InstagramTestUser(access_token: UserDefaults.standard.string(forKey: "instagramAuthKey") ?? "", user_id: UserDefaults.standard.integer(forKey: "instagramID"))) { (user) in
            completion(user.username)
        }
    }

    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center) {
            VStack(spacing: 0) {
                content()
            }.padding(.vertical, 10)
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
}
