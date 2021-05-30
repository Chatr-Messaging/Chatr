//
//  PublicDialogDiscoverCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct PublicDialogDiscoverCell: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var showPinDetails: String
    @State var dialogData: PublicDialogModel
    @State var isLast: Bool = false
    @State private var actionState: Bool = false
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var openNewDialogID: Int = 0
    var sendDia: DialogStruct = DialogStruct()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
//            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all).environmentObject(self.auth), tag: 200, selection: self.$actionState) {
//                EmptyView()
//            }

            NavigationLink(destination: self.dialogDetails().edgesIgnoringSafeArea(.all), isActive: self.$actionState, label: {
                EmptyView()
            })

            Button(action: {
                print("pushing to the next: \(String(describing: self.dialogData.name)) && \(String(describing: self.dialogData.id))")
                self.actionState.toggle()
            }) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        
                        WebImage(url: URL(string: self.dialogData.avatar ?? ""))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 54, height: 54, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .scaledToFill()
                            .frame(width: 54, height: 54)
                            .cornerRadius(50 / 4)
                            .clipped()
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(self.dialogData.name ?? "no name")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(self.dialogData.memberCount ?? 0) members")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(Color.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                            
                            Text(self.dialogData.description ?? "")
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
            .onAppear() {
                self.sendDia.id = self.dialogData.id ?? ""
                self.sendDia.dialogType = "public"
                self.sendDia.fullName = self.dialogData.name ?? ""
                self.sendDia.bio = self.dialogData.description ?? ""
                self.sendDia.avatar = self.dialogData.avatar ?? ""
                self.sendDia.coverPhoto = self.dialogData.coverPhoto ?? ""
                print("found the diaaaaa :\(self.sendDia.id)")
            }
        }.simultaneousGesture(TapGesture()
                                .onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                })
    }
    
    func dialogDetails() -> some View {
        VisitGroupChannelView(dismissView: self.$dismissView, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$openNewDialogID, showPinDetails: self.$showPinDetails, fromDialogCell: false, viewState: .fromDynamicLink, dialogRelationship: .subscribed, dialogModel: self.sendDia)
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
