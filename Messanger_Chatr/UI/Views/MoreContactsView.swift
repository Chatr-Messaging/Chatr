//
//  MoreContactsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/7/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift
import PopupView

struct MoreContactsView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var dialogModelMembers: [Int]
    @Binding var openNewDialogID: Int
    @Binding var dialogModel: DialogStruct
    @Binding var currentUserIsPowerful: Bool
    @Binding var showProfile: Bool
    @State var showAlert = false
    @State var notiText: String = ""
    @State var notiType: String = ""
    @State var isRemoving: Bool = false
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 5) {
                    HStack(alignment: .bottom) {
                        Text("\(self.dialogModel.occupentsID.count) TOTAL MEMBERS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.top, 60)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    LazyVStack(alignment: .center, spacing: 0) {
                        ForEach(self.dialogModelMembers.indices, id: \.self) { id in
                            VStack(alignment: .trailing, spacing: 0) {
                                DialogContactCell(showAlert: self.$showAlert, notiType: self.$notiType, notiText: self.$notiText, dismissView: self.$dismissView, openNewDialogID: self.$openNewDialogID, showProfile: self.$showProfile, contactID: Int(self.dialogModelMembers[id]), isAdmin: self.dialogModel.adminID.contains(self.dialogModelMembers[id]), isOwner: self.dialogModel.owner == self.dialogModelMembers[id], currentUserIsPowerful: self.$currentUserIsPowerful, isLast: self.dialogModelMembers[id] == self.dialogModelMembers.last, isRemoving: self.$isRemoving)
                                    .environmentObject(self.auth)
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                    
                    Spacer()
                    
                    //MARK: Footer Section
                    FooterInformation()
                        .padding(.vertical)
                }
            }//.navigationBarTitle("more members...", displayMode: .inline)
//            .popup(isPresented: self.$showAlert, type: .floater(), position: .bottom, animation: Animation.spring(), autohideIn: 4, closeOnTap: true) {
//                self.auth.createTopFloater(alertType: self.notiType, message: self.notiText)
//                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 8)
//            }
        }.background(Color("bgColor"))
        .edgesIgnoringSafeArea(.all)
        .onAppear() {
            self.showProfile = false
        }
    }
}
