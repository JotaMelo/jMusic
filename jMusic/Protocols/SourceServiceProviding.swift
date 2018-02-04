
//
//  SourceServiceProviding.swift
//  jMusic
//
//  Created by Jota Melo on 27/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

typealias ErrorBlock = (Error?) -> Void
typealias AuthenticationBlock = (Bool, Error?) -> Void
typealias UserPlaylistsBlock = (PlaylistPaging?, Error?) -> Void
typealias PlaylistTracksBlock = (Playlist?, [Track]?, Error?) -> Void

protocol SourceServiceProviding {

    var authenticated: Bool { get }
    
    var username: String? { get }
    
    var service: Service { get }

    func parsePlaylistURL(_ playlistURLString: String) -> URL?
    
    func startAuthentication(handler: AuthenticationBlock?)
    
    func finishAuthenticationWithURL(_ url: URL)
    
    func persistAuthentication()
    
    func logout()
    
    func userPlaylists(_ callback: UserPlaylistsBlock?)
    
    func tracksFor(playlist: Playlist, callback: PlaylistTracksBlock?)
    
    func tracksFor(playlistURL: URL, callback: PlaylistTracksBlock?)
}
