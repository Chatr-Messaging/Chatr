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
    var catagory: String
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
        
            let page = Int(scrollView.contentOffset.x / UIScreen.main.bounds.width)
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
    @State var openDiscoverContent: Bool = false
    @State var openPremiumContent: Bool = false
    @State var openAddressBookContent: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(self.dataArray, id: \.self) { data in
                DiscoverBannerCell(groupName: data.groupName, memberCount: data.memberCount, catagory: data.catagory, groupImg: data.groupImg, backgroundImg: data.backgroundImg, catagoryImg: data.catagoryImg)
                    .frame(width: Constants.screenWidth)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
            }
        }.padding(.vertical)
    }
}

// MARK: Discover Cell
struct DiscoverBannerCell: View, Identifiable {
    let id = UUID()
    @State var groupName: String
    @State var memberCount: Int
    @State var catagory: String
    @State var groupImg: String
    @State var backgroundImg: String
    @State var catagoryImg: String

    var body: some View {
        GeometryReader { geo in
            VStack() {
                HStack(alignment: .center) {
                    Image(self.groupImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 55, height: 55)
                        .cornerRadius(55 / 4)
                    
                    VStack(alignment: .leading, spacing: 2.5) {
                        Text(self.groupName)
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        
                        Text(self.memberCount > 1 ? "\(self.memberCount) members" : "be one of the first to join this group!")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    }.padding(.leading, 5)
                    
                    Spacer()
                }.padding()
                
                Spacer()
                HStack {
                    HStack {
                        HStack {
                            Image(systemName: self.catagoryImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 18, alignment: .center)
                                .foregroundColor(.black)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                            
                            Text(self.catagory)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                        }.padding(2.5).cornerRadius(2).background(Color.white.opacity(0.5))
                        
                        Spacer()
                        
                        Button(action: {
                            print("join: \(self.groupName)")
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18, alignment: .center)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                                
                                Text("Join Group")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                            }.padding(2.5).cornerRadius(2).background(Color.blue)
                        }
                    }
                }.padding()
            }.background(Image(self.backgroundImg).resizable().scaledToFill())
            .cornerRadius(25)
            .padding(.horizontal)
            .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
        }
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

