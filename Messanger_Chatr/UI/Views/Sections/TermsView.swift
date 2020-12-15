//
//  TermsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct TermsView: View {
    @State var mainText: String
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    VStack(alignment: .center) {
                        VStack {
                            Text(self.mainText)
                                .font(.none)
                                .fontWeight(.none)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    Spacer()
                    FooterInformation(middleText: "last updated: August 27, 2020")
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle("Terms", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
