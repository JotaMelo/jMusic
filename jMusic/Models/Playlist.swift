//
//  PlaylistModel.swift
//  jMusic
//
//  Created by Jota Melo on 09/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

enum Service: String {
    case unspecified = "unspecified"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
}

enum PlaylistType: Int {
    case source
    case destination
}

protocol Playlist {
    var id: String { get }
    var name: String { get }
    var userID: String? { get }
    var type: PlaylistType { get }
    var service: Service { get }
    var tracks: [Track]? { get set }
}
