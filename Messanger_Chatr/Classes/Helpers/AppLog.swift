//
//  AppLog.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 11/15/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation

public func print(_ output: Any) {
    #if DEBUG
    Swift.print(output)
    #endif
}

public func print(_ output: Any...) {
    #if DEBUG
    for item in output {
        Swift.print(item)
    }
    #endif
}
