//
//  DiscoverCarouselSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift

struct DiscoverBannerData: Identifiable, Hashable {
    var id = UUID()
    var groupName: String
    var memberCount: Int
    var description: String
    var groupImg: String
    var backgroundImg: String
    var catagoryImg: String
}

//MARK: Carousel View
struct DiscoverCarousel : UIViewRepresentable {
    var width : CGFloat
    @Binding var page : Int
    @Binding var dataArray: [DiscoverBannerData]
    @Binding var dataArrayCount: Int
    @State var scrollOffset: CGFloat = CGFloat()
    var height : CGFloat
    
    func makeCoordinator() -> Coordinator {
        return DiscoverCarousel.Coordinator(parent1: self)
    }

    func makeUIView(context: Context) -> UIScrollView{
        // ScrollView Content Size...
        let total = width * CGFloat(dataArrayCount)
        let view = UIScrollView()
        view.isPagingEnabled = true
        //1.0  For Disabling Vertical Scroll....
        view.contentSize = CGSize(width: total, height: 1.0)
        view.bounces = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.delegate = context.coordinator
        
        // Now Going to  embed swiftUI View Into UIView...
        let view1 = UIHostingController(rootView: DiscoverListView(page: self.$page, dataArray: self.$dataArray))
        view1.view.frame = CGRect(x: 0, y: 0, width: total, height: self.height)
        view1.view.backgroundColor = .clear
        view.addSubview(view1.view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        let total = width * CGFloat(dataArrayCount)
        uiView.contentSize = CGSize(width: total, height: 1.0)
    }
    
    class Coordinator : NSObject,UIScrollViewDelegate{
        var parent : DiscoverCarousel
        
        init(parent1: DiscoverCarousel) {
            parent = parent1
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Using This Function For Getting Currnet Page
        
            let page = Int(scrollView.contentOffset.x / (Constants.screenWidth * 0.55))
            self.parent.page = page
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.parent.scrollOffset = scrollView.contentOffset.x
        }
    }
}

//MARK: Discover List View
struct DiscoverListView : View {
    @EnvironmentObject var auth: AuthModel
    @Binding var page : Int
    @Binding var dataArray: [DiscoverBannerData]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(self.dataArray, id: \.self) { data in
                DiscoverBannerCell(groupName: data.groupName, memberCount: data.memberCount, description: data.description, groupImg: data.groupImg, backgroundImg: data.backgroundImg, catagoryImg: data.catagoryImg)
                    .frame(width: Constants.screenWidth * 0.55)
            }
        }
    }
}

// MARK: Discover Cell
struct DiscoverBannerCell: View, Identifiable {
    let id = UUID()
    @State var groupName: String
    @State var memberCount: Int
    @State var description: String
    @State var groupImg: String
    @State var backgroundImg: String
    @State var catagoryImg: String
    @State private var actionState: Int? = 0

    var body: some View {
        ZStack {
            NavigationLink(destination: self.dialogDetail().edgesIgnoringSafeArea(.all), tag: 1, selection: self.$actionState) {
                EmptyView()
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.actionState = 1
            }) {
                ZStack(alignment: .top) {
                    Image(self.backgroundImg)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .cornerRadius(10)
                        .clipped()

                    VStack(alignment: .center, spacing: 0) {
                        Image(self.groupImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .cornerRadius(55 / 4)
                            .padding(.bottom, 5)
                            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(self.groupName)
                                .font(.system(size: 22))
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .foregroundColor(Color.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(self.memberCount > 1 ? "\(self.memberCount) members" : "be one of the first to join this group!")
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
                                }.frame(width: Constants.screenWidth * 0.50 - 50, height: 36, alignment: .center)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }.buttonStyle(ClickMiniButtonStyle())
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2.5)
                            .padding(.bottom, 5)
                        }
                    }.padding(.top, 60)
                    .padding()
                }
                .background(Color("buttonColor"))
                .frame(minHeight: 280, maxHeight: 360)
                .cornerRadius(20)
                .padding(.horizontal, 15)
            }.buttonStyle(ClickMiniButtonStyle())
        }
    }
    
    func dialogDetail() -> some View {
        Text("more dialog detail here lol...")
    }
}

//MARK: UIPageControl
struct DiscoverPageControl : UIViewRepresentable {
    @Binding var page : Int
    @Binding var dataArrayCount: Int
    @State var color: String = ""
    
    func makeUIView(context: Context) -> UIPageControl {
        let view = UIPageControl()
        if self.color == "white" {
            view.currentPageIndicatorTintColor = .white
            view.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
        } else {
            view.currentPageIndicatorTintColor = UIColor.black.withAlphaComponent(0.8)
            view.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
        }
        view.numberOfPages = dataArrayCount
        return view
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        // Updating Page Indicator When Ever Page Changes....
        DispatchQueue.main.async {
            uiView.currentPage = self.page
            uiView.numberOfPages = dataArrayCount
        }
    }
}

