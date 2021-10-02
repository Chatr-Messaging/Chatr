//
//  MoreTagDetailView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/27/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct MorePublicListView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: DiscoverViewModel
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @Binding var openNewDialogID: Int
    @State var tagsCount: Int = 0
    @State var tagId: String = "tagName"
    @State var dialogData: [PublicDialogModel] = []
    @State var isHiddenIndicator: Bool = false
    var viewState: morePublicListRelationship = .unknown
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: true) {
                if !self.dialogData.isEmpty {
                    VStack(spacing: 5) {
                        HStack(alignment: .bottom) {
                            Text(self.viewState == .tags ? "\(self.tagsCount) TOTAL " + (self.tagsCount <= 1 ? "DIALOG:" : "DIALOGS:") : self.viewState == .popular ? "TOP DIALOGS:" : self.viewState == .newest ? "RECENTLY ADDED:" : "DIALOGS:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .padding(.top, 90)
                            Spacer()
                        }
                        
                        self.styleBuilder(content: {
                            ForEach(self.dialogData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, openNewDialogID: self.$openNewDialogID, dialogData: self.dialogData[id], isLast: self.dialogData[id].id == self.dialogData.last?.id)
                                        .environmentObject(self.auth)
                                }
                            }
                        })
                    }
                } else if self.isHiddenIndicator {
                    VStack(spacing: 5) {
                        Image("EmptyDialog")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120, alignment: .center)
                            .padding(.top, 180)
                            .padding(.bottom, 10)
                        
                        Text("No Chatr")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(self.viewState == .tags ? "No found public channels for this tag. 🤔\nPlease explore other tags or check your connection." : "No found public dialogs. 🤔\nPlease try again or check your connection.")
                            .font(.subheadline)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if !self.isHiddenIndicator {
                    Text(self.viewState == .tags ? "loading \("#" + self.tagId)..." : self.viewState == .popular ? "loading more popular..." : self.viewState == .newest ? "loading the newest..." : "loading...")
                        .font(.subheadline)
                        .fontWeight(.none)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 140)
                }
                
                FooterInformation()
                    .padding(.top, 100)
                    .padding(.bottom, 25)
                    .opacity(self.isHiddenIndicator ? 1 : 0)
            }
        }.frame(width: Constants.screenWidth)
        .navigationBarTitle(self.viewState == .tags ? "#" + self.tagId : self.viewState == .popular ? "Popular" : self.viewState == .newest ? "Newest" : "More", displayMode: .inline)
        .background(Color("bgColor"))
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            guard self.dialogData.isEmpty else { return }

            if self.viewState == .tags {
                self.viewModel.observeTopTagDialogs(tagId: self.tagId, kPagination: 20, loadMore: false, completion: { dia in
                    if dia.banned == false, !self.dialogData.contains(where: { $0.id == dia.id }) {
                        self.dialogData.append(dia)
                    }
                }, isHiddenIndicator: { hide in
                    self.dialogData.sort(by: { $0.memberCount ?? 0 > $1.memberCount ?? 0 })
                    self.isHiddenIndicator = hide ?? false
                })
                
                self.viewModel.fetchTagsDialogCount(tagId, completion: { count in
                    self.tagsCount = count
                })
            } else if self.viewState == .popular {
                self.viewModel.observeTopDialogs(kPagination: 20, loadMore: false, completion: { dia in
                    if dia.banned == false, !self.dialogData.contains(where: { $0.id == dia.id }) {
                        self.dialogData.append(dia)
                    }
                }, isHiddenIndicator: { hide in
                    self.dialogData.sort(by: { $0.memberCount ?? 0 > $1.memberCount ?? 0 })
                    self.isHiddenIndicator = hide ?? false
                })
            } else if self.viewState == .newest {
                self.viewModel.observeRecentDialogs(kPagination: 20, loadMore: false, completion: { dia in
                    if dia.banned == false, !self.dialogData.contains(where: { $0.id == dia.id }) {
                        self.dialogData.append(dia)
                    }
                }, isHiddenIndicator: { hide in
                    self.dialogData.sort(by: { $0.creationOrder ?? 0 > $1.creationOrder ?? 0 })
                    self.isHiddenIndicator = hide ?? false
                })
            }
        }
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

