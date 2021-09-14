//
//  EmptyMessagesSection.swift
//  EmptyMessagesSection
//
//  Created by Brandon Shaw on 9/14/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct EmptyMessagesSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var messageCount: Int
    let bgColorBubble: LinearGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom)
    
    var body: some View {
        VStack(alignment: .center, spacing: 2.5) {
            Text("No Messages Sent")
                .font(.system(size: 26))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.top)
            
            Text("Start the conversation by \nsending a nice message")
                .font(.caption)
                .fontWeight(.none)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 10) {
                    HStack(alignment: .center, spacing: 6) {
                        Spacer()

                        Button(action: {
                            self.sendMessageEmptySection(text: "👋")
                        }) {
                            Text("👋")
                                .font(.body)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .transition(AnyTransition.scale)
                                .background(self.bgColorBubble)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                    .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 6)
                        }.buttonStyle(ClickButtonStyle())

                        Button(action: {
                            self.sendMessageEmptySection(text: "How are you?")
                        }) {
                            Text("How are you?")
                                .font(.body)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .transition(AnyTransition.scale)
                                .background(self.bgColorBubble)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 6)
                        }.buttonStyle(ClickButtonStyle())

                        Button(action: {
                            self.sendMessageEmptySection(text: "Whats up?")
                        }) {
                            Text("Whats up?")
                                .font(.body)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .transition(AnyTransition.scale)
                                .background(self.bgColorBubble)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 6)
                        }.buttonStyle(ClickButtonStyle())
                        
                        Spacer()
                    }
                    
                    
                    //Second row of options
                    HStack(alignment: .center, spacing: 6) {
                        Button(action: {
                            self.sendMessageEmptySection(text: "Where are you?")
                        }) {
                            Text("Where are you?")
                                .font(.body)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .transition(AnyTransition.scale)
                                .background(self.bgColorBubble)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 6)
                        }.buttonStyle(ClickButtonStyle())
                        
                        Button(action: {
                            self.sendMessageEmptySection(text: "What do you think?")
                        }) {
                            Text("What do you think?")
                                .font(.body)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 10)
                                .transition(AnyTransition.scale)
                                .background(self.bgColorBubble)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                .shadow(color: Color.blue.opacity(0.15), radius: 6, x: 0, y: 6)
                        }.buttonStyle(ClickButtonStyle())
                        
                    }
                }.padding(10)
            }
        }.frame(minWidth: 240, idealWidth: Constants.screenWidth * 0.7, maxWidth: Constants.screenWidth - 40)
        .background(BlurView(style: .systemThinMaterial))
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color("bgColor").opacity(0.5), lineWidth: 2.5))
    }
    
    func sendMessageEmptySection(text: String) {
        guard let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)

            return
        }
        
        changeMessageRealmData.shared.sendMessage(dialog: selectedDialog, text: text, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
        self.messageCount += 1
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}
