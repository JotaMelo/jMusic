//
//  AppleMusicPlaylist.swift
//  jMusic
//
//  Created by Jota Melo on 11/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

struct AppleMusicPlaylist: Playlist {
    
    let id: String
    let name: String
    var userID: String?
    let type: PlaylistType
    let service: Service
    var tracks: [Track]?
    
    init(id: String, name: String) {
        
        self.id = id
        self.name = name
        self.type = .destination
        self.service = .appleMusic
    }
}
