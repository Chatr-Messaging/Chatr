//
//  Messanger_ChatrTests.swift
//  Messanger_ChatrTests
//
//  Created by Brandon Shaw on 11/24/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import XCTest
//@testable import Messanger_Chatr

class Messanger_ChatrTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            if #available(iOS 14.0, *) {
                measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
                    XCUIApplication().launch()
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }

}
