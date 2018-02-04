//
//  SpotifyTrack.swift
//  jMusic
//
//  Created by Jota Melo on 10/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

struct SpotifyTrack: Track, Mappable {
    
    let id: String
    let name: String
    let artist: String
    let album: String
    let albumCoverURL: URL?
    let duration: TimeInterval
    let service: Service
    
    var status: TrackStatus
    var matchedResult: SearchResult?
    var searches: [Search] = []
    var errorDescription: String?
    
    init(mapper: Mapper) {
        
        self.id = mapper.keyPath("track.id") ?? UUID().uuidString // "local tracks" on Spotify don't have IDs but we really need an ID
        self.name = mapper.keyPath("track.name")
        self.artist = mapper.keyPath("track.artists.0.name")
        self.album = mapper.keyPath("track.album.name")
        self.albumCoverURL = mapper.keyPath("track.album.images.0.url")
        self.duration = mapper.keyPath("track.duration_ms") / 1000
        self.service = .spotify
        self.status = .unprocessed
    }
}
