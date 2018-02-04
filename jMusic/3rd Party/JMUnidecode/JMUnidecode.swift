//
//  JMUnidecode.swift
//
//  Created by Jota Melo on 31/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

class JMUnidecode {
    
    private static let sharedInstance = JMUnidecode()
    private var table: [String: [String]]?
    
    public static func preload() {
        _ = self.sharedInstance.characterListFor(section: 0)
    }
    
    public static func unidecode(_ string: String) -> String {
    
        var unidecodedString = ""
        
        for unicodeScalar in string.unicodeScalars {
            if unicodeScalar.value < 0x80 { // Basic ASCII
                unidecodedString.append(String(unicodeScalar))
                continue
            }
            
            let section = unicodeScalar.value >> 8 // Remove last 2 hex digits
            let position = unicodeScalar.value % 256 // Last two hex digits
            
            let list = self.sharedInstance.characterListFor(section: section)
            if let list = list, Int(position) < list.count {
                unidecodedString.append(list[Int(position)])
            }
        }
        
        return unidecodedString
    }
    
    private func characterListFor(section: UInt32) -> [String]? {
        
        if self.table == nil {
            guard let fileURL = Bundle.main.url(forResource: "JMUnidecodeData", withExtension: "json"),
            let fileData = try? Data(contentsOf: fileURL),
            let jsonObject = try? JSONSerialization.jsonObject(with: fileData, options: []) else { return nil }
            
            self.table = jsonObject as? [String: [String]]
        }
        
        if let table = self.table {
            return table["\(section)"]
        }
        
        return nil
    }
}
