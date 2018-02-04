//
//  SpotifyAPI.swift
//  jMusic
//
//  Created by Jota Melo on 02/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

class SpotifyAPI: APIRequest {
    
    struct Constants {
        static let clientID = ""
        static let clientSecret = ""
        static let redirectURI = "jMusic://"
    }
    
    class CredentialsManager: Mappable {
        private static let credentialsKeychainKey = "spotifyCredentialsKeychainKey"
        
        var userID: String?
        var userName: String?
        
        var accesstoken: String
        var tokenType: String
        var scope: String
        var expiryDate: Date
        var refreshToken: String
        
        private var originalDictionary: [String: Any]
        
        static func loadPersisted() -> CredentialsManager? {
            let keychain = KeychainSwift()
            if let jsonData = keychain.getData(self.credentialsKeychainKey), let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []), let dictionary = jsonObject as? [String: Any] {
                return CredentialsManager(dictionary: dictionary)
            }
            
            return nil
        }
            
        required init(mapper: Mapper) {
            
            self.accesstoken = mapper.keyPath("access_token")
            self.tokenType = mapper.keyPath("token_type")
            self.scope = mapper.keyPath("scope")
            
            if let expiresIn: Int = mapper.keyPath("expires_in") {
                self.expiryDate = Date(timeIntervalSinceNow: TimeInterval(expiresIn))
            } else {
                self.expiryDate = mapper.keyPath("expires_at")
            }
            
            self.refreshToken = mapper.keyPath("refresh_token")
            self.userID = mapper.keyPath("userID")
            self.userName = mapper.keyPath("userName")
            
            self.originalDictionary = mapper.dictionary
        }
        
        func persist() {
            
            var dictionary = self.originalDictionary
            if let userID = self.userID {
                dictionary["userID"] = userID
            }
            
            if let userName = self.userName {
                dictionary["userName"] = userName
            }
            
            dictionary.removeValue(forKey: "expires_in")
            dictionary["expires_at"] = self.expiryDate.timeIntervalSince1970
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: []) {
                let keychain = KeychainSwift()
                keychain.set(jsonData, forKey: CredentialsManager.credentialsKeychainKey)
            }
        }
        
        func clear() {
            let keychain = KeychainSwift()
            keychain.delete(CredentialsManager.credentialsKeychainKey)
        }
    }
    
    static var credentialsManager = CredentialsManager.loadPersisted()
    
    override var extraHeaders: [String: String]? {
        didSet {
            guard let credentialsManager = SpotifyAPI.credentialsManager else { return }
            
            let headerValue = "Bearer \(credentialsManager.accesstoken)"
            if extraHeaders != nil {
                super.extraHeaders?["Authorization"] = headerValue
            } else {
                super.extraHeaders = ["Authorization": headerValue]
            }
        }
    }
    
    override func makeRequest() {
        
        guard let credentialsManager = SpotifyAPI.credentialsManager, Date() > credentialsManager.expiryDate else {
            super.makeRequest()
            return
        }
        
        SpotifyAPI.refreshAccessToken { response, error, cache in
            if let response = response {
                super.extraHeaders?["Authorization"] = "Bearer \(response)"
                super.makeRequest()
            } else {
                self.completionBlock?(response, error, cache)
            }
        }
    }
}

extension SpotifyAPI {
    
    static func generateAuthenticationURL() -> URL {
        
        let parameters = ["client_id": Constants.clientID, "response_type": "code", "scope": "user-read-private playlist-read-private playlist-read-collaborative", "redirect_uri": Constants.redirectURI, "state": UUID().uuidString]
        let encodedParameters = API.URLParameterEncoder.encode(parameters: parameters)
        
        return URL(string: "https://accounts.spotify.com/authorize?\(encodedParameters)")!
    }
    
    @discardableResult
    static func authenticateWith(responseURL: URL, callback: ResponseBlock<String>?) -> SpotifyAPI? {
        
        SpotifyAPI.credentialsManager = nil
        
        guard let decodedURLParameters = API.URLParameterEncoder.decode(queryString: responseURL.absoluteString),
            let code = decodedURLParameters["code"] else { return nil }
        
        let request = SpotifyAPI(method: .post, path: "api/token", parameters: ["grant_type": "authorization_code", "code": code, "redirect_uri": Constants.redirectURI, "client_id": Constants.clientID, "client_secret": Constants.clientSecret], urlParameters: nil, cacheOption: .networkOnly) { (response, error, cache) in
            
            if let error = error {
                callback?(nil, error, false)
            } else if let authenticationResponse = response as? [String: Any] {
                self.credentialsManager = CredentialsManager(dictionary: authenticationResponse)
                
                SpotifyAPI(method: .get, path: "me", parameters: nil, urlParameters: nil, cacheOption: .networkOnly, completion: { response, error, cache in
                    if let error = error {
                        callback?(nil, error, false)
                    } else if let response = response as? [String: Any]  {
                        self.credentialsManager?.userID = response["id"] as? String
                        self.credentialsManager?.userName = response["display_name"] as? String
                        callback?(self.credentialsManager?.accesstoken, nil, false)
                    }
                }).makeRequest()
            }
        }
        request.parameterEncoder = API.URLParameterEncoder.self
        request.baseURL = URL(string: "https://accounts.spotify.com")!
        request.makeRequest()
        
        return request
    }
    
    @discardableResult
    static func refreshAccessToken(callback: ResponseBlock<String>?) -> SpotifyAPI? {
        guard let credentialsManager = SpotifyAPI.credentialsManager else { return nil }
        SpotifyAPI.credentialsManager = nil
        
        let authorization = "\(Constants.clientID):\(Constants.clientSecret)".data(using: .utf8)!.base64EncodedString()
        let request = SpotifyAPI(method: .post, path: "api/token", parameters: ["grant_type": "refresh_token", "refresh_token": credentialsManager.refreshToken], urlParameters: nil, cacheOption: .networkOnly) { response, error, cache in
            if let error = error {
                callback?(nil, error, false)
            } else if var response = response as? [String: Any] {
                if response["refresh_token"] == nil {
                    response["refresh_token"] = credentialsManager.refreshToken
                }
                
                if let userID = credentialsManager.userID {
                    response["userID"] = userID
                }
                
                if let userName = credentialsManager.userName {
                    response["userName"] = userName
                }
                
                SpotifyAPI.credentialsManager = CredentialsManager(dictionary: response)
                SpotifyAPI.credentialsManager?.persist()
                callback?(SpotifyAPI.credentialsManager?.accesstoken, nil, cache)
            }
        }
        request.parameterEncoder = API.URLParameterEncoder.self
        request.extraHeaders = ["Authorization": "Basic \(authorization)"]
        request.baseURL = URL(string: "https://accounts.spotify.com")!
        request.makeRequest()
        return request
    }
    
    @discardableResult
    static func userPlaylists(callback: (APIRequest.ResponseBlock<PlaylistPaging>?), offset: Int, limit: Int) -> SpotifyAPI? {
        
        guard let userID = self.credentialsManager?.userID else { return nil }
        let request = SpotifyAPI(method: .get, path: "users/\(userID)/playlists", parameters: nil, urlParameters: ["offset": offset, "limit": limit], cacheOption: .networkOnly) { response, error, cache in
            
            if let error = error {
                callback?(nil, error, false)
            } else if let response = response as? [String: Any] {
                let playlistPage = SpotifyPlaylistPage(dictionary: response)
                callback?(playlistPage, nil, false)
            }
        }
        request.makeRequest()
        
        return request
    }
    
    @discardableResult
    static func userPlaylists(callback: APIRequest.ResponseBlock<PlaylistPaging>?) -> SpotifyAPI? {
        return self.userPlaylists(callback: callback, offset: 0, limit: 50)
    }
    
    @discardableResult
    static func playlistWith(spotifyURL: URL, callback: APIRequest.ResponseBlock<SpotifyPlaylist>?) -> SpotifyAPI {
        
        // consider playlistURL spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty
        let components = spotifyURL.absoluteString.components(separatedBy: ":")
        let playlistID = components[4]
        let userID: String
        if URL(string: components[2]) == nil {
            userID = API.URLParameterEncoder.encode(string: components[2])
        } else {
            userID = components[2]
        }
        
        let request = SpotifyAPI(method: .get, path: "users/\(userID)/playlists/\(playlistID)", parameters: nil, urlParameters: nil, cacheOption: .networkOnly) { (response, error, cache) in
            
            if let error = error {
                callback?(nil, error, false)
            } else if let response = response as? [String: Any] {
                let playlist = SpotifyPlaylist(dictionary: response)
                callback?(playlist, nil, false)
            }
        }
        request.makeRequest()
        
        return request
    }
    
    @discardableResult
    static func tracks(for playlist: Playlist, callback: APIRequest.ResponseBlock<[SpotifyTrack]>?) -> SpotifyAPI? {
        
        guard var userID = playlist.userID else { return nil }
        if URL(string: userID) == nil {
            userID = API.URLParameterEncoder.encode(string: userID)
        }
        
        let path = "users/\(userID)/playlists/\(playlist.id)/tracks"
        var tracks: [SpotifyTrack] = []
        
        var pagingBlock: APIRequest.ResponseBlock<Any>?
        pagingBlock = { response, error, cache in
            if let error = error {
                callback?(nil, error, false)
            } else if let response = response as? [String: Any],
                let items = response["items"] as? [[String: Any]],
                let offset = response["offset"] as? Int,
                let limit = response["limit"] as? Int {
                
                let pageTracks = items.flatMap { item -> SpotifyTrack? in
                    if item["track"] != nil && item["track"]! is NSNull {
                        return nil
                    }
                    
                    return SpotifyTrack(dictionary: item)
                }
                tracks.append(contentsOf: pageTracks)
                
                if response["next"] is String {
                    let request = SpotifyAPI(method: .get, path: path, parameters: nil, urlParameters: ["offset": offset + limit, "limit": limit], cacheOption: .networkOnly, completion: pagingBlock)
                    request.makeRequest()
                } else {
                    callback?(tracks, nil, false)
                }
            }
        }
        
        let request = SpotifyAPI(method: .get, path: path, parameters: nil, urlParameters: ["offset": 0, "limit": 100], cacheOption: .networkOnly, completion: pagingBlock)
        request.makeRequest()
        
        return request
    }
}
