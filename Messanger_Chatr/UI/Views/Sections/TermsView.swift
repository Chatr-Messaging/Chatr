//
//  TermsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MarkdownUI

struct TermsView: View {
    @State var markdown: Markdown
    @State var navTitle: String
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    VStack(alignment: .center) {
                        VStack {
                            self.markdown
                                .markdownStyle(
                                    DefaultMarkdownStyle(
                                        font: .system(.body, design: .default),
                                        codeFontName: "Menlo",
                                        codeFontSizeMultiple: 0.88
                                    )
                                )
                                .foregroundColor(.primary)
                                .padding()
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    Spacer()
                    FooterInformation(middleText: "last updated: October 05, 2021")
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle(self.navTitle, displayMode: .automatic)
            .navigationBarItems(trailing:
                                Menu {
                                    if self.navTitle != "EULA Agreement" {
                                        Button(action: {
                                            self.markdown = Constants.eulaMarkdown
                                            self.navTitle = "EULA Agreement"
                                        }) {
                                            Label("EULA Agreement", systemImage: "doc.text")
                                        }
                                    }
                                    
                                    if self.navTitle != "Privacy Policy" {
                                        Button(action: {
                                            self.markdown = Constants.privacyPolicyMarkdown
                                            self.navTitle = "Privacy Policy"
                                        }) {
                                            Label("Privacy Policy", systemImage: "doc.text")
                                        }
                                    }
                                    
                                    if self.navTitle != "Terms of Service" {
                                        Button(action: {
                                            self.markdown = Constants.termsOfServiceMarkdown
                                            self.navTitle = "Terms of Service"
                                        }) {
                                            Label("Terms of Service", systemImage: "doc.text")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "doc.text")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.blue)
                                        .frame(width: 22, height: 22)
                                }.buttonStyle(ClickButtonStyle())
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                }
            )
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
