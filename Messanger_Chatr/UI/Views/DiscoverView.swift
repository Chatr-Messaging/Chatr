//
//  DiscoverView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Firebase
import Grid

struct DiscoverView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State var searchText: String = ""
    @State var outputSearchText: String = ""
    @State var bannerDataArray: [DiscoverBannerData] = []
    @State var topDialogsData: [DiscoverBannerData] = []
    @State var dialogTags: [publicTag] = []
    @State var bannerCount: Int = 0
    @State var topDialogsCount: Int = 0
    @State var pageIndex: Int = 0
    @State var openNewPublicDialog: Bool = false
    @State var showMoreTopDialogs: Bool = false
    @State var style = StaggeredGridStyle(.horizontal, tracks: .fixed(35), spacing: 8)

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .center) {
                /*
                Text("Under Construction")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)

                Text("coming soon...")
                    .font(.headline)
                    .fontWeight(.regular)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Spacer()
                Image("Construction")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.screenWidth)
*/
                
                //SEARCH BAR
                VStack {
                    HStack {
                        Text("SEARCH NAME:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Spacer()
                    }
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
                }.padding(.all)
                
                //MARK: Tag Section
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(self.dialogTags, id: \.self) { item in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }, label: {
                            Text("#" + "\(item.title)")
                                .fontWeight(.medium)
                                .padding(.vertical, 7.5)
                                .padding(.horizontal)
                                .foregroundColor(item.selected ? Color.black : Color.primary)
                                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.75), lineWidth: 1.5).background(Color("buttonColor")).cornerRadius(10))
                                .lineLimit(1)
                                .fixedSize()
                        }).buttonStyle(ClickButtonStyle())
                    }.padding(.leading, 20)
                    .frame(height: 85)
                }.gridStyle(self.style)
                .padding(.vertical)
                
                //MARK: Featured Section
                if self.bannerDataArray.count > 0 {
                    VStack {
                        HStack {
                            Text("FEATURED:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .padding(.bottom, 2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            DiscoverListView(page: self.$pageIndex, dataArray: self.$bannerDataArray)
                                .environmentObject(self.auth)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                        }.frame(height: 280)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                    }
                }

                //MARK: Popular Section
                if self.topDialogsData.count > 0 {
                    VStack {
                        HStack {
                            Text("POPULAR:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 5)

                        self.styleBuilder(content: {
                            ForEach(self.topDialogsData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    if id <= 4 {
                                     //Public dialog cell
                                        PublicDialogDiscoverCell(dialogData: self.topDialogsData[id], isLast: id == 4)
                                            .environmentObject(self.auth)
                                    }
                                    
                                    if self.topDialogsData.count > 5 && id == 4 {
                                        NavigationLink(destination: self.topDialogs(), isActive: $showMoreTopDialogs) {
                                            VStack(alignment: .trailing, spacing: 0) {
                                                Divider()
                                                    .frame(width: Constants.screenWidth - 80)
                                                    .offset(x: 20)
                                                
                                                HStack {
                                                    Image(systemName: "ellipsis.circle")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 20, height: 20, alignment: .center)
                                                        .foregroundColor(Color("SoftTextColor"))
                                                        .padding(.leading, 10)
                                                    
                                                    Text("more...")
                                                        .font(.subheadline)
                                                        .foregroundColor(Color("SoftTextColor"))
                                                        .padding(.horizontal)
                                                    
                                                    Spacer()
                                                    Image(systemName: "chevron.right")
                                                        .resizable()
                                                        .font(Font.title.weight(.bold))
                                                        .scaledToFit()
                                                        .frame(width: 7, height: 15, alignment: .center)
                                                        .foregroundColor(.secondary)
                                                }.padding(.horizontal)
                                                .padding(.top, 10)
                                                .padding(.bottom, 15)
                                                .contentShape(Rectangle())
                                            }
                                        }.buttonStyle(changeBGButtonStyle())
                                    }
                                }
                            }
                        })
                    }
                }
            }
            .onAppear {
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Apple Fanboy", memberCount: 18, description: "Technology group that is full of fun people!", groupImg: "proPic", backgroundImg: "michaelAngelWallpaper", catagoryImg: "iphone.homebutton"))
                
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "When in Rome they say eh?! lolll", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Howedy dooo to my peopleee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.bannerDataArray.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Sounds of music is an old movieeee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Sounds of music is an old movieeee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Apple Fanboy", memberCount: 18, description: "Technology group that is full of fun people!", groupImg: "proPic", backgroundImg: "michaelAngelWallpaper", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "When in Rome they say eh?! lolll", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Howedy dooo to my peopleee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Howedy dooo to my peopleee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))
                
                self.topDialogsData.append(DiscoverBannerData(groupName: "Retro World", memberCount: 129, description: "Howedy dooo to my peopleee", groupImg: "proPic", backgroundImg: "syncAddressBackground", catagoryImg: "iphone.homebutton"))

                self.bannerCount = self.bannerDataArray.count
                self.topDialogsCount = self.topDialogsData.count
                self.loadTags(completion: { })
            }
        }.resignKeyboardOnDragGesture()
//        .navigationBarItems(leading:
//            Button(action: {
//                self.presentationMode.wrappedValue.dismiss()
//            }) {
//                Text("Done")
//                    .foregroundColor(.primary)
//            })
    }
    
    func loadTags(completion: @escaping () -> ()) {
        let marketplaceTags = Database.database().reference().child("Marketplace").child("tags")

        self.dialogTags.removeAll()
        marketplaceTags.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for i in dict {
                    withAnimation {
                        self.dialogTags.append(publicTag(title: i.key))
                    }
                }

                completion()
            } else {
                completion()
            }
        })
    }

    func topDialogs() -> some View {
        Text("more top dialogs here lol...")
//        MoreContactsView(dismissView: self.$dismissView,
//                         dialogModelMemebers: self.$dialogModelMemebers,
//                         openNewDialogID: self.$openNewDialogID,
//                         dialogModel: self.$dialogModel,
//                         currentUserIsPowerful: self.$currentUserIsPowerful,
//                         showProfile: self.$showProfile)
//            .environmentObject(self.auth)
    }
    
    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center, spacing: 0) {
            content()
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
}
