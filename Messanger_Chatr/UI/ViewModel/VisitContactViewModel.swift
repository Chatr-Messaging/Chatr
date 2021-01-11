//
//  VisitContactViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/11/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine

class VisitContactViewModel: ObservableObject {
    private let instagramApi = InstagramApi.shared
    private var cancellables = Set<AnyCancellable>()
    @Published var igStrings: [String] = []
    @Published var username: String = ""
    
    //@Published var selectedUrl = "https://i.picsum.photos/id/646/200/200.jpg?hmac=3jbia15y-hA5gmqVJjmk6BPJiisi4j-fNKPi3iXRiRo"
    init() {
        instagramApi.$igStrings
            .assign(to: \.igStrings, on: self)
            .store(in: &cancellables)
        
        instagramApi.$username
            .assign(to: \.username, on: self)
            .store(in: &cancellables)
    }
    
    func loadInstagramImages(testUser: InstagramTestUser) {
        if testUser.user_id != 0 && testUser.access_token != "" {
            self.instagramApi.pullInstagramImages(testUser: testUser)
        }
    }
    
    func pullInstagramUser(testUser: InstagramTestUser, completion: @escaping (String) -> ()) {
        self.instagramApi.getInstagramUser(testUserData: testUser) { (user) in
            completion(user.username)
        }
    }
}
