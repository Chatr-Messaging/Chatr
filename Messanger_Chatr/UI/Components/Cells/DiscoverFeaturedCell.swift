//
//  DiscoverFeaturedCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct DiscoverFeaturedCell: View, Identifiable {
    @EnvironmentObject var auth: AuthModel
    let id = UUID()
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @State var groupName: String
    @State var memberCount: Int
    @State var description: String
    @State var groupImg: String
    @State var backgroundImg: String
    @State private var actionState: Bool = false
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var openNewDialogID: Int = 0

    var body: some View {
        ZStack {
//            NavigationLink(destination: , tag: 1, selection: self.$actionState) {
//                EmptyView()
//            }

            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all), isActive: self.$actionState, label: {
                EmptyView()
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.actionState.toggle()
            }) {
                ZStack(alignment: .top) {
                    WebImage(url: URL(string: self.backgroundImg))
                        .resizable()
                        .placeholder{ Image(systemName: "photo.on.rectangle.angled").resizable().frame(width: 30, height: 27, alignment: .center).scaledToFill().offset(y: -18) }
                        .indicator(.activity)
                        .frame(width: Constants.screenWidth * 0.68 - 30, height: 180)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)

                    VStack(alignment: .center, spacing: 0) {
                        WebImage(url: URL(string: self.groupImg))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 70, height: 70, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .background(Color("buttonColor"))
                            .cornerRadius(55 / 4)
                            .padding(.bottom, 5)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(self.groupName)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(self.memberCount > 1 ? "\(self.memberCount) members" : "become the first member!")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .multilineTextAlignment(.center)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)

        //                        Text("#" + self.catagory)
        //                            .font(.caption)
        //                            .fontWeight(.regular)
        //                            .multilineTextAlignment(.center)
        //                            .foregroundColor(Color.primary)
        //                            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
        //                            .padding(2.5).background(Color.primary.opacity(0.05)).cornerRadius(4)
        //                            .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary, lineWidth: 1.5).background( Color.primary.opacity(0.05)).cornerRadius(4))
                            
                            Text(self.description)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(height: 40)
                            
                            Spacer()
                            Button(action: {
                                print("join: \(self.groupName)")
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 16, alignment: .center)
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                                    
                                    Text("Join Group")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color.white)
                                }.frame(width: Constants.screenWidth * 0.60 - 50, height: 36, alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }.buttonStyle(ClickMiniButtonStyle())
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2.5)
                            .padding(.bottom, 4)
                        }
                    }
                    .padding(.top, 120)
                    .padding()
                }
                .background(Color("buttonColor"))
                .frame(minHeight: 340, maxHeight: 360)
                .cornerRadius(20)
                .padding(.horizontal, 15)
            }.buttonStyle(ClickMiniButtonStyle())
        }
    }
    
    func dialogDetails() -> some View {
        VisitGroupChannelView(dismissView: self.$dismissView, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, fromDialogCell: false, viewState: .fromDynamicLink, dialogRelationship: .subscribed)
            .environmentObject(self.auth)
            .edgesIgnoringSafeArea(.all)
            .navigationBarItems(trailing:
                            Button(action: {
                                self.isEditGroupOpen.toggle()
                            }) {
                                Text("Edit")
                                    .foregroundColor(.blue)
                                    .opacity(self.canEditGroup ? 1 : 0)
                            }.disabled(self.canEditGroup ? false : true))
    }
}
