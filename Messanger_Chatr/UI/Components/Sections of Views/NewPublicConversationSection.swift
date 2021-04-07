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
    @State var bioText: String = ""
    @State var bioHeight: CGFloat = 0
    @State var didSave: Bool = true
    @State var showImagePicker: Bool = false
    @State private var image: Image? = nil
    @State private var inputImage: UIImage? = nil

    var body: some View {
        VStack {
            //MARK: Profile Picture Section
            HStack {
                Text("GROUP PICTURE:")
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
                                if (image == nil) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 80, height: 80, alignment: .center)
                                            .foregroundColor(Color("bgColor"))

                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.primary)
                                            .frame(width: 58, height: 58, alignment: .center)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                    }.shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                                } else {
                                    image?.resizable().scaledToFill().clipped().frame(width: 80, height: 80).cornerRadius(20)
                                        .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                                }

                                Text("Change Group Picture")
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
            }.background(Color("bgColor"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            .padding(.horizontal)
            .padding(.bottom, 5)
            .sheet(isPresented: self.$showImagePicker, onDismiss: self.loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            
            //MARK: Name & Bio Section
            HStack {
                Text("GROUP DETAILS:")
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
                        
                        TextField("Name", text: $fullNameText)
                            //.font(.system(size: 16, weight: .se, design: .default))
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
                                .foregroundColor(self.bioText != "Description" ? .primary : .secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(5)
                                .offset(x: -7, y: -10)
                                .onChange(of: self.bioText) { _ in
                                    self.didSave = false
                                }
                            
                            Text("Description")
                                .font(.none)
                                .fontWeight(.none)
                                .foregroundColor(Color("placeholderText"))
                                .opacity(self.bioText != "" ? 0 : 1)
                                .offset(x: -5)
                        }
                    }
                }.padding(.horizontal)
                .padding(.vertical, 8)
                .frame(height: 100)
            })

            HStack(alignment: .center) {
                Text("public group chats can have up to 100 occupants (for now) and provides more options to maintain and grow your audience")
                    .font(.caption)
                    .fontWeight(.none)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }.padding(.horizontal, 20)
            .padding(.vertical, 30)
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        self.auth.setUserAvatar(image: inputImage, completion: { _ in })
    }
}
