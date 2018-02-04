//
//  JMUnidecodeTests.swift
//  jMusic
//
//  Created by Jota Melo on 31/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import XCTest

@testable import jMusic

class JMUnidecodeTests: XCTestCase {

    func testASCII() {
        self.measure {
            for i in 0..<128 {
                let character = String(i)
                let unidecodedCharacter = JMUnidecode.unidecode(character)
                
                XCTAssertEqual(character, unidecodedCharacter)
            }
        }
    }
    
    func testBMP() {
        self.measure {
            for i in 0..<0x10000 {
                // Just check that it doesn't throw an exception
                
                let character = String(i)
                _ = JMUnidecode.unidecode(character)
            }
        }
    }
    
    func testCirclesLatin() {
        self.measure {
            for i in 0..<26 {
                let a = String(UnicodeScalar(Int(("a" as NSString).character(at: 0)) + i)!)
                let b = JMUnidecode.unidecode(String(UnicodeScalar(0x24d0 + i)!))
                
                XCTAssertEqual(a, b)
            }
        }
    }
    
    func testMathematicalLatin() {
        // 13 consecutive sequences of A-Z, a-z with some codepoints
        // undefined. We just count the undefined ones and don't check
        // positions.
        
        self.measure {
            var empty = 0
            
            for i in 0x1d400..<0x1d6a4 {
                let a: String
                
                if i % 52 < 26 {
                    a = String(UnicodeScalar(Int(("A" as NSString).character(at: 0)) + i % 26)!)
                } else {
                    a = String(UnicodeScalar(Int(("a" as NSString).character(at: 0)) + i % 26)!)
                }
                
                let b = JMUnidecode.unidecode(String(UnicodeScalar(i)!))
                if b.isEmpty {
                    empty += 1
                } else {
                    XCTAssertEqual(a, b)
                }
            }
            
            XCTAssertEqual(empty, 24)
        }
    }
    
    func testMathematicalDigits() {
        self.measure {
            for i in 0x1d7ce..<0x1d800 {
                let a = String(UnicodeScalar(Int(("0" as NSString).character(at: 0)) + (i - 0x1d7ce) % 10)!)
                let b = JMUnidecode.unidecode(a)
                
                XCTAssertEqual(a, b)
            }
        }
    }
    
    func testSpecific() {
        JMUnidecode.preload()
        
        let tests = [["Hello, World!", "Hello, World!"],
                     ["'\"\r\n", "'\"\r\n"],
                     ["ČŽŠčžš", "CZSczs"],
                     ["ア", "a"],
                     ["α", "a"],
                     ["château", "chateau"],
                     ["viñedos", "vinedos"],
                     ["北亰", "Bei Jing "],
                     ["Efﬁcient", "Efficient"],
                     
                     // https://github.com/iki/unidecode/commit/4a1d4e0a7b5a11796dc701099556876e7a520065
                     ["příliš žluťoučký kůň pěl ďábelské ódy", "prilis zlutoucky kun pel dabelske ody"],
                     ["PŘÍLIŠ ŽLUŤOUČKÝ KŮŇ PĚL ĎÁBELSKÉ ÓDY", "PRILIS ZLUTOUCKY KUN PEL DABELSKE ODY"],
                    
                     // Table that doesn't exist
                     ["\u{a500}", ""],
                    
                     // Table that has less than 256 entries
                     ["\u{1eff}", ""]
                    ]
        
        self.measure {
            for test in tests {
                XCTAssertEqual(JMUnidecode.unidecode(test.first!), test.last!)
            }
        }

    }
}
