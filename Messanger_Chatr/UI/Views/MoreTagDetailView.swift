//
//  MoreTagDetailView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/27/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct MoreTagDetailView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: DiscoverViewModel
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @State var tagsCount: Int = 0
    @State var tagId: String = "tagName"
    @State var tagsData: [PublicDialogModel] = []

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: true) {
                if !self.tagsData.isEmpty {
                    VStack(spacing: 5) {
                        HStack(alignment: .bottom) {
                            Text("\(self.tagsCount) TOTAL " + (self.tagsCount <= 1 ? "TAG:" : "TAGS:"))
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .padding(.top, 90)
                                .offset(y: 2)
                            Spacer()
                        }
                        
                        self.styleBuilder(content: {
                            ForEach(self.tagsData.indices, id: \.self) { id in
                                VStack(alignment: .trailing, spacing: 0) {
                                    PublicDialogDiscoverCell(dismissView: self.$dismissView, showPinDetails: self.$showPinDetails, dialogData: self.tagsData[id], isLast: id == self.tagsData.count)
                                        .environmentObject(self.auth)
                                }
                            }
                        })
                    }
                } else {
                    VStack(spacing: 5) {
                        Image("EmptyDialog")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120, alignment: .center)
                            .padding(.top, 180)
                            .padding(.bottom, 10)
                        
                        Text("Empty Dialogs")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("No found public dialogs for this tag. 🤔\nPlease explore other tags.")
                            .font(.subheadline)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        }.frame(width: Constants.screenWidth)
        .navigationBarTitle("#" + self.tagId, displayMode: .inline)
        .edgesIgnoringSafeArea(.all)
        .background(Color("bgColor"))
        .onAppear() {
            self.tagsData.removeAll()
            self.viewModel.observeTopTagDialogs(tagId: self.tagId, kPagination: 20, loadMore: false, completion: { dia in
                self.tagsData.append(dia)
            }, isHiddenIndicator: { hide in
                print("the loading for more tags is hidden: \(String(describing: hide))")
            })
            
            self.viewModel.fetchTagsDialogCount(tagId, completion: { count in
                self.tagsCount = count
            })
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

