//
//  SpotifyPlaylistPage.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

struct SpotifyPlaylistPage: PlaylistPaging, Mappable {
    
    private var limit: Int
    private var offset: Int
    private var total: Int
    private var next: String?
    private var realItems: [SpotifyPlaylist]
    
    var items: [Playlist] {
        return self.realItems
    }
    
    var hasNextPage: Bool {
        return self.next != nil
    }
    
    init(mapper: Mapper) {
        
        self.limit = mapper.keyPath("limit")
        self.offset = mapper.keyPath("offset")
        self.total = mapper.keyPath("total")
        self.next = mapper.keyPath("next")
        self.realItems = mapper.keyPath("items")
    }
    
    func loadNextPage(_ callback: PageBlock?) {
        
        SpotifyAPI.userPlaylists(callback: { playlistPage, error, cache in
            callback?(playlistPage, error)
        }, offset: self.offset + self.limit, limit: self.limit)
    }
}
