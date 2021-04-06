//
//  NewPublicConversationSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 4/6/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct NewPublicConversationSection: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel = EditProfileViewModel()
    @StateObject var imagePicker = KeyboardCardViewModel()
    @State var fullNameText: String = ""
    @State var bioText: String = "Bio"
    @State var bioHeight: CGFloat = 0
    @State var loadingSave: Bool = false
    @State var didSave: Bool = true
    @State var showImagePicker: Bool = false
    @State private var image: Image? = nil
    @State private var inputImage: UIImage? = nil

    var body: some View {
        VStack {
            //MARK: Profile Picture Section
            HStack {
                Text("PROFILE PICTURE:")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .offset(y: 2)
                Spacer()
            }.padding(.top, 10)
            
            //Profile Image
            VStack(alignment: .center) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.showImagePicker.toggle()
                    }
                }, label: {
                    VStack {
                        HStack(alignment: .center) {
                            Spacer()
                            VStack(alignment: .center) {
                                if let avitarURL = self.auth.profile.results.first?.avatar {
                                    WebImage(url: URL(string: avitarURL))
                                        .resizable()
                                        .placeholder{ Image("empty-profile").resizable().frame(width: 80, height: 80, alignment: .center).scaledToFill() }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 80, height: 80, alignment: .center)
                                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
                                }
                                
                                Text("Change Profile Picture")
                                    .font(.none)
                                    .fontWeight(.none)
                                    .foregroundColor(.blue)
                                    .padding(.top, 10)
                            }.padding(.horizontal)
                            .offset(x: 20)
                            .contentShape(Rectangle())
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .resizable()
                                .font(Font.title.weight(.bold))
                                .scaledToFit()
                                .frame(width: 7, height: 15, alignment: .center)
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }.padding(.vertical, 10)
                }).buttonStyle(changeBGButtonStyle())
            }.background(Color("buttonColor"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            .padding(.horizontal)
            .padding(.bottom, 5)
            .sheet(isPresented: self.$showImagePicker, onDismiss: self.loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            
            //MARK: Name & Bio Section
            HStack {
                Text("NAME & BIO:")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .offset(y: 2)
                Spacer()
            }.padding(.top, 10)
            
            self.viewModel.styleBuilder(content: {
                //FullName Section
                VStack {
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.secondary)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                        
                        TextField("Full Name", text: $fullNameText)
                            //.font(.system(size: 24, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                            .onChange(of: self.fullNameText) { _ in
                                self.didSave = false
                            }

                        Spacer()
                    }.padding(.horizontal)
                    .padding(.vertical, 6)
                    .padding(.top, 2)
                    .contentShape(Rectangle())

                    Divider()
                        .frame(width: Constants.screenWidth - 70)
                        .offset(x: 30)
                }.onAppear() {
                    self.fullNameText = self.auth.profile.results.first?.fullName ?? ""
                }
                
                //Bio Section
                VStack() {
                    HStack(alignment: .top) {
                        VStack() {
                            Image(systemName: "note.text")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.secondary)
                                .frame(width: 20, height: 20, alignment: .center)
                                .padding(.trailing, 5)
                            
                            Text("\(220 - self.bioText.count)")
                                .font(.subheadline)
                                .fontWeight(self.bioText.count > 220 ? .bold : .none)
                                .foregroundColor(self.bioText.count > 220 ? .red : .secondary)
                                .padding(.trailing, 5)
                        }
                        
                        ZStack(alignment: .topLeading) {
                            ResizableTextField(imagePicker: self.imagePicker, height: self.$bioHeight, text: self.$bioText)
                                .padding(.horizontal, 2.5)
                                .padding(.trailing, 5)
                                .font(.none)
                                .foregroundColor(self.bioText != "Bio" ? .primary : .secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(5)
                                .offset(x: -7, y: -10)
                                .onChange(of: self.bioText) { _ in
                                    self.didSave = false
                                }
                            
                            Text("Bio")
                                .font(.none)
                                .fontWeight(.none)
                                .foregroundColor(.secondary)
                                .opacity(self.bioText != "" ? 0 : 1)
                                .padding(.leading, 5)
                        }
                    }
                }.padding(.horizontal)
                .padding(.vertical, 8)
                .frame(height: 100)
                .onAppear() {
                    self.bioText = self.auth.profile.results.first?.bio ?? "Bio"
                }
            })
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        self.auth.setUserAvatar(image: inputImage, completion: { _ in })
    }
}
