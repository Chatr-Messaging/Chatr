//
//  Profile.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/7/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import UIKit
import ConnectyCube
import CoreData

struct ProfileModel {
    var id: Int
    var fullname: String
    var phoneNumber: String
    var photo: Data
}

class Profile: NSObject {
    override init() {
       super.init()
   }
   
   public func initiateInstance() {
    
   }
}
