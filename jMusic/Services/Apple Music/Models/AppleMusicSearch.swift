//
//  AppleMusicSearch.swift
//  jMusic
//
//  Created by Jota Melo on 11/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

struct AppleMusicSearch: Search {
    
    var query: String
    var date: Date
    var results: [SearchResult]
}
