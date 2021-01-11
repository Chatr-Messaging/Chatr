//
//  InstagramTestUser.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/9/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation

//MARK:- Instagram Users
struct InstagramTestUser: Codable {
    var access_token: String
    var user_id: Int
}

struct InstagramLongLiveUser: Codable {
    var access_token: String
    var token_type: String
    var expires_in: Int
}

struct InstagramUser: Codable {
    var id: String
    var username: String
}

//MARK:- Instagram Feed
struct Feed: Codable {
    var data: [MediaData]
    var paging : PagingData
}

struct MediaData: Codable {
    var id: String
    var caption: String?
}

struct PagingData: Codable {
    var cursors: CursorData
    var next: String
}

struct CursorData: Codable {
    var before: String
    var after: String
}

struct InstagramMedia: Codable {
      var id: String
      var media_type: MediaType
      var media_url: String
      var username: String
      var timestamp: String //"2017-08-31T18:10:00+0000"
    
    class igMedia {
        let id: UUID
        @Published var name: String = ""
        @Published var media_type: String = ""
        @Published var media_url: String = ""
        @Published var username: String = ""
        @Published var timestamp: String = ""
        
        init() {
            id = UUID()
        }
    }
}

enum MediaType: String,Codable {
    case IMAGE
    case VIDEO
    case CAROUSEL_ALBUM
}

