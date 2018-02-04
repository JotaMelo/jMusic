//
//  SearchResult.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation
import RealmSwift

protocol SearchResult {
    
    var service: Service { get }
    var trackID: String { get }
    var trackName: String { get }
    var artist: String { get }
    var album: String { get }
    var albumCoverURL: URL? { get }
    var duration: TimeInterval { get }
    var isStreamable: Bool { get }
}

