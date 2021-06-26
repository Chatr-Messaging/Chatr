//
//  miniHeader.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct miniHeader: View {
    var title: String = ""
    var doubleIndent: Bool = true
    
    init(title: String, doubleIndent: Bool = true) {
        self.title = title
        self.doubleIndent = doubleIndent
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .padding(.horizontal, self.doubleIndent ? 40 : 20)
                .offset(y: 2)
            Spacer()
        }
    }
}
