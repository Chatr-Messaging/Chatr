//
//  HighlightedContactCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/11/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct HighlightedContactCell: View {
    @Environment(\.presentationMode) var presentationMode
    @State var contact: ContactStruct = ContactStruct()
    @Binding var newMessage: Int
    @Binding var dismissView: Bool
    @Binding var selectedQuickSnapContact: ContactStruct
    @Binding var quickSnapViewState: QuickSnapViewingState
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    if let avitarURL = contact.avatar {
                        ZStack {
                            WebImage(url: URL(string: avitarURL))
                                .resizable()
                                .placeholder{ Image(systemName: "person.fill") }
                                .indicator(.activity)
                                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 35, height: 35, alignment: .center)
                                .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 5)
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 10, height: 10)
                                .foregroundColor(.green)
                                .opacity(contact.isOnline ? 1 : 0)
                                .offset(x: 12, y: 12)
                        }.padding(.horizontal)
                    } else {
                        ZStack {
                            Circle()
                                .frame(width: 25, height: 25, alignment: .center)
                                .foregroundColor(Color("bgColor"))

                            Text("".firstLeters(text: contact.fullName))
                                .font(.system(size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }.padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    if self.contact.isMyContact {
                        Button(action: {
                            print("Favourite tap")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if self.contact.isFavourite {
                                changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: false)
                            } else {
                                changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: true)
                            }
                        }) {
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14, alignment: .center)
                                .foregroundColor( self.contact.isFavourite ? .yellow : .secondary)
                                .shadow(color: Color.black.opacity(self.contact.isFavourite ? 0.15 : 0.0), radius: 2, x: 0, y: 2)
                        }.buttonStyle(ClickButtonStyle())
                        .padding(.horizontal)
                    }
                }
                
                HStack(spacing: 5) {
                    if self.contact.isPremium == true {
                        Image(systemName: "checkmark.seal")
                            .resizable()
                            .scaledToFit()
                            .font(Font.title.weight(.semibold))
                            .frame(width: 18, height: 18, alignment: .center)
                            .foregroundColor(Color("main_blue"))
                    }
                    
                    Text(contact.fullName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }.padding(.horizontal)
                
                Text(contact.isOnline ? "online now" : "online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                    .font(.caption)
                    .fontWeight(.none)
                    .padding(.horizontal)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.leading)
                    .offset(y: contact.isPremium ? -3 : 0)
                
                Spacer()
                
                HStack(alignment: .center, spacing: 20) {
                    Button(action: {
                        print("chat...")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        self.newMessage = self.contact.id
                        self.dismissView.toggle()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(.clear)
                                .background(Constants.purpleGradient)
                                .cornerRadius(10)
                                .shadow(color: Color(.sRGB, red: 44 / 255, green: 0 / 255, blue: 255 / 255, opacity: 0.35), radius: 8, x: 0, y: 5)
                            
                            Image("ChatBubble")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 29, height: 18, alignment: .center)
                                .foregroundColor(.primary)
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                .padding(3)
                        }
                    }.buttonStyle(ClickButtonStyle())
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        self.quickSnapViewState = .camera
                        self.selectedQuickSnapContact = self.contact
                        print("camera...")
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(.clear)
                                .background(Constants.quickSnapGradient)
                                .cornerRadius(10)
                                .shadow(color: Color(.sRGB, red: 255 / 255, green: 34 / 255, blue: 169 / 255, opacity: 0.35), radius: 8, x: 0, y: 5)

                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 21, height: 18, alignment: .center)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                .padding(3)
                        }
                    }.buttonStyle(ClickButtonStyle())
                }.frame(width: 160)
            }.padding(.all)
        }
    }
}
