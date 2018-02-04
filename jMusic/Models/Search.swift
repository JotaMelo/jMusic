//
//  Search.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

protocol Search {
    var query: String { get }
    var date: Date { get }
    var results: [SearchResult] { get }
}
