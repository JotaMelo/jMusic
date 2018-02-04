//
//  MappableTests.swift
//  jMusic
//
//  Created by Jota Melo on 01/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import XCTest
import Foundation

@testable import jMusic

enum PizzaSize: Int {
    case small
    case medium
    case large
}

struct Pizza: Mappable {
    
    let pizzaID: Int
    let name: String
    var size: PizzaSize
    var numberOfIngredients: Int?
    
    init(mapper: Mapper) {
        
        self.pizzaID = mapper.keyPath("pizza_id")
        self.name = mapper.keyPath("name")
        self.size = mapper.keyPath("size")
        self.numberOfIngredients = mapper.keyPath("number_of_ingredients")
    }
}

struct User: Mappable {
    
    var id: Int
    var userName: String
    var email: String
    var isFirstLogin: Bool
    var likesPizza: Bool
    var registerDate: Date
    var favoritePizza: Pizza
    var orderedPizzas: [Pizza]
    var favoritePizzaName: String
    var secondPizzaName: String
    var nestedTest: String
    
    init(mapper: Mapper) {
        
        mapper.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        self.id = mapper.keyPath("id")
        self.userName = mapper.keyPath("user_name")
        self.email = mapper.keyPath("email")
        self.isFirstLogin = mapper.keyPath("is_first_login")
        self.likesPizza = mapper.keyPath("likes_pizza")
        self.registerDate = mapper.keyPath("register_date")
        self.favoritePizza = mapper.keyPath("favorite_pizza")
        self.orderedPizzas = mapper.keyPath("OrderedPizzas")
        self.favoritePizzaName = mapper.keyPath("favorite_pizza.name")
        self.secondPizzaName = mapper.keyPath("OrderedPizzas.1.name")
        self.nestedTest = mapper.keyPath("OrderedPizzas.1.testDictionary.nested.0.key")
    }
}

class MappableTests: XCTestCase {

    func testModels() {
        
        let bundle = Bundle(for: type(of: self))
        let testDictionary = try! JSONSerialization.jsonObject(with: try! Data(contentsOf: bundle.url(forResource: "mappableTestDictionary1", withExtension: "json")!), options: []) as! [String: Any]
        
        let user = User(dictionary: testDictionary)
        
        print(user.nestedTest)
        
        XCTAssertEqual(user.id, 123)
        XCTAssertEqual(user.userName, "fulana22k")
        XCTAssertEqual(user.email, "fulana22k@hotmail.com")
        XCTAssert(user.isFirstLogin)
        XCTAssert(user.likesPizza)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        XCTAssertEqual(user.registerDate, dateFormatter.date(from: "2015/08/21 15:45:45"))
        
        XCTAssertEqual(user.favoritePizza.pizzaID, 5)
        XCTAssertEqual(user.favoritePizza.name, "Catuperoni")
        XCTAssertEqual(user.favoritePizzaName, "Catuperoni")
        XCTAssertEqual(user.favoritePizza.size, .medium)
        XCTAssertNil(user.favoritePizza.numberOfIngredients)
        XCTAssertEqual(user.orderedPizzas.count, 2)
        
        XCTAssertEqual(user.orderedPizzas.first!.pizzaID, 5)
        XCTAssertEqual(user.orderedPizzas.first!.name, "Catuperoni")
        XCTAssertEqual(user.orderedPizzas.first!.size, .large)
        XCTAssertEqual(user.orderedPizzas.first!.numberOfIngredients, 3)
        
        XCTAssertEqual(user.orderedPizzas.last!.pizzaID, 10)
        XCTAssertEqual(user.orderedPizzas.last!.name, "Calabresa")
        XCTAssertEqual(user.secondPizzaName, "Calabresa")
        XCTAssertEqual(user.orderedPizzas.last!.size, .small)
        XCTAssertNil(user.orderedPizzas.last!.numberOfIngredients)
        
        XCTAssertEqual(user.nestedTest, "value123")
    }
}
