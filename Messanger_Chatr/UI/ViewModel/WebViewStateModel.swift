//
//  WebViewStateModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/2/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

class WebViewStateModel: ObservableObject {
    @Published var pageTitle: String = "Web View"
    @Published var loading: Bool = false
    @Published var canGoBack: Bool = false
    @Published var goBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var goForward: Bool = false
    @Published var reload: Bool = false
    @Published var websiteUrl: String = ""
}
