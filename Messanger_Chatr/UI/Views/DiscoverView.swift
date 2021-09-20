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
    @Binding var openNewDialogID: Int
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
    @State var isShowingWelcome: Bool = false
    @State var isLoading: Bool = false
    @State var style = StaggeredGridStyle(.horizontal, tracks: .fixed(35), spacing: 8)

    var body: some View {
        if UserDefaults.standard.bool(forKey: "discoverAgree") || self.isShowingWelcome {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .center) {
                //SEARCH BAR
                VStack {
                    HStack {
                        Text("SEARCH CHANNEL NAME:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
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
                                    if dia.banned == false, !self.grandSearchData.contains(where: { $0.id == dia.id }) {
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
                                        PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, dialogData: self.grandSearchData[id], isLast: id == 4)
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

                if self.recentDialogsData.isEmpty && self.dialogTags.isEmpty && self.bannerDataArray.isEmpty && self.topDialogsData.isEmpty {
                    VStack(alignment: .center, spacing: 12) {
                        Circle()
                            .trim(from: 0, to: 0.8)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 25, height: 25)
                            .rotationEffect(.init(degrees: self.isLoading ? 360 : 0))
                            .animation(Animation.linear(duration: 0.8).repeatForever(autoreverses: false))
                            .padding(.horizontal, 45)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                            .onAppear() {
                                self.isLoading.toggle()
                            }
                        
                        Text("loading...")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.primary)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                            .offset(x: 5)
                    }.padding(.vertical, 80)
                } else {
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
                                        DiscoverFeaturedCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, dialogModel: self.bannerDataArray[index])
                                            .environmentObject(self.auth)
                                            .frame(width: Constants.screenWidth * 0.68)
                                            .id(self.bannerDataArray[index].id)
                                            .animation(.interactiveSpring())
                                    }
                                }.animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                            }.frame(height: 340)
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        }
                    }

                    //MARK: Popular Section
                    if self.topDialogsData.count > 0 {
                        VStack {
                            HStack(alignment: .center) {
                                Text("Popular")
                                    .font(.system(size: 30))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    
                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.showMoreTopDialogs.toggle()
                                }, label: {
                                    Text("see all")
                                        .foregroundColor(.blue)
                                }).opacity(self.topDialogsData.count > 5 ? 1 : 0)
                            }.padding(.horizontal, 30)
                            .padding(.top, 35)
                            .padding(.bottom, 10)

                            self.styleBuilder(content: {
                                ForEach(self.topDialogsData.indices, id: \.self) { id in
                                    VStack(alignment: .trailing, spacing: 0) {
                                        if id <= 4 {
                                            PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, dialogData: self.topDialogsData[id], isLast: id == 4)
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
                                                            .foregroundColor(Color.blue)
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
                                            .simultaneousGesture(TapGesture()
                                                .onEnded { _ in
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                })
                                        }
                                    }
                                }
                            })
                        }
                    }
                    
                    //MARK: Recent Section
                    if self.recentDialogsData.count > 0 {
                        VStack {
                            HStack(alignment: .center) {
                                Text("Just Added")
                                    .font(.system(size: 30))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.showMoreRecentDialogs.toggle()
                                }, label: {
                                    Text("see all")
                                        .foregroundColor(.blue)
                                }).opacity(self.recentDialogsData.count > 5 ? 1 : 0)
                            }.padding(.horizontal, 30)
                            .padding(.top, 35)
                            .padding(.bottom, 10)

                            self.styleBuilder(content: {
                                ForEach(self.recentDialogsData.indices, id: \.self) { id in
                                    VStack(alignment: .trailing, spacing: 0) {
                                        if id <= 4 {
                                         //Public dialog cell
                                            PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, dialogData: self.recentDialogsData[id], isLast: id == 4 || self.recentDialogsData[id].id == self.recentDialogsData.last?.id)
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
                                                            .foregroundColor(Color.blue)
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
                                            .simultaneousGesture(TapGesture()
                                                .onEnded { _ in
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                })
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                
                FooterInformation()
                    .padding(.top, self.searchText.count < 2 ? 80 : 140)
                    .padding(.bottom, 25)
                    .opacity(!self.grandSearchData.isEmpty ? 0 : 1)
            }
            .onAppear {
                DispatchQueue.main.async {
                    if self.bannerDataArray.isEmpty {
                        self.viewModel.observeFeaturedDialogs({ dialog in
                            if dialog.banned == false, !self.bannerDataArray.contains(where: { $0.id == dialog.id }) {
                                self.bannerDataArray.append(dialog)
                            }
                        }, isHiddenIndicator: { hide in
                            self.isDataLoading = hide ?? false
                        })
                    }
                    
                    if self.topDialogsData.isEmpty {
                        self.viewModel.observeTopDialogs(kPagination: 6, loadMore: false, completion: { dia in
                            if dia.banned == false, !self.topDialogsData.contains(where: { $0.id == dia.id }) {
                                self.topDialogsData.append(dia)
                            }
                        }, isHiddenIndicator: { hide in
                            self.topDialogsData.sort(by: { $0.memberCount ?? 0 > $1.memberCount ?? 0 })
                            self.isDataLoading = hide ?? false
                        })
                    }

                    if self.recentDialogsData.isEmpty {
                        self.viewModel.observeRecentDialogs(kPagination: 6, loadMore: false, completion: { dia in
                            if dia.banned == false, !self.recentDialogsData.contains(where: { $0.id == dia.id }) {
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
            }
        }.resignKeyboardOnDragGesture()
        .navigationBarItems(leading:
            Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .foregroundColor(.primary)
            }.opacity(self.removeDoneBtn ? 0 : 1))
        } else {
            DiscoverWelcomeSection(isShowing: self.$isShowingWelcome)
        }
    }
    
    func moreDetails(tagId: String?, viewState: morePublicListRelationship) -> some View {
        MorePublicListView(viewModel: self.viewModel, dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, tagsCount: 0, tagId: tagId ?? "", viewState: viewState)
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
