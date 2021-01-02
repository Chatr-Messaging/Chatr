//
//  AboutChatrView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/14/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct AboutChatrView: View {
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    //MARK: Personal Privacy Section
                    HStack {
                        Text("Social:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        VStack {
                            
                            //Twitter Section
                            VStack(alignment: .leading) {
                                Button(action: {
                                    //add to fav button
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    let screenName = "ChatrMessaging"
                                    let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
                                    let webURL = NSURL(string: "https://twitter.com/\(screenName)")!
                                    let application = UIApplication.shared

                                    if application.canOpenURL(appURL as URL) {
                                         application.open(appURL as URL)
                                    } else {
                                         application.open(webURL as URL)
                                    }
                                    
                                }) {
                                    HStack(alignment: .center) {
                                        Image("twitterIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.primary)
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(.trailing, 5)
                                        
                                        Text("@ChatrMessaging")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                                    .offset(x: 50)
                            }.padding(.bottom, 5)
                            
                            //Website Section
                            VStack(alignment: .leading) {
                                Button(action: {
                                    //add to fav button
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    UIApplication.shared.open(URL(string: "https://www.chatr-messaging.com/")!)
                                }) {
                                    HStack(alignment: .center) {
                                        Image(systemName: "safari")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.secondary)
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(.trailing, 5)
                                        
                                        Text("chatr-messaging.com")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    HStack(alignment: .center) {
                        Text("for immediate assistance please \nsend an email found on our website")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }.padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    FooterInformation()
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle("About", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
