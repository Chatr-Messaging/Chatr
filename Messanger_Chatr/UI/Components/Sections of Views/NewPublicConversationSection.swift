//
//  NewPublicConversationSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 4/6/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Firebase

struct publicTag: Identifiable, Hashable {
    var id = UUID().uuidString
    var title: String = ""
    var selected: Bool = false
    var isExceeded: Bool = false // To Stop Auto Update...
}

struct NewPublicConversationSection: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel = EditProfileViewModel()
    @StateObject var imagePicker = KeyboardCardViewModel()
    @Binding var creatingDialog: Bool
    @Binding var isNotPresent: Bool
    @Binding var groupName: String
    @Binding var description: String
    @Binding var inputImage: UIImage?
    @State var groupImage: Image? = nil
    @Binding var selectedTags: [publicTag]
    @State var descriptionHeight: CGFloat = 0
    @State var publicTags: [publicTag] = []
    @State private var showImagePicker: Bool = false

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
                                if (groupImage == nil) {
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
                                    groupImage?.resizable().scaledToFill().clipped().frame(width: 80, height: 80).cornerRadius(20)
                                        .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                                }

                                Text("Change Group Picture")
                                    .font(.none)
                                    .fontWeight(.none)
                                    .foregroundColor(.blue)
                                    .padding(.top, 5)
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
                //MARK: FullName Section
                VStack {
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.secondary)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                        
                        TextField("Name", text: $groupName)
                            .foregroundColor(.primary)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .font(.system(size: 20, weight: self.groupName.count > 0 ? .semibold : .regular, design: .default))

                        Spacer()
                    }.padding(.horizontal)
                    .padding(.vertical, 2)
                    .padding(.top, 2)
                    .contentShape(Rectangle())

                    Divider()
                        .frame(width: Constants.screenWidth - 70)
                        .offset(x: 30)
                }
                
                //MARK: Description Section
                VStack() {
                    HStack(alignment: .top) {
                        VStack() {
                            Image(systemName: "note.text")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.secondary)
                                .frame(width: 20, height: 20, alignment: .center)
                                .padding(.trailing, 5)

                            Text("\(220 - self.description.count)")
                                .font(.subheadline)
                                .fontWeight(self.description.count > 220 ? .bold : .none)
                                .foregroundColor(self.description.count > 220 ? .red : .secondary)
                                .padding(.trailing, 5)
                        }

                        ZStack(alignment: .topLeading) {
                            ResizableTextField(imagePicker: self.imagePicker, height: self.$descriptionHeight, text: self.$description)
                                .padding(.horizontal, 2.5)
                                .padding(.trailing, 5)
                                .font(.none)
                                .foregroundColor(self.description != "Description" ? .primary : .secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(5)
                                .offset(x: -12.5, y: -10)
                            
                            Text("Description")
                                .font(.none)
                                .fontWeight(.none)
                                .foregroundColor(Color("placeholderText"))
                                .opacity(self.description != "" ? 0 : 1)
                                .offset(x: -5)
                        }
                    }

                    Divider()
                        .frame(width: Constants.screenWidth - 70)
                        .offset(x: 30)
                }.padding(.horizontal)
                .padding(.vertical, 8)
                .frame(height: 100)

                //MARK: Tags Section
                VStack() {
                    HStack(alignment: .top) {
                        Image(systemName: "tag.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.secondary)
                            .frame(width: 20, height: 20, alignment: .center)
                            .offset(x: 20)

                        ScrollView {
                            FlexibleView(data: self.publicTags, spacing: 7.5, alignment: .leading) { item in
                                Text("#" + "\(item.title)")
                                    .fontWeight(.medium)
                                    .padding(.vertical, 7.5)
                                    .padding(.horizontal)
                                    .foregroundColor(item.selected ? Color.black : Color.primary)
                                    .background(RoundedRectangle(cornerRadius: 10).stroke(item.selected ? Color.blue : Color.black, lineWidth: 1.5).background(item.selected ? Color("interactions_selected") : Color("SegmentSliderColor")).cornerRadius(10))
                                    .lineLimit(1)
                                    .fixedSize()
                                    .onTapGesture {
                                        if self.selectedTags.count <= 1 || self.selectedTags.contains(where: { $0.id == item.id }) {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            if let foundIndex = self.publicTags.firstIndex(of: item) {
                                                self.publicTags[foundIndex].selected.toggle()
                                            }

                                            if self.selectedTags.contains(where: { $0.id == item.id }) {
                                                self.selectedTags.removeAll(where: { $0.id == item.id })
                                            } else {
                                                self.selectedTags.append(item)
                                            }
                                        } else {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }
                            }.offset(x: 25)
                            .padding(.trailing, 20)
                        }.frame(maxHeight: 175)
                    }
                }
            })

            HStack(alignment: .center) {
                Text("public group chats can have up to 100 occupants (for now) and provides more options to maintain and grow your audience")
                    .font(.caption)
                    .fontWeight(.none)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }.padding(.horizontal, 20)
            .padding(.vertical, 30)
        }.onAppear() {
            self.loadTags(completion: {  })
        }.onDisappear() {
            self.description = ""
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        groupImage = Image(uiImage: inputImage)
    }

    func loadTags(completion: @escaping () -> ()) {
        let marketplaceTags = Database.database().reference().child("Marketplace").child("tags")

        self.publicTags.removeAll()
        marketplaceTags.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                for i in dict {
                    self.publicTags.append(publicTag(title: i.key))
                }

                completion()
            } else {
                completion()
            }
        })
    }
}
