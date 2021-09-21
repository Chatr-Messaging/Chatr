//
//  AppearanceView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Grid

struct AppIconData: Identifiable {
    var id = UUID()
    var title: String
    var image: String
    var selected: Bool
}

struct WallpaperData: Identifiable {
    var id = UUID()
    var title: String
    var image: String
    var selected: Bool
    var isPremium: Bool
}

// MARK: Appeacrace Section
struct appearanceView: View {
    @EnvironmentObject var auth: AuthModel
    @State var openMenbership: Bool = false
    @State var selectedIcon: AppIconData? = nil
    @State var selectedWallpaper: WallpaperData? = nil
    @State var style = StaggeredGridStyle(.vertical, tracks: .count(2), spacing: 2.5)

    var AppIconDataArray : [AppIconData] = [
        AppIconData(title: "Original", image: "AppIcon-Original", selected: false),
        AppIconData(title: "Original Dark", image: "AppIcon-Original-Dark", selected: false),
        AppIconData(title: "Flat", image: "AppIcon-Flat", selected: false),
        AppIconData(title: "Flat Dark", image: "AppIcon-Flat-Dark", selected: false),
        AppIconData(title: "Paper Airplane", image: "AppIcon-PaperAirplane", selected: false),
        AppIconData(title: "Paper Airplane Dark", image: "AppIcon-PaperAirplane-Dark", selected: false),
        AppIconData(title: "Colorful", image: "AppIcon-Colorful", selected: false),
        AppIconData(title: "Colorful Dark", image: "AppIcon-Colorful-Dark", selected: false)
    ]
    var WallpaperDataArray : [WallpaperData] = [
        WallpaperData(title: "Empty", image: "", selected: false, isPremium: false),
        WallpaperData(title: "Chat Bubbles", image: "SoftChatBubbles_DarkWallpaper", selected: false, isPremium: false),
        WallpaperData(title: "Paper Airplanes", image: "SoftPaperAirplane-Wallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Night Sky", image: "oldHouseWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "New York City", image: "nycWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Michael Angelo", image: "michaelAngelWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Moon", image: "moonWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Patagonia", image: "patagoniaWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Ocean Rocks", image: "oceanRocksWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "South Africa", image: "southAfricaWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Flowers", image: "flowerWallpaper", selected: false, isPremium: true),
        WallpaperData(title: "Paint", image: "paintWallpaper", selected: false, isPremium: true)
    ]
    
    let wallpaperLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    
                    //MARK: Icon Section
                    HStack {
                        Text("ICONS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        Grid(self.AppIconDataArray) { item in
                            Button(action: {
                                if self.auth.subscriptionStatus == .subscribed || item.title == self.AppIconDataArray.first?.title || (item.title == "Original Dark" && UserDefaults.standard.bool(forKey: "isEarlyAdopter")) {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.selectedIcon = item
                                    UserDefaults.standard.set(item.title, forKey: "selectedAppIcon")
                                    self.auth.changeHomeIconTo(name: self.selectedIcon?.image == "AppIcon-Original" ? nil : self.selectedIcon?.image)
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    self.openMenbership.toggle()
                                }
                            }, label: {
                                VStack(alignment: .center) {
                                    Image("\(item.image)")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 55, height: 55, alignment: .center)
                                        .cornerRadius(15)
                                        .padding(.bottom, 5)
                                        .shadow(color: Color("buttonShadow"), radius: 5, x: 0, y: 5)

                                    if self.auth.subscriptionStatus == .subscribed || item.title == "Original" || (item.title == "Original Dark" && UserDefaults.standard.bool(forKey: "isEarlyAdopter")) {
                                        if self.selectedIcon?.title == item.title {
                                            Image(systemName: "checkmark.circle.fill" )
                                                .resizable()
                                                .scaledToFill()
                                                .foregroundColor(.blue)
                                                .frame(width: 20, height: 20)
                                        } else {
                                            Image(systemName: "circle")
                                                .resizable()
                                                .scaledToFill()
                                                .foregroundColor(.secondary)
                                                .frame(width: 20, height: 20)
                                        }
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(.secondary)
                                            .frame(width: 16, height: 16)
                                    }

                                    Text(item.title)
                                        .font(.subheadline)
                                        .fontWeight(.none)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 25)
                            })
                            .background(RoundedRectangle(cornerRadius: 15).fill(self.selectedIcon?.title == item.title ? Color("bgColor_light") : Color.clear).animation(.none))
                            .buttonStyle(ClickMiniButtonStyleBG())

                        }.frame(minHeight: 520, maxHeight: 620, alignment: .center)
                        .padding(.vertical, 15)
                        .gridStyle(self.style)
                        .onAppear {
                            if self.auth.subscriptionStatus == .subscribed || UserDefaults.standard.bool(forKey: "isEarlyAdopter") {
                                self.selectedIcon = self.AppIconDataArray.filter({ $0.title == UserDefaults.standard.string(forKey: "selectedAppIcon") }).first ?? self.AppIconDataArray[0]
                            } else {
                                self.selectedIcon = self.AppIconDataArray[0]
                            }
                        }.sheet(isPresented: self.$openMenbership, content: {
                            MembershipView()
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                                .navigationBarTitle("")
                        })

                        /*
                        VStack {
                            ForEach(self.AppIconDataArray.indices, id:\.self) { results in
                                VStack {
                                    HStack {
                                        Image(self.AppIconDataArray[results].image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 55, height: 55, alignment: .center)
                                            .cornerRadius(15)
                                            .shadow(color: Color("buttonShadow"), radius: 5, x: 0, y: 5)
                                            .padding(.trailing, 5)
                                            .padding(.vertical, 3)
                                        
                                        Text(self.AppIconDataArray[results].title)
                                            .font(.subheadline)
                                            .fontWeight(.none)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        if self.auth.subscriptionStatus == .subscribed || self.AppIconDataArray[results].title == "Original" || (self.AppIconDataArray[results].title == "Original Dark" && UserDefaults.standard.bool(forKey: "isEarlyAdopter")) {
                                            if self.selectedIcon?.title == self.AppIconDataArray[results].title {
                                                Image(systemName: "checkmark.circle.fill" )
                                                    .resizable()
                                                    .scaledToFill()
                                                    .foregroundColor(.blue)
                                                    .frame(width: 20, height: 20)
                                            } else {
                                                Image(systemName: "circle")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .foregroundColor(.secondary)
                                                    .frame(width: 20, height: 20)
                                            }
                                        } else {
                                            Image(systemName: "lock.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(.secondary)
                                                .frame(width: 20, height: 20)
                                        }
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                    
                                    if self.AppIconDataArray[results].title != self.AppIconDataArray.last?.title {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 100)
                                            .offset(x: 60)
                                    }
                                }.onAppear {
                                    if self.auth.subscriptionStatus == .subscribed {
                                        self.selectedIcon = self.AppIconDataArray[UserDefaults.standard.integer(forKey: "selectedAppIcon")]
                                    } else {
                                        self.selectedIcon = self.AppIconDataArray[0]
                                    }
                                }.sheet(isPresented: self.$openMenbership, content: {
                                    MembershipView()
                                        .environmentObject(self.auth)
                                        .edgesIgnoringSafeArea(.all)
                                        .navigationBarTitle("")
                                })
                                .onTapGesture {
                                    if self.auth.subscriptionStatus == .subscribed || self.AppIconDataArray[results].title == self.AppIconDataArray.first?.title || (self.AppIconDataArray[results].title == "Original Dark" && UserDefaults.standard.bool(forKey: "isEarlyAdopter")) {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.selectedIcon = self.AppIconDataArray[results]
                                        UserDefaults.standard.set(results, forKey: "selectedAppIcon")
                                        self.auth.changeHomeIconTo(name: self.selectedIcon?.image == "AppIcon-Original" ? nil : self.selectedIcon?.image)
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        self.openMenbership.toggle()
                                    }
                                }
                            }
                        }.padding(.vertical, 15)
                        */
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    //MARK: Wallpaper Section
                    HStack {
                        Text("WALLPAPERS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        LazyVGrid(columns: self.wallpaperLayout, spacing: 35) {
                            ForEach(self.WallpaperDataArray.indices, id:\.self) { results in
                                VStack {
                                    VStack {
                                        ZStack(alignment: .bottomTrailing) {
                                            if self.WallpaperDataArray[results].image == "" {
                                                BlurView(style: .systemThinMaterial)
                                                    .frame(width: 80, height: 170)
                                                    .cornerRadius(15)
                                                    .shadow(color: Color("buttonShadow"), radius: 5, x: 0, y: 5)
                                            }
                                            
                                            Image(self.WallpaperDataArray[results].image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 170, alignment: .center)
                                                .cornerRadius(15)
                                                .shadow(color: Color("buttonShadow"), radius: 5, x: 0, y: 5)
                                            
                                            if self.auth.subscriptionStatus == .subscribed || self.WallpaperDataArray[results].isPremium == false {
                                                if self.selectedWallpaper?.title == self.WallpaperDataArray[results].title {
                                                    Image(systemName: "checkmark.circle.fill" )
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(.blue)
                                                        .frame(width: 20, height: 20)
                                                        .padding(10)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .foregroundColor(.secondary)
                                                        .frame(width: 20, height: 20)
                                                        .padding(10)
                                                }
                                            } else {
                                                Image(systemName: "lock.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(.white)
                                                    .frame(width: 20, height: 20)
                                                    .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                                    .padding(10)
                                            }
                                        }.padding(.trailing, 5)
                                        .padding(.vertical, 3)
                                        
                                        HStack(alignment: .center, spacing: 10) {
                                            Text(self.WallpaperDataArray[results].title)
                                                .font(.subheadline)
                                                .fontWeight(.none)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                            
                                        }.frame(width: 150)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.onAppear {
                                    self.selectedWallpaper = self.WallpaperDataArray[UserDefaults.standard.integer(forKey: "selectedWallpaper")]
                                }.sheet(isPresented: self.$openMenbership, content: {
                                    MembershipView()
                                        .environmentObject(self.auth)
                                        .edgesIgnoringSafeArea(.all)
                                        .navigationBarTitle("")
                                })
                                .onTapGesture {
                                    if self.auth.subscriptionStatus == .subscribed || self.WallpaperDataArray[results].isPremium == false {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.selectedWallpaper = self.WallpaperDataArray[results]
                                        UserDefaults.standard.set(results, forKey: "selectedWallpaper")
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        self.openMenbership.toggle()
                                    }
                                }
                            }
                            
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    Spacer()
                    FooterInformation()
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle("Appearance", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
