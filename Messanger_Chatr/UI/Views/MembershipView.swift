//
//  MembershipView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/31/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Purchases

// MARK: Profile View
struct MembershipView: View {
    @EnvironmentObject var auth: AuthModel
    @State var selectedOption: Int = 2
    @State var openTerms: Bool = false

    @State var monthly: Purchases.Package?
    @State var threeMonthly: Purchases.Package?
    @State var yearly: Purchases.Package?
    
    var body: some View {
        VStack(alignment: .center) {
            
            //MARK: Header Section
            HStack {
                VStack(alignment: .leading) {
                    Text("Upgrade to")
                        .font(.body)
                        .foregroundColor(Color.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
                    
                    HStack(alignment: .bottom) {
                        Text("Chatr")
                            .font(.system(size: 38))
                            .fontWeight(.bold)
                            .foregroundColor(Color.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
                        
                        Text("Premium")
                            .font(.system(size: 38))
                            .fontWeight(.regular)
                            .foregroundColor(Color.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 2)
                    }
                }
                
                Spacer()
                Image("iconCoin")
                    .resizable()
                    .frame(width: 55, height: 55, alignment: .center)
                    .shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 10)
            }.padding(.top, 40)
            
            Spacer()
            
            //MARK: List Section
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 25) {
                        Spacer()
                        
                        //Seal the Deal
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.seal")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.trailing, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Seal the Deal")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
                                    .padding(.bottom, 0)
                                
                                Text("Receive a badge next to your name to help combat fake accounts.")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                                            
                        //Customize Theme
                        HStack(alignment: .top) {
                            Image(systemName: "paintbrush")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.trailing, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Customize Theme")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
                                    .padding(.bottom, 0)
                                
                                Text("Make it feel more at home by changing the background, icon, & more.")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                        
                        //Unlimited Storage
                        HStack(alignment: .top) {
                            Image(systemName: "lock.shield")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.trailing, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Ultimate Security")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
                                    .padding(.bottom, 0)
                                
                                Text("Enhance your security with an extra layer of verification.")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                    .foregroundColor(.white)
                                    .opacity(0.8)
                            }
                        }
                        
                        //Discovered Storage
//                        HStack(alignment: .top) {
//                            Image(systemName: "person.2")
//                                .resizable()
//                                .scaledToFit()
//                                .font(Font.title.weight(.bold))
//                                .frame(width: 40, height: 40, alignment: .center)
//                                .foregroundColor(.white)
//                                .padding(.trailing, 15)
//
//                            VStack(alignment: .leading) {
//                                Text("Support a Startup")
//                                    .font(.headline)
//                                    .fontWeight(.semibold)
//                                    .foregroundColor(.white)
//                                    .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 0)
//                                    .padding(.bottom, 0)
//
//                                Text("Supporting ensures this project lives on and features keep coming.")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
//                                    .foregroundColor(.white)
//                                    .opacity(0.8)
//                            }
//                        }
                    }
                    //}.frame(maxHeight: Constants.screenHeight / 3 + 25, alignment: .center)
                    .padding(.vertical)
                    
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.selectedOption = 1
                        }, label: {
                            ZStack(alignment: .bottom) {
                                ZStack(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Constants.snapPurpleGradient, lineWidth: self.selectedOption == 1 ? 8 : 0)
                                        .frame(width: (Constants.screenWidth / 3) - 29, height: (Constants.screenWidth / 3.5) - 5, alignment: .center)
                                    
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 25, height: (Constants.screenWidth / 3.5), alignment: .center)
                                        .foregroundColor(Color("bgColor").opacity(0.35))
                                    
                                    VStack {
                                        if let mon = monthly {
                                            Text("\(self.formattedPrice(for: mon))")
                                                .font(.title)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                        }
                                        
                                        Text("per month")
                                            .font(.footnote)
                                            .fontWeight(.regular)
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                            .foregroundColor(.white)
                                            .opacity(0.8)
                                    }
                                }.clipShape(RoundedRectangle(cornerRadius: 25, style: .circular))
                                .shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 20)
                                
                                ZStack(alignment: .center) {
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 40, height: 45, alignment: .bottom)
                                        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 0)
                                        .foregroundColor(.clear)
                                        .background(Constants.messageBlueGradient)
                                        .cornerRadius(30)
                                    
                                    Text("FREE \nTRIAL!")
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }.offset(y: 20)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                            }
                        }).scaleEffect(self.selectedOption == 1 ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0))
                        .buttonStyle(ClickButtonStyle())
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.selectedOption = 2
                        }, label: {
                            ZStack(alignment: .bottom) {
                                ZStack(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Constants.snapPurpleGradient, lineWidth: self.selectedOption == 2 ? 8 : 0)
                                        .frame(width: (Constants.screenWidth / 3) - 29, height: (Constants.screenWidth / 3.5) - 5, alignment: .center)
                                    
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 25, height: (Constants.screenWidth / 3.5), alignment: .center)
                                        .foregroundColor(Color("bgColor").opacity(0.35))

                                    VStack {
                                        if let threeMon = threeMonthly {
                                            Text("\(self.formattedPrice(for: threeMon))")
                                                .font(.title)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                        }
                                        
                                        Text("per 3 months")
                                            .font(.footnote)
                                            .fontWeight(.regular)
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                            .foregroundColor(.white)
                                            .opacity(0.8)
                                    }
                                }.clipShape(RoundedRectangle(cornerRadius: 25, style: .circular))
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                                
                                ZStack(alignment: .center) {
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 40, height: 40, alignment: .bottom)
                                        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 0)
                                        .foregroundColor(.clear)
                                        .background(Constants.messageBlueGradient)
                                        .cornerRadius(30)
                                    
                                    Text("12% OFF!")
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }.offset(y: 20)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                            }
                        }).scaleEffect(self.selectedOption == 2 ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0))
                        .buttonStyle(ClickButtonStyle())
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.selectedOption = 3
                        }, label: {
                            ZStack(alignment: .bottom) {
                                ZStack(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Constants.snapPurpleGradient, lineWidth: self.selectedOption == 3 ? 8 : 0)
                                        .frame(width: (Constants.screenWidth / 3) - 29, height: (Constants.screenWidth / 3.5) - 5, alignment: .center)
                                    
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 25, height: (Constants.screenWidth / 3.5), alignment: .center)
                                        .foregroundColor(Color("bgColor").opacity(0.35))

                                    VStack {
                                        if let yearz = self.yearly {
                                            Text("\(self.formattedPrice(for: yearz))")
                                                .font(.title)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                        }
                                        
                                        Text("per year")
                                            .font(.footnote)
                                            .fontWeight(.regular)
                                            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 0)
                                            .foregroundColor(.white)
                                            .opacity(0.8)
                                    }
                                }.clipShape(RoundedRectangle(cornerRadius: 25, style: .circular))
                                .shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 20)
                                
                                ZStack(alignment: .center) {
                                    Rectangle()
                                        .frame(width: (Constants.screenWidth / 3) - 40, height: 40, alignment: .bottom)
                                        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 0)
                                        .foregroundColor(.clear)
                                        .background(Constants.messageBlueGradient)
                                        .cornerRadius(30)
                                    
                                    Text("20% OFF!")
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }.offset(y: 20)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                            }
                        }).scaleEffect(self.selectedOption == 3 ? 1.1 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6, blendDuration: 0))
                        .buttonStyle(ClickButtonStyle())
                    }
                    
                    Spacer()
                    Button(action: {
                        if self.selectedOption == 1 {
                            if let mont = self.monthly {
                                self.auth.purchase(source: "profile_settings", product: mont)
                            }
                        } else if self.selectedOption == 2 {
                            if let threemont = self.threeMonthly {
                                self.auth.purchase(source: "profile_settings", product: threemont)
                            }
                        } else if self.selectedOption == 3 {
                            if let yearlyy = self.yearly {
                                self.auth.purchase(source: "profile_settings", product: yearlyy)
                            }
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "checkmark.seal")
                                .resizable()
                                .frame(width: 25, height: 25, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.trailing, 5)
                            
                            Text("JOIN PREMIUM")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }.buttonStyle(MainButtonStyle())
                    .frame(height: 50)
                    .frame(minWidth: 220, maxWidth: 280)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)

                    Button(action: {
                        self.auth.restorePurchase()
                    }) {
                        Text("restore subscription")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                    }.frame(minWidth: 100, maxWidth: 180)
                    .padding(.vertical, 5)

                    Button(action: {
                        self.openTerms.toggle()
                    }) {
                        Text("by joining Chatr Premium you agree \nto the Terms of Service & Privacy Policy")
                            .font(.caption)
                            .underline()
                            .fontWeight(.none)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                    }.frame(minWidth: 200, maxWidth: 280)
                    .padding(.bottom)
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: self.$openTerms, content: {
                        NavigationView {
                            TermsView(markdown: Constants.termsOfServiceMarkdown, navTitle: "Terms of Service")
                                .navigationBarTitle("Terms of Service")
                                .modifier(GroupedListModifier())
                                .environmentObject(self.auth)
                        }
                    })
                    
                    //Spacer()
                }
            }
        }.background(AnimatedGradientGradientBG().opacity(0.85))
        .padding(.horizontal)
        .onAppear() {
            Purchases.shared.offerings { (offerings, error) in
                if error == nil {
                    if let mont = offerings?.current?.monthly {
                        self.monthly = mont
                    }
                    if let threeMon = offerings?.current?.threeMonth {
                        threeMonthly = threeMon
                    }
                    if let yearr = offerings?.current?.annual {
                        yearly = yearr
                    }
                }
            }
        }
    }
    
    private func formattedPrice(for package: Purchases.Package) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        if let mont = self.monthly {
            formatter.locale = mont.product.priceLocale
        }
        return formatter.string(from: package.product.price)!
    }
}

