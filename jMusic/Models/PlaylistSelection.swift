//
//  PlaylistSelection.swift
//  jMusic
//
//  Created by Jota Melo on 1/11/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import Foundation

class PlaylistSelection {
    
    var isFullSelection: Bool {
        guard let tracks = self.playlist.tracks else { return false }
        return tracks.count == self.tracks.count
    }
    
    var playlist: Playlist
    var tracks: [Track]
    
    init(playlist: Playlist, tracks: [Track]) {
        self.playlist = playlist
        self.tracks = tracks
    }
}
