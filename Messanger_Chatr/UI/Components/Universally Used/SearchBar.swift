//
//  SearchBar.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct CustomSearchBar: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var searchText: String
    @Binding var localOpen: Bool

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.leading, 5)
                
                TextField("Search", text: $searchText)
                    .foregroundColor(.primary)
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .keyboardType(.webSearch)
                    .padding(.vertical, 2)
                
                if !searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }.padding(EdgeInsets(top: 10, leading: 8, bottom: 10, trailing: 10))
            .foregroundColor(.secondary)
            .background(Color("buttonColor"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.top, 20)
            .animation(.linear(duration: 0.2))
        }.padding(.horizontal)
    }
}
