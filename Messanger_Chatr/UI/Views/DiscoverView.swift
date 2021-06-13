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
    @State var grandSearchData: [PublicDialogModel] = []
    @State var dialogTags: [publicTag] = []
    @State var bannerCount: Int = 0
    @State var topDialogsCount: Int = 0
    @State var tagSelection: Int? = -1
    @State var openNewPublicDialog: Bool = false
    @State var showMoreTopDialogs: Bool = false
    @State var showMoreRecentDialogs: Bool = false
    @State var isDataLoading: Bool = true
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
                                    if !self.grandSearchData.contains(where: { $0.id == dia.id }) {
                                        withAnimation {
                                            self.grandSearchData.append(dia)
                                        }
                                    }
                                })
                            } else {
                                withAnimation {
                                    self.grandSearchData.removeAll()
                                }
                            }
                        }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                withAnimation {
                                    self.searchText = ""
                                    self.outputSearchText = ""
                                    self.grandSearchData.removeAll()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal, 15)
                        }
                        
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                }.padding(.all)
                
                //MARK: Grand Search Section
                if !self.grandSearchData.isEmpty {
                    VStack {
                        HStack {
                            Text("SEARCH RESULTS:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                            Spacer()
                        }.padding(.bottom, 5)

                        self.styleBuilder(content: {
                            ForEach(self.grandSearchData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    if id <= 14 {
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.grandSearchData[id], isLast: id == 4)
                                            .environmentObject(self.auth)
                                    }
                                }
                            }
                        })
                    }.padding(.vertical, 25)
                    .animation(.interactiveSpring())
                }
                
                if self.searchText.count >= 2 && self.grandSearchData.isEmpty {
                    VStack {
                        Text("no dialogs found with your search")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }.animation(.interactiveSpring())
                    .padding(.vertical, 40)
                }

                //MARK: Tag Section
                ScrollView(.horizontal, showsIndicators: false) {
                    Grid(self.dialogTags.sorted(by: { $0.title < $1.title }).indices, id: \.self) { item in
                        ZStack {
                            NavigationLink(destination: self.moreDetails(tagId: self.dialogTags[item].title, viewState: .tags).edgesIgnoringSafeArea(.all), tag: Int(item), selection: self.$tagSelection) {
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
                                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.45), lineWidth: 1).background(Color("buttonColor")).cornerRadius(10))
                                    .lineLimit(1)
                                    .fixedSize()
                            }).buttonStyle(ClickButtonStyle())
                        }
                    }.padding(.horizontal)
                    .frame(height: 85)
                }.gridStyle(self.style)
                .padding(.vertical, 5)
                
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
                                    DiscoverFeaturedCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogModel: self.bannerDataArray[index])
                                        .environmentObject(self.auth)
                                        .frame(width: Constants.screenWidth * 0.68)
                                        .id(self.bannerDataArray[index].id)
                                        .animation(.interactiveSpring())
                                }
                            }.animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                        }.frame(height: 340)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                    }
                }

                //MARK: Popular Section
                if self.topDialogsData.count > 0 {
                    VStack {
                        HStack {
                            Text("Popular")
                                .font(.system(size: 26))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.showMoreTopDialogs.toggle()
                            }, label: {
                                Text("See All")
                                    .foregroundColor(.blue)
                            })
                        }.padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 10)

                        self.styleBuilder(content: {
                            ForEach(self.topDialogsData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    if id <= 4 {
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.topDialogsData[id], isLast: id == 4)
                                            .environmentObject(self.auth)
                                            .id(self.topDialogsData[id].id)
                                    }
                                    
                                    if self.topDialogsData.count > 5 && id == 4 {
                                        NavigationLink(destination: self.moreDetails(tagId: nil, viewState: .popular), isActive: $showMoreTopDialogs) {
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
                            Text("Newest")
                                .font(.system(size: 26))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.showMoreRecentDialogs.toggle()
                            }, label: {
                                Text("See All")
                                    .foregroundColor(.blue)
                            })
                        }.padding(.horizontal, 30)
                        .padding(.top, 30)
                        .padding(.bottom, 10)

                        self.styleBuilder(content: {
                            ForEach(self.recentDialogsData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    if id <= 4 {
                                     //Public dialog cell
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.recentDialogsData[id], isLast: id == 4 || self.recentDialogsData[id].id == self.recentDialogsData.last?.id)
                                            .environmentObject(self.auth)
                                            .id(self.recentDialogsData[id].id)
                                    }
                                    
                                    if self.recentDialogsData.count > 5 && id == 4 {
                                        NavigationLink(destination: self.moreDetails(tagId: nil, viewState: .newest), isActive: $showMoreRecentDialogs) {
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
                
                FooterInformation()
                    .padding(.top, self.searchText.count < 2 ? 80 : 140)
                    .padding(.bottom, 25)
                    .opacity(!self.grandSearchData.isEmpty ? 0 : 1)
            }
            .onAppear {
                //self.bannerCount = self.bannerDataArray.count
                //self.topDialogsCount = self.topDialogsData.count
                
                if self.bannerDataArray.isEmpty {
                    self.viewModel.observeFeaturedDialogs({ dialog in
                        if !self.bannerDataArray.contains(where: { $0.id == dialog.id }) {
                            self.bannerDataArray.append(dialog)
                        }
                    }, isHiddenIndicator: { hide in
                        self.isDataLoading = hide ?? false
                    })
                }
                
                if self.topDialogsData.isEmpty {
                    self.viewModel.observeTopDialogs(kPagination: 6, loadMore: false, completion: { dia in
                        if !self.topDialogsData.contains(where: { $0.id == dia.id }) {
                            self.topDialogsData.append(dia)
                        }
                    }, isHiddenIndicator: { hide in
                        self.topDialogsData.sort(by: { $0.memberCount ?? 0 > $1.memberCount ?? 0 })
                        self.isDataLoading = hide ?? false
                    })
                }

                if self.recentDialogsData.isEmpty {
                    self.viewModel.observeRecentDialogs(kPagination: 6, loadMore: false, completion: { dia in
                        if !self.recentDialogsData.contains(where: { $0.id == dia.id }) {
                            self.recentDialogsData.append(dia)
                        }
                    }, isHiddenIndicator: { hide in
                        self.recentDialogsData.sort(by: { $0.creationOrder ?? 0 > $1.creationOrder ?? 0 })
                        self.isDataLoading = hide ?? false
                    })
                }

                if self.dialogTags.isEmpty {
                    self.viewModel.loadTags(completion: { tags in
                        for tag in tags {
                            if !self.dialogTags.contains(where: { $0.title == tag.title }) {
                                self.dialogTags = tags
                                self.isDataLoading = false
                            }
                        }
                    })
                }
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
    
    func moreDetails(tagId: String?, viewState: morePublicListRelationship) -> some View {
        MorePublicListView(viewModel: self.viewModel, dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, tagsCount: 0, tagId: tagId ?? "", viewState: viewState)
            .environmentObject(self.auth)
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
