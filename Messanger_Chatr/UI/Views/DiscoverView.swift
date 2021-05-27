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
    @ObservedObject var viewModel: DiscoverViewModel = DiscoverViewModel()
    var removeDoneBtn: Bool = true
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @State var searchText: String = ""
    @State var outputSearchText: String = ""
    @State var bannerDataArray: [PublicDialogModel] = []
    @State var topDialogsData: [PublicDialogModel] = []
    @State var recentDialogsData: [PublicDialogModel] = []
    @State var dialogTags: [publicTag] = []
    @State var bannerCount: Int = 0
    @State var topDialogsCount: Int = 0
    @State var tagSelection: Int? = -1
    @State var openNewPublicDialog: Bool = false
    @State var showMoreTopDialogs: Bool = false
    @State var showMoreRecentDialogs: Bool = false
    @State var style = StaggeredGridStyle(.horizontal, tracks: .fixed(35), spacing: 8)

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .center) {
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
                            if self.searchText.count >= 2 {
                                //self.grandSeach(searchText: self.searchText)
                                self.viewModel.searchPublicDialog(withText: self.searchText, completion: { dia in
                                    print("found dialog isss: \(String(describing: dia.name))")
                                })
                            } else {
                                //self.grandUsers.removeAll()
                            }
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
                    Grid(self.dialogTags.sorted(by: { $0.title < $1.title }).indices, id: \.self) { item in
                        ZStack {
                            NavigationLink(destination: self.tagDetails(tagId: self.dialogTags[item].title).edgesIgnoringSafeArea(.all), tag: Int(item), selection: self.$tagSelection) {
                                EmptyView()
                            }

                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.tagSelection = Int(item)
                            }, label: {
                                Text("#" + "\(self.dialogTags[item].title)")
                                    .fontWeight(.medium)
                                    .padding(.vertical, 7.5)
                                    .padding(.horizontal)
                                    .foregroundColor(self.dialogTags[item].selected ? Color.black : Color.primary)
                                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.75), lineWidth: 1.5).background(Color("buttonColor")).cornerRadius(10))
                                    .lineLimit(1)
                                    .fixedSize()
                            }).buttonStyle(ClickButtonStyle())
                        }
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
                            HStack(spacing: 0) {
                                ForEach(self.bannerDataArray.indices, id: \.self) { index in
                                    DiscoverBannerCell(groupName: self.bannerDataArray[index].name ?? "no name", memberCount: self.bannerDataArray[index].memberCount ?? 0, description: self.bannerDataArray[index].description ?? "", groupImg: self.bannerDataArray[index].avatar ?? "", backgroundImg: self.bannerDataArray[index].coverPhoto ?? "")
                                        .frame(width: Constants.screenWidth * 0.55)
                                }
                            }.animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
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
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.topDialogsData[id], isLast: id == 4)
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
                
                //MARK: Recent Section
                if self.recentDialogsData.count > 0 {
                    VStack {
                        HStack {
                            Text("RECENTLY ADDED:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                        .padding(.top, 30)
                        .padding(.bottom, 5)

                        self.styleBuilder(content: {
                            ForEach(self.recentDialogsData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    if id <= 4 {
                                     //Public dialog cell
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.recentDialogsData[id], isLast: id == 4)
                                            .environmentObject(self.auth)
                                    }
                                    
                                    if self.recentDialogsData.count > 5 && id == 4 {
                                        NavigationLink(destination: self.recentDialogs(), isActive: $showMoreRecentDialogs) {
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
                self.bannerCount = self.bannerDataArray.count
                self.topDialogsCount = self.topDialogsData.count
                
                self.bannerDataArray.removeAll()
                self.viewModel.observeFeaturedDialogs({ dialog in
                    self.bannerDataArray.append(dialog)
                    print("the found banner array: \(dialog.name ?? "no name")")
                }, isHiddenIndicator: { hide in
                    print("the loading indicator is done? \(hide ?? false)")
                })
                
                self.topDialogsData.removeAll()
                self.viewModel.observeTopDialogs(kPagination: 5, loadMore: false, completion: { dia in
                    print("the found top dialog array: \(dia.name ?? "no name")")
                    self.topDialogsData.append(dia)
                }, isHiddenIndicator: { hide in
                    print("the loading indicator is done? \(hide ?? false)")
                })
                
                self.recentDialogsData.removeAll()
                self.viewModel.observeRecentDialogs(kPagination: 5, loadMore: false, completion: { dia in
                    print("the found recent dialog array: \(dia.name ?? "no name")")
                    self.recentDialogsData.append(dia)
                }, isHiddenIndicator: { hide in
                    print("the loading indicator is done? \(hide ?? false)")
                })

                self.dialogTags.removeAll()
                self.viewModel.loadTags(completion: { tags in
                    self.dialogTags = tags
                })
            }
        }.resignKeyboardOnDragGesture()
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .foregroundColor(.primary)
            }.opacity(self.removeDoneBtn ? 0 : 1))
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
    
    func tagDetails(tagId: String) -> some View {
        MoreTagDetailView(viewModel: self.viewModel, dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, tagsCount: 0, tagId: tagId)
            .environmentObject(self.auth)
    }
    
    func recentDialogs() -> some View {
        Text("more recent dialogs here lol...")
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
