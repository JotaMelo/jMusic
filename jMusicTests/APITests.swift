//
//  APITests.swift
//  jMusic
//
//  Created by Jota Melo on 29/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import XCTest
import Foundation

@testable import jMusic

class APITests: XCTestCase {
    
    var request: APIRequest?

    func testAPIHelpers() {
        
        let testDictionary: [String: Any] = ["id": "123",
                                            "abc": [["a": "b",
                                                     "b": "c",
                                                     "c": [1, 2, 3, ["x": "y"]]],
                                                    ],
                                            "ddd": ["b": "j",
                                                    "c": ["b": "p", "c": Data()]]]
        
        let flattenedTestDictionary: [String: Any] = ["id": "123",
                                                      "abc[0][a]": "b",
                                                      "abc[0][b]": "c",
                                                      "abc[0][c][0]": 1,
                                                      "abc[0][c][1]": 2,
                                                      "abc[0][c][2]": 3,
                                                      "abc[0][c][3][x]": "y",
                                                      "ddd[b]": "j",
                                                      "ddd[c][b]": "p",
                                                      "ddd[c][c]": Data()]
        
        let flattenedDictionary = API.flatten(dictionary: testDictionary)
        
        XCTAssert(NSDictionary(dictionary: flattenedDictionary).isEqual(to: flattenedTestDictionary))
        XCTAssert(API.checkForDataObjectsIn(Array(testDictionary.values)))
    }
    
    func testAPIRequest() {
        
        let expectation = self.expectation(description: "APIRequest")
        let cacheExpectation = self.expectation(description: "APIRequestCached")

        let testDictionary: [String: Any] = ["id": "123",
                                             "abc": [["a": "b",
                                                      "b": "c",
                                                      "c": [1, 2, 3, ["x": "y"]]],
                                                    ],
                                             "ddd": ["b": "j",
                                                     "c": ["b": "p"]]]

        APICacheManager.shared.clearCache()

        self.request = APIRequest(method: .post, path: "randomness/123echo123", parameters: testDictionary, urlParameters: nil, cacheOption: .networkOnly, completion: { [unowned self] (response, error, cache) in

            XCTAssert(!cache)
            XCTAssert(error == nil)
            XCTAssert(NSDictionary(dictionary: response as! [String: Any]).isEqual(to: testDictionary))

            expectation.fulfill()

            self.request?.cacheOption = .cacheOnly
            self.request?.completionBlock = { [unowned self] (response, error, cache) in

                XCTAssert(cache)
                XCTAssert(error == nil)
                XCTAssert(NSDictionary(dictionary: response as! [String: Any]).isEqual(to: testDictionary))

                cacheExpectation.fulfill()
                self.request = nil
            }

            // cache save is async, so wait a bit to make sure it had time to save
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                _ = self.request?.makeRequest()
            })
        })
        self.request?.baseURL = URL(string: "http://jota.pm")!
        _ = self.request?.makeRequest()

        self.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCache() {
        
        let cacheManager = APICacheManager.shared

        // checking it doesn't crash
        _ = cacheManager.cacheFileNameWith(path: "randomness/123echo123", method: "GET", parameters: nil)
        _ = cacheManager.cacheFileNameWith(path: "randomness/123echo123", method: "POST", parameters: ["a": ["b": "c"]])
        _ = cacheManager.cacheFileNameWith(path: "randomness/123echo123", method: "POST", parameters: ["a": ["b": Data()]])

        // checking consistent results
        let imageData = UIImagePNGRepresentation(UIImage(named: "testImage.jpg")!)!
        let cacheFileName1 = cacheManager.cacheFileNameWith(path: "randomness/123echo123", method: "PUT", parameters: ["a": ["b": imageData]])
        let cacheFileName2 = cacheManager.cacheFileNameWith(path: "randomness/123echo123", method: "PUT", parameters: ["a": ["b": imageData]])
        XCTAssertEqual(cacheFileName1, cacheFileName2)

        // saving this image to cache should go over the default 1MB in memory cache limit
        cacheManager.write(data: ["a": ["b": imageData]], toCacheFile: cacheFileName2)

        let cacheExpectation = self.expectation(description: "Cache")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssert(!cacheManager.isFilePresentInMemoryCache(fileName: cacheFileName2))

            cacheManager.callBlock({ (response, error, cache) in
                XCTAssert(cache)
                XCTAssert(NSDictionary(dictionary: response as! [String: Any]).isEqual(to: ["a": ["b": imageData]]))

                cacheExpectation.fulfill()
            }, ifCacheExistsForFileName: cacheFileName2)
        }

        self.waitForExpectations(timeout: 5, handler: nil)
    }
}
