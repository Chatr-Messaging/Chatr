//
//  PublicDialogDiscoverCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct PublicDialogDiscoverCell: View {
    @EnvironmentObject var auth: AuthModel
    @State var dialogData: DiscoverBannerData
    @State var isLast: Bool = false
    @State private var actionState: Int? = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all).environmentObject(self.auth), tag: 1, selection: self.$actionState) {
                EmptyView()
            }

            Button(action: {
                self.actionState = 1
            }) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Image(self.dialogData.groupImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                            .cornerRadius(50 / 4)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(self.dialogData.groupName)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(self.dialogData.memberCount) members")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Text(self.dialogData.description)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                                .padding(.top, 4)
                        }

                        Spacer()
                        
                        
                        Button(action: {
                            print("join group")
                        }) {
                            Text("JOIN")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.blue)
                                .frame(width: 55, height: 30, alignment: .center)
                                .background(Color("buttonColor_darker"))
                        }.cornerRadius(8)
                        //.shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)

                        Image(systemName: "chevron.right")
                            .resizable()
                            .font(Font.title.weight(.semibold))
                            .scaledToFit()
                            .frame(width: 7, height: 15, alignment: .center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    
                    Divider()
                        .frame(width: Constants.screenWidth - 80)
                        .offset(x: 45)
                        .opacity(!self.isLast ? 1 : 0)
                }
            }.buttonStyle(changeBGButtonStyle())
            
        }.simultaneousGesture(TapGesture()
                                .onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                })
    }
    
    func dialogDetails() -> some View {
        Text("more top dialogs here lol...")
//        MoreContactsView(dismissView: self.$dismissView,
//                         dialogModelMemebers: self.$dialogModelMemebers,
//                         openNewDialogID: self.$openNewDialogID,
//                         dialogModel: self.$dialogModel,
//                         currentUserIsPowerful: self.$currentUserIsPowerful,
//                         showProfile: self.$showProfile)
//            .environmentObject(self.auth)
    }
}
