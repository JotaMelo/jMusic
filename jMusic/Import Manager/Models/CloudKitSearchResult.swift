//
//  CloudKitSearchResult.swift
//  jMusic
//
//  Created by Jota Melo on 18/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

struct CloudKitSearchResult: SearchResult, Mappable {
    
    var service = Service.appleMusic
    var trackID: String
    var trackName: String
    var artist: String
    var album: String
    var albumCoverURL: URL?
    var duration: TimeInterval
    var isStreamable: Bool
    
    init(mapper: Mapper) {
        
        self.trackID = mapper.keyPath("destinationServiceTrackID")
        self.trackName = mapper.keyPath("trackName")
        self.artist = mapper.keyPath("artist")
        self.album = mapper.keyPath("album")
        self.albumCoverURL = mapper.keyPath("albumCoverURL")
        self.duration = mapper.keyPath("duration")
        self.isStreamable = mapper.keyPath("isStreamable")
    }
}

