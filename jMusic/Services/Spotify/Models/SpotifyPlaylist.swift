//
//  SpotifyPlaylist.swift
//  jMusic
//
//  Created by Jota Melo on 10/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

struct SpotifyPlaylist: Playlist, Mappable {
    
    let id: String 
    let name: String
    let userID: String?
    let type: PlaylistType
    let service: Service
    var tracks: [Track]?
    
    init(mapper: Mapper) {
        
        self.id = mapper.keyPath("id")
        self.name = mapper.keyPath("name")
        self.userID = mapper.keyPath("owner.id")
        self.type = .source
        self.service = .spotify
    }
}
