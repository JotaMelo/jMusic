//
//  DestinationServiceProviding.swift
//  jMusic
//
//  Created by Jota Melo on 27/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

typealias PlaylistReturnBlock = (Playlist?, Error?) -> Void
typealias TrackSearchBlock = (SearchResult?, [Search], Error?) -> Void

protocol DestinationServiceProviding {
    
    var regionIdentifier: String { get }
    
    var service: Service { get }

    func startAuthenticationWith(handler: ErrorBlock?)
    
    func createPlaylist(name: String, callback: PlaylistReturnBlock?)
    
    func retrieve(playlist: Playlist, callback: PlaylistReturnBlock?)
    
    func find(track: Track, callback: TrackSearchBlock?)
    
    func addTrack(fromSearchResult searchResult: SearchResult, toPlaylist playlist: Playlist, callback: ErrorBlock?)
    
    func addTrack(withID trackID: String, toPlaylist playlist: Playlist, callback: ErrorBlock?)
}
