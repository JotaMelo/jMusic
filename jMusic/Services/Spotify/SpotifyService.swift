//
//  SpotifyService.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

class SpotifyService: NSObject, SourceServiceProviding {
    
    var authenticated: Bool {
        return SpotifyAPI.credentialsManager != nil
    }
    
    var username: String? {
        guard let credentialsManager = SpotifyAPI.credentialsManager else { return nil }
        return credentialsManager.userName
    }
    
    var service = Service.spotify
    var authenticationCallback: AuthenticationBlock?
    
    private var authenticationSession: Any?
    private var safariDelegate: SpotifyServiceSafariViewControllerDelegate?
    
    public func parsePlaylistURL(_ playlistURLString: String) -> URL? {
        
        if (playlistURLString.hasPrefix("spotify:")) {
            // standard format:
            // spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty
            
            if !playlistURLString.contains(":user:") {
                return nil
            } else if !playlistURLString.contains(":playlist:") {
                return nil
            }
            
            if let url = URL(string: playlistURLString) {
                return url
            } else {
                let components = playlistURLString.components(separatedBy: ":")
                let user = components[2]
                let encodedUser = API.URLParameterEncoder.encode(string: user)
                let fixedURLString = playlistURLString.replacingOccurrences(of: ":\(user):", with: ":\(encodedUser):")
                return URL(string: fixedURLString)
            }
        } else if playlistURLString.hasPrefix("http") {
            // standard format:
            // https://open.spotify.com/user/brunolvl/playlist/6sa5ys5q1BTNNdtDO3zxty
            
            if !playlistURLString.contains("spotify.com") {
                return nil
            }
            
            let components = playlistURLString.components(separatedBy: "/")
            
            var user: String?
            var playlistID: String?
            
            for i in 0..<components.count {
                if components[i] == "user" && i < components.count - 1 {
                    user = components[i + 1]
                } else if (components[i] == "playlist" && i < components.count - 1) {
                    let component = components[i + 1]
                    
                    // stripping any URL parameters
                    playlistID = component.components(separatedBy: "?").first!.components(separatedBy: "&").first
                }
            }
            
            if var user = user, let playlistID = playlistID {
                if URL(string: user) == nil {
                    user = API.URLParameterEncoder.encode(string: user)
                }
                
                let spotifyURIString = "spotify:user:\(user):playlist:\(playlistID)"
                return URL(string: spotifyURIString)
            }
        }
        
        return nil
    }
    
    public func startAuthentication(handler: AuthenticationBlock?) {
        
        self.authenticationCallback = handler
        let loginURL = SpotifyAPI.generateAuthenticationURL()
        
        self.safariDelegate = SpotifyServiceSafariViewControllerDelegate()
        self.safariDelegate?.authenticationBlock = handler
        
        if #available(iOS 11, *) {
            let authenticationSession = SFAuthenticationSession(url: loginURL, callbackURLScheme: "jmusic") { url, error in
                self.authenticationSession = nil
                if let url = url {
                    self.finishAuthenticationWithURL(url)
                } else if let error = error as NSError? {
                    if error.domain == SFAuthenticationErrorDomain {
                        handler?(false, nil)
                    } else {
                        handler?(false, error)
                    }
                } else {
                    handler?(false, nil)
                }
            }
            self.authenticationSession = authenticationSession // this is only done because it needs to be retained
            authenticationSession.start()
        } else {
            let authenticationSafariViewController = SFSafariViewController(url: loginURL)
            authenticationSafariViewController.delegate = self.safariDelegate
            UIApplication.shared.keyWindow?.rootViewController?.present(authenticationSafariViewController, animated: true, completion: nil)
        }
    }
    
    func persistAuthentication() {
        SpotifyAPI.credentialsManager?.persist()
    }
    
    func logout() {
        SpotifyAPI.credentialsManager?.clear()
        SpotifyAPI.credentialsManager = nil
    }
    
    func finishAuthenticationWithURL(_ url: URL) {
        
        self.safariDelegate = nil
        UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
        SpotifyAPI.authenticateWith(responseURL: url) { response, error, cache in
            self.authenticationCallback?(error == nil, error)
            self.authenticationCallback = nil
        }
    }
    
    public func userPlaylists(_ callback: UserPlaylistsBlock?) {
        
        SpotifyAPI.userPlaylists { page, error, cache in
            callback?(page, error)
        }
    }
    
    public func tracksFor(playlist: Playlist, callback: PlaylistTracksBlock?) {
        
        SpotifyAPI.tracks(for: playlist) { tracks, error, cache in
            callback?(playlist, tracks, error)
        }
    }
    
    func tracksFor(playlistURL: URL, callback: PlaylistTracksBlock?) {
        
        SpotifyAPI.playlistWith(spotifyURL: playlistURL) { playlist, error, cache in
        
            if let error = error {
                callback?(nil, nil, error)
            } else if let playlist = playlist {
                self.tracksFor(playlist: playlist, callback: callback)
            }
        }
    }
}

// MARK: - Safari View Controller delegate

// Yes this is a class purely for conforming to this protocol, didn't want
// SpotifyService becoming an NSObject just because of this
fileprivate class SpotifyServiceSafariViewControllerDelegate: NSObject, SFSafariViewControllerDelegate {
    
    var authenticationBlock: AuthenticationBlock?
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.authenticationBlock?(false, nil)
    }
}
