//
//  DiscoverView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State var searchText: String = ""
    @State var outputSearchText: String = ""
    @State var bannerDataArray: [DiscoverBannerData] = []
    @State var bannerCount: Int = 0
    @State var pageIndex: Int = 0
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack {
                
                //SEARCH BAR
                VStack {
                    HStack {
                        Text("SEARCH GROUP BY NAME:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Spacer()
                    }.padding(.top, 10)
                    .padding(.bottom, 2)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .padding(.leading, 15)
                            .foregroundColor(.secondary)
                        
                        TextField("Search", text: $searchText, onCommit: {
                            self.outputSearchText = self.searchText
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                            if allowOnlineSearch {
//                                self.grandSeach(searchText: self.outputSearchText)
//                            }
                        })
                        .padding(EdgeInsets(top: 16, leading: 5, bottom: 16, trailing: 10))
                        .foregroundColor(.primary)
                        .font(.system(size: 18))
                        .lineLimit(1)
                        .keyboardType(.webSearch)
                        .onChange(of: self.searchText) { value in
                            print("the value is: \(value)")
//                            if self.searchText.count >= 3 && self.allowOnlineSearch {
//                                self.grandSeach(searchText: self.searchText)
//                            } else {
//                                self.grandUsers.removeAll()
//                            }
                        }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                                self.outputSearchText = ""
                                //self.grandUsers.removeAll()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal, 15)
                        }
                        
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                }
                    .padding(.all)
                
                if self.bannerDataArray.count > 0 {
                    DiscoverCarousel(width: Constants.screenWidth, page: self.$pageIndex, dataArray: self.$bannerDataArray, dataArrayCount: self.$bannerCount, height: self.bannerDataArray.count > 0 ? 190 : 0)
                        .environmentObject(self.auth)
                        .frame(width: Constants.screenWidth, height: self.bannerDataArray.count > 0 ? 205 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                        .resignKeyboardOnDragGesture()
                    
                    if self.bannerDataArray.count > 1 {
                        DiscoverPageControl(page: self.$pageIndex, dataArrayCount: self.$bannerCount, color: colorScheme == .dark ? "white" : "black")
                            .frame(minWidth: 35, idealWidth: 50, maxWidth: 75)
                            .offset(y: -30)
                    }
                }
            }.onAppear {
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Apple Fanboy", memberCount: 18, catagory: "Technology", groupImg: "proPic", backgroundImg: "michaelAngelWallpaper", catagoryImg: "iphone.homebutton"))
                
                //DiscoverBannerData(titleBold: "Discover", title: "Channels", subtitleImage: "magnifyingglass", subtitle: "Join your favorite public groups", imageMain: "contactsBanner", gradientBG: "discoverBackground")
                
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, catagory: "Technology", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.bannerCount = self.bannerDataArray.count
            }
        }.resignKeyboardOnDragGesture()
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .foregroundColor(.primary)
            })
    }
}
