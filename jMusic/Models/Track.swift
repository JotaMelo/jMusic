//
//  PlaylistTrack.swift
//  jMusic
//
//  Created by Jota Melo on 27/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

enum TrackStatus: Int {
    case unprocessed
    case error
    case notFound
    case found
}

protocol Track {
    
    var id: String { get }
    var name: String { get }
    var artist: String { get }
    var album: String { get }
    var albumCoverURL: URL? { get }
    var duration: TimeInterval { get }
    var service: Service { get }
    var status: TrackStatus { get set }
    
    var matchedResult: SearchResult? { get set }
    var searches: [Search] { get }
    var errorDescription: String? { get set }
}
