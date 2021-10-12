//
//  QuickSnapStartView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

enum QuickSnapViewingState {
    case undefined, camera, takenPic, viewing, viewingOver, closed
}

struct QuickSnapStartView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var viewState: QuickSnapViewingState
    @Binding var selectedQuickSnapContact: ContactStruct
    @State var postViewSize = CGSize.zero
    @State var cameraViewSize = CGSize.zero
    @State var cameraFoucsPoint: CGPoint = CGPoint.zero
    @State var selectedContacts: [Int] = []
    
    var body: some View {
        ZStack {
            
            //MARK: Post View
            GeometryReader { geomotry in
                QuickSnapsPostView(selectedQuickSnapContact: self.$selectedQuickSnapContact, viewState: self.$viewState, selectedContacts: self.$selectedContacts)
                    .environmentObject(self.auth)
                    .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: self.viewState == .viewing || self.viewState == .viewingOver  ? abs(self.postViewSize.height) : 150))
                    .offset(y: self.postViewSize.height / 2)
                    .scaleEffect(self.viewState == .viewing || self.viewState == .viewingOver ? 1 - abs(self.postViewSize.height) / 500 : 0, anchor: .top)
                    .frame(height: self.viewState == .viewing || self.viewState == .viewingOver ? geomotry.size.height - abs(self.postViewSize.height / 10) : geomotry.size.height)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                    .allowsHitTesting(self.viewState == .viewing || self.viewState == .viewingOver ? true : false)
                    .gesture(DragGesture(minimumDistance: self.viewState == .viewing || self.viewState == .viewingOver ? 0 : Constants.screenHeight).onChanged { value in
                        if self.viewState == .viewing || self.viewState == .viewingOver  {
                            guard value.translation.height < 200 else { return }
                            guard value.translation.height > -1 else { return }
                            self.postViewSize = value.translation
                        }
                    }.onEnded { value in
                        if self.viewState == .viewing || self.viewState == .viewingOver {
                            if self.postViewSize.height > 150 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.viewState = .closed
                            }
                            self.postViewSize = .zero
                        }
                    })
            }
            

            //MARK: Camera View
            if self.auth.isUserAuthenticated == .signedIn {
                GeometryReader { geomotry in
                    CameraView(cameraState: self.$viewState, cameraFocus: self.$cameraFoucsPoint, selectedQuickSnapContact: self.$selectedQuickSnapContact, selectedContacts: self.$selectedContacts)
                        .environmentObject(self.auth)
                        .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                        .background(BlurView(style: .systemMaterialDark))
                        .opacity(self.viewState == .camera || self.viewState == .takenPic ? 1 : 0)
                        .clipShape(RoundedRectangle(cornerRadius: self.viewState != .closed ? abs(self.cameraViewSize.height) : 150))
                        .offset(y: self.cameraViewSize.height / 2)
                        .scaleEffect(self.viewState == .camera || self.viewState == .takenPic ? 1 - abs(self.cameraViewSize.height) / 500 : 0, anchor: .center)
                        .frame(height: self.viewState == .camera || self.viewState == .takenPic ? geomotry.size.height - abs(self.cameraViewSize.height / 10) : geomotry.size.height)
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 15)
                        .animation(.spring(response: 0.30, dampingFraction: 0.6, blendDuration: 0))
                        .allowsHitTesting(self.viewState == .camera || self.viewState == .takenPic ? true : false)
                        .gesture(DragGesture(minimumDistance: self.viewState == .camera || self.viewState == .takenPic ? 0 : Constants.screenHeight).onChanged { value in
                            if self.viewState == .camera {
                                guard value.translation.height < 200 else { return }
                                guard value.translation.height > -1 else { return }
                                
                                self.cameraViewSize = value.translation
                            }
                        }.onEnded { value in
                            if self.viewState == .camera {
                                if self.cameraViewSize.height > 150 {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.viewState = .closed
                                }
                                if self.cameraViewSize.height == 0 {
                                    self.cameraFoucsPoint = value.location
                                } else {
                                    self.cameraViewSize = .zero
                                }
                            }
                        })
                }
            }
            
            //MARK: Undefined View
            VStack(alignment: .center) {
                Text("Please pick view:")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Button("Camera View", action: {
                    self.viewState = .camera
                })
                
                Button("Post View", action: {
                    self.viewState = .viewing
                })
            }.opacity(viewState == .undefined ? 1 : 0)
            .disabled(viewState == .undefined ? false : true)
        }
    }
}
