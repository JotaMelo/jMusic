//
//  AppleMusicService.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

enum AppleMusicError: Error {
    case denied
    case iCloudMusicLibraryDisabled
    case eligibleForSubscription
    case appleMusicNotSubscribed
    case unknown
}

class TokenManager {
    
    private static let tokenKeychainKey = "tokenKeychainKey"
    private static let tokenExpirationTimestampKeychainKey = "tokenExpirationTimestampKeychainKey"
    static let shared = TokenManager()

    private var _token: String?
    private var expirationDate: Date?
    var token: String? {
        if let token = self._token, let expirationDate = self.expirationDate {
            if Date() > expirationDate {
                return nil
            } else {
                return token
            }
        }
        
        let keychain = KeychainSwift()
        if let token = keychain.get(TokenManager.tokenKeychainKey), let expirationTimestampString = keychain.get(TokenManager.tokenExpirationTimestampKeychainKey), let expirationTimestamp = Double(expirationTimestampString) {
            let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
            if Date() > expirationDate {
                return nil
            }
            
            self._token = token
            self.expirationDate = expirationDate
            return token
        }
        
        return nil
    }
    
    func fetchNewToken(callback: ((String?, Error?) -> Void)?) {
        
        let request = APIRequest(method: .get, path: "generateToken", parameters: nil, urlParameters: nil, cacheOption: .networkOnly) { response, error, cache in
            if let error = error {
                // using a last resort default token if request fails
                self._token = Constants.lastResortAppleMusicToken
                self.expirationDate = Constants.lastResortAppleMusicTokenExpirationDate
                
                if let token = self.token {
                    callback?(token, nil)
                } else {
                    callback?(nil, error)
                }
            } else if let response = response as? [String: Any], let token = response["token"] as? String, let expirationTimestamp = response["expiresAt"] as? Double {
                let keychain = KeychainSwift()
                keychain.set(token, forKey: TokenManager.tokenKeychainKey)
                keychain.set(String(describing: expirationTimestamp), forKey: TokenManager.tokenExpirationTimestampKeychainKey)
                self._token = token
                self.expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                callback?(token, nil)
            }
        }
        request.baseURL = URL(string: "https://backend.server.here")!
        request.suppressErrorAlert = true
        request.makeRequest()
    }
}

extension AppleMusicError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("You denied jMusic access to your Apple Music library. Go to Settings -> Privacy -> Media Library and enabled jMusic so we can continue!", comment: "")
            
        case .iCloudMusicLibraryDisabled:
            return NSLocalizedString("It seems like you don't have iCloud Music Library turned on. jMusic needs it so we can add music to your library. Go to Settings -> Music and switch on iCloud Music Library. Then restart the app and we'll try again.", comment: "")
            
        case .eligibleForSubscription:
            return NSLocalizedString("", comment: "")
            
        case .appleMusicNotSubscribed:
            return NSLocalizedString("You need an Apple Music subscription to use jMusic", comment: "")
            
        case .unknown:
            return NSLocalizedString("An unknown error occured :( Try restarting the app, and check that Apple Music and iCloud Music Library is enabled in Settings -> Music.", comment: "")
        }
    }
}

class AppleMusicService {
    
    fileprivate struct Constants {
        static let storefrontIdentifierUserDefaultsKey = "storefrontIdentifier"
        static let AppleMusicServerBaseURL = URL(string: "https://api.music.apple.com")!
        static let playlistWaitTimeSeconds = 5
        static let searchRequestMaxRetries = 3
        static let totalPasses = 8
        static let storefrontIdentifiers = ["143528": "jo", "143592": "mn", "143491": "il", "143448": "gr", "143595": "pw", "143478": "pl", "143449": "ie", "143581": "td", "143580": "cv", "143583": "fj", "143582": "cg", "143585": "gw", "143584": "gm", "143587": "la", "143586": "kg", "143533": "mu", "143588": "lr", "143509": "ec", "143593": "mz", "143508": "do", "143515": "mo", "143532": "ml", "143545": "dm", "143544": "ky", "143547": "ms", "143469": "ru", "143541": "bb", "143540": "ag", "143543": "vg", "143542": "bm", "143501": "co", "143463": "hk", "143503": "br", "143461": "nz", "143466": "kr", "143504": "gt", "143464": "sg", "143465": "cn", "143453": "pt", "143603": "tj", "143568": "az", "143451": "lu", "143462": "jp", "143450": "it", "143468": "mx", "143496": "sk", "143460": "au", "143518": "ee", "143456": "se", "143534": "ne", "143535": "sn", "143536": "tn", "143502": "ve", "143530": "mk", "143455": "ca", "143514": "uy", "143549": "lc", "143505": "ar", "143454": "es", "143538": "ai", "143539": "bs", "143548": "kn", "143479": "sa", "143571": "ye", "143572": "tz", "143573": "gh", "143507": "pe", "143576": "bj", "143577": "bt", "143578": "bf", "143579": "kh", "143473": "my", "143472": "za", "143475": "th", "143474": "ph", "143477": "pk", "143476": "id", "143467": "in", "143589": "mw", "143506": "sv", "143488": "mv", "143558": "is", "143520": "lt", "143494": "hr", "143597": "pg", "143445": "at", "143470": "tw", "143444": "gb", "143489": "cz", "143446": "be", "143447": "fi", "143527": "ci", "143526": "bg", "143442": "fr", "143443": "de", "143480": "tr", "143481": "ae", "143529": "ke", "143483": "cl", "143484": "np", "143485": "pa", "143486": "lk", "143487": "ro", "143519": "lv", "143482": "hu", "143566": "uz", "143565": "by", "143564": "ao", "143563": "dz", "143562": "om", "143561": "ng", "143560": "bn", "143523": "md", "143522": "li", "143575": "al", "143531": "mg", "143521": "mt", "143497": "lb", "143471": "vn", "143495": "cr", "143591": "fm", "143493": "kw", "143492": "ua", "143594": "na", "143490": "bd", "143546": "gd", "143598": "st", "143599": "sc", "143524": "am", "143499": "si", "143441": "us", "143602": "sz", "143452": "nl", "143600": "sl", "143601": "sb", "143457": "no", "143525": "bw", "143604": "tm", "143605": "zw", "143537": "ug", "143459": "ch", "143458": "dk", "143590": "mr", "143556": "bo", "143557": "cy", "143554": "sr", "143555": "bz", "143552": "tc", "143553": "gy", "143550": "vc", "143551": "tt", "143512": "ni", "143513": "py", "143510": "hn", "143511": "jm", "143516": "eg", "143517": "kz", "143498": "qa", "143559": "bh"]
    }
    
    private var playlistCache: [String: MPMediaPlaylist] = [:]
    
    private var searches: [AppleMusicSearch] = []
    private var storefrontIdentifier: String?
    private var totalRetries = 0
    
    var regionIdentifier: String {
        return self.storefrontIdentifier ?? ""
    }
    
    var service = Service.appleMusic
    
    init() {
//        self.loadStorefrontIdentifier(callback: nil)
    }
    
    private func loadStorefrontIdentifier(callback: ((String?, Error?) -> Void)?) {
        
        if Helper.testMode {
            self.storefrontIdentifier = "143441"
            callback?("143441", nil)
            return
        }
        
        SKCloudServiceController().requestStorefrontIdentifier { storefrontIdentifier, error in

            if error == nil {
                self.storefrontIdentifier = storefrontIdentifier?.components(separatedBy: "-").first
                Helper.set(self.storefrontIdentifier, forKey: Constants.storefrontIdentifierUserDefaultsKey)
            }
            
            callback?(self.storefrontIdentifier, error)
        }
    }
    
    private func requestCapabilitiesWith(handler: ErrorBlock?)  {
        
        SKCloudServiceController().requestCapabilities(completionHandler: { capabilities, error in
            guard error == nil else {
                handler?(error)
                return
            }
            
            if capabilities.contains(.addToCloudMusicLibrary) {
                if self.storefrontIdentifier == nil {
                    self.loadStorefrontIdentifier(callback: { _, _ in
                        handler?(nil)
                    })
                } else {
                    handler?(nil)
                }
            } else if capabilities.contains(.musicCatalogPlayback) {
                handler?(AppleMusicError.iCloudMusicLibraryDisabled)
            } else if capabilities.contains(.musicCatalogSubscriptionEligible) {
                handler?(AppleMusicError.eligibleForSubscription)
            } else {
                handler?(AppleMusicError.appleMusicNotSubscribed)
            }
        })
    }
    
    private func playlistWith(uuid: UUID, creationMetadata: MPMediaPlaylistCreationMetadata, callback: @escaping (MPMediaPlaylist?, Error?) -> Void) {
        
        MPMediaLibrary.default().getPlaylist(with: uuid, creationMetadata: creationMetadata) { [unowned self] libraryPlaylist, error in
            if error == nil {
                self.playlistCache[uuid.uuidString] = libraryPlaylist
                callback(libraryPlaylist, error)
            } else {
                callback(nil, error)
            }
        }
    }
    
    private func searchFor(track: Track, callback: TrackSearchBlock?, pass: Int = 0) {
        
        guard
            let storefrontIdentifier = self.storefrontIdentifier,
            let cleanStorefront = storefrontIdentifier.components(separatedBy: ",").first,
            let countryCode = Constants.storefrontIdentifiers[cleanStorefront]
        else {
            self.loadStorefrontIdentifier { storeFrontIdentifier, error in
                if error == nil {
                    self.searchFor(track: track, callback: callback, pass: pass)
                } else {
                    callback?(nil, [], ImportError.storefrontFailed)
                }
            }
            return
        }
        
        guard let token = TokenManager.shared.token else {
            TokenManager.shared.fetchNewToken { _, error in
                if error == nil {
                    self.searchFor(track: track, callback: callback, pass: pass)
                } else {
                    callback?(nil, [], ImportError.token)
                }
            }
            return
        }
        
        if pass > Constants.totalPasses {
            callback?(nil, self.searches, nil)
            self.searches = []
            self.totalRetries = 0
            return
        }
        
        let baseURL = Constants.AppleMusicServerBaseURL
        let query = self.queryFor(track: track, pass: pass)
        if query == "" {
            self.searchFor(track: track, callback: callback, pass: pass + 1)
            return
        }
        
        if self.searches.last?.query == query {
            if pass < Constants.totalPasses {
                self.searchFor(track: track, callback: callback, pass: pass + 1)
            } else {
                callback?(nil, self.searches, nil)
            }
            
            return
        }
        
        let search = AppleMusicSearch(query: query, date: Date(), results: [])
        let parameters = ["term": query, "types": "songs", "limit": "25"]
        
        NSLog("Search parameters: %@", parameters)
        
        let request = APIRequest(method: .get, path: "v1/catalog/\(countryCode)/search", parameters: nil, urlParameters: parameters, cacheOption: .networkOnly) { response, error, cache in
            if let error = error {
                self.handleRequestError(error: error, callback: callback, track: track, pass: pass)
            } else if let response = response {
                self.searches.append(search)
                self.handleRequestSuccess(response: response, callback: callback, track: track, pass: pass)
            }
        }
        request.extraHeaders = ["Authorization": "Bearer \(token)"]
        request.suppressErrorAlert = true
        request.baseURL = baseURL
        request.makeRequest()
    }
    
    private func handleRequestSuccess(response: Any, callback: TrackSearchBlock?, track: Track, pass: Int) {
        
        guard let response = response as? [String: Any], let results = response[keyPath: "results.songs.data"] as? [[String: Any]] else {
            self.searchFor(track: track, callback: callback, pass: pass + 1)
            return
        }
        
        let searchResults = results.flatMap { item -> SearchResult? in
            if let attributes = item["attributes"] as? [String: Any], attributes["playParams"] == nil {
                return nil
            }
            
            return AppleMusicSearchResult(dictionary: item)
        }
        
        self.searches[self.searches.count - 1].results.append(contentsOf: searchResults)
        
        let filteredResults = self.filterResults(searchResults, forTrack: track)
        if filteredResults.count == 0 && pass < Constants.totalPasses {
            self.searchFor(track: track, callback: callback, pass: pass + 1)
        } else {
            let bestMatch = self.bestMatchFor(track: track, in: filteredResults, fallback: pass < 4)
            
            callback?(bestMatch, self.searches, nil)
            self.searches = []
            self.totalRetries = 0
        }
    }
    
    private func handleRequestError(error: API.RequestError, callback: TrackSearchBlock?, track: Track, pass: Int) {
        
        if self.totalRetries < Constants.searchRequestMaxRetries {
            self.totalRetries += 1
            
            NSLog("Waiting to make next request")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.searchFor(track: track, callback: callback, pass: pass)
            })
        } else {
            self.totalRetries = 0
            callback?(nil, self.searches, error)
        }
    }
}

// MARK: - Helpers

fileprivate extension AppleMusicService {
    
    func bestMatchFor(track: Track, in results: [SearchResult], fallback: Bool, forceStreamable: Bool = true) -> SearchResult? {
        
        var bestMatch: SearchResult?
        
        var cleanTrackName = self.cleanUpQuery(track.name, pass: 0).lowercased().components(separatedBy: "-").first!.trimmingCharacters(in: CharacterSet.whitespaces)
        cleanTrackName = JMUnidecode.unidecode(cleanTrackName)
        
        for result in results {
            let durationDifference = max(result.duration, track.duration) - min(result.duration, track.duration)
            let trackName = JMUnidecode.unidecode(result.trackName).lowercased()
            
            let durationTest = durationDifference <= 5
            let nameTest = trackName.hasPrefix(cleanTrackName)
            let streamableTest = forceStreamable ? result.isStreamable : true
            if durationTest && nameTest && streamableTest {
                bestMatch = result
                break
            }
        }
        
        if bestMatch == nil && forceStreamable {
            return self.bestMatchFor(track: track, in: results, fallback: fallback, forceStreamable: false)
        }
        
        if bestMatch == nil && fallback {
            bestMatch = results.first
        }
        
        return bestMatch
    }
    
    func queryFor(track: Track, pass: Int) -> String {
        
        var searchQuery: String = ""
        let cleanTrackName = self.cleanUpQuery(track.name, pass: pass)
        let cleanAlbumName = self.cleanUpQuery(track.album, pass: pass)
        
        // on pass 3 search lowercased
        // on pass 4 search for artist name + album name
        // on pass 5 search for song name + album name
        // on pass 6 search only for the artist name
        // on pass 7 search only for the album name
        // on pass 8 search only for the song name
        if pass < 4 {
            searchQuery = "\(cleanTrackName) \(track.artist)"
            
            if pass == 3 {
                searchQuery = searchQuery.lowercased()
            }
        } else if pass == 4 {
            searchQuery = "\(track.artist) \(cleanAlbumName)"
        } else if pass == 5 {
            searchQuery = "\(cleanTrackName) \(cleanAlbumName)"
        } else if pass == 6 {
            searchQuery = track.artist
        } else if pass == 7 {
            searchQuery = track.album
        } else if pass == 8 {
            searchQuery = cleanTrackName
        }
        
        return searchQuery.replacingOccurrences(of: ",", with: "")
    }
    
    func filterResults(_ results: [SearchResult], forTrack track: Track) -> [SearchResult] {
        
        return results.filter { result -> Bool in
            let resultArtistName = self.cleanupArtistName(result.artist)
            let trackArtistName = self.cleanupArtistName(track.artist)
            
            // VERY specific case. On itunes: TR/ST, on Spotify: Trust. Fine.
            if resultArtistName == "trst" && trackArtistName == "trust" {
                return true
            }
            
            // Another specific case. Kakkmaddafakka apparently changed their name to KMF on Spotify
            let kakkmaddafakkaAlbums = ["hest", "six months is a long time", "kmf", "down to earth"]
            if resultArtistName == "kakkmaddafakka" && trackArtistName == "kmf" && kakkmaddafakkaAlbums.contains(track.album.lowercased()) {
                return true
            }
            
            let test1 = resultArtistName.contains(trackArtistName)
            let test2 = trackArtistName.contains(resultArtistName)
            
            return test1 || test2
        }
    }
    
    func cleanUpQuery(_ query: String, pass: Int) -> String {
        // At the first pass just remove the matches containing ignored terms
        // At the second pass also replace matches of relevant terms with the term
        // At the third pass, delete all the matches
        //
        // Matches are strings between parentesis/after dash
        
        let query = query as NSString
        var pass = pass
        
        if pass > 2 {
            pass = 2
        }
        
        let mutableQuery = query.mutableCopy() as! NSMutableString
        
        let relevantTerms = ["(mix ", " mix)", " mix ", "mix ", " mix", "(remix ", " remix)", " remix ", "remix ", " remix"]
        let ignoredTerms = ["original", "single", "album", "feat.", "ft.", "bonus", "spotify"]
        
        var regex = try! NSRegularExpression(pattern: "\\(.+?\\)", options: .caseInsensitive)
        var matches = regex.matches(in: query as String, options: [], range: NSMakeRange(0, query.length))
        
        regex = try! NSRegularExpression(pattern: " - .+", options: .caseInsensitive)
        matches.append(contentsOf: regex.matches(in: query as String, options: [], range: NSMakeRange(0, query.length)))
        
        var totalDeletedCharacters = 0
        for textCheckingResult in matches {
            let text = query.substring(with: textCheckingResult.range).lowercased()
            
            if pass == 2 {
                if textCheckingResult.range.location >= totalDeletedCharacters {
                    let range = NSMakeRange(textCheckingResult.range.location - totalDeletedCharacters, textCheckingResult.range.length)
                    
                    if range.location != NSNotFound && range.location + range.length <= mutableQuery.length {
                        mutableQuery.deleteCharacters(in: range)
                        
                        totalDeletedCharacters += range.length
                    }
                }
            } else {
                var hasIgnoredTerm = false
                for ignoredTerm in ignoredTerms {
                    if text.contains(ignoredTerm) && textCheckingResult.range.location >= totalDeletedCharacters && totalDeletedCharacters <= textCheckingResult.range.location {
                        let range = NSMakeRange(textCheckingResult.range.location - totalDeletedCharacters, textCheckingResult.range.length)
                        
                        if range.location != NSNotFound && range.location + range.length <= mutableQuery.length {
                            mutableQuery.deleteCharacters(in: range)
                            
                            totalDeletedCharacters += range.length
                            hasIgnoredTerm = true
                            break
                        }
                    }
                }
                
                if pass == 1 && !hasIgnoredTerm {
                    for relevantTerm in relevantTerms {
                        if text.contains(relevantTerm) && textCheckingResult.range.location >= totalDeletedCharacters {
                            let cleanTerm = relevantTerm.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "")
                            
                            let range = NSMakeRange(textCheckingResult.range.location - totalDeletedCharacters, textCheckingResult.range.length)
                            
                            if range.location != NSNotFound && range.location + range.length <= mutableQuery.length {
                                mutableQuery.replaceCharacters(in: range, with: cleanTerm)
                                
                                totalDeletedCharacters += (range.length - cleanTerm.utf16.count)
                            }
                            
                            break
                        }
                    }
                }
            }
        }
        
        // MusicKit API gets mad about commas, interprets as a separator for parameters
        return mutableQuery.replacingOccurrences(of: ",", with: "")
    }
    
    func cleanupArtistName(_ artist: String) -> String {
        
        var artist = artist.replacingOccurrences(of: "&", with: "and")
        
        let charactersToRemove = CharacterSet.alphanumerics.inverted
        artist = artist.components(separatedBy: charactersToRemove).joined(separator: "")
        
        return JMUnidecode.unidecode(artist).lowercased()
    }
}

// MARK: - Destination Service Providing

extension AppleMusicService: DestinationServiceProviding {
    
    func startAuthenticationWith(handler: ErrorBlock?) {
        
        if Helper.testMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                handler?(nil)
            })
            return
        }
        
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            if authorizationStatus == .authorized {
                self.requestCapabilitiesWith(handler: handler)
            } else {
                handler?(AppleMusicError.denied)
            }
        }
    }
    
    func createPlaylist(name: String, callback: PlaylistReturnBlock?) {
        
        let playlistUUID = UUID()
        let playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: name)
        playlistCreationMetadata.authorDisplayName = " "
        
        if Helper.testMode {
            let playlist = AppleMusicPlaylist(id: playlistUUID.uuidString, name: name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                callback?(playlist, nil)
            })
            return
        }
        
        self.playlistWith(uuid: playlistUUID, creationMetadata: playlistCreationMetadata) { (libraryPlaylist, error) in
            
            if let libraryPlaylist = libraryPlaylist {
                let playlist = AppleMusicPlaylist(id: playlistUUID.uuidString, name: libraryPlaylist.name!)
                callback?(playlist, nil)
            } else if let error = error {
                callback?(nil, error)
            }
        }
    }
    
    func retrieve(playlist: Playlist, callback: PlaylistReturnBlock?) {
        
        guard let playlistUUID = UUID(uuidString: playlist.id) else { return }
        let playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: playlist.name)
        playlistCreationMetadata.authorDisplayName = " "
        
        self.playlistWith(uuid: playlistUUID, creationMetadata: playlistCreationMetadata) { (libraryPlaylist, error) in
            if libraryPlaylist != nil {
                callback?(playlist, nil)
            } else if error != nil {
                callback?(nil, error)
            }
        }
    }
    
    func find(track: Track, callback: TrackSearchBlock?) {
        self.searchFor(track: track, callback: callback)
    }
    
    func addTrack(fromSearchResult searchResult: SearchResult, toPlaylist playlist: Playlist, callback: ErrorBlock?) {
        if Helper.testMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                callback?(nil)
            })
        } else {
            self.addTrack(withID: searchResult.trackID, toPlaylist: playlist, callback: callback)
        }
    }
    
    func addTrack(withID trackID: String, toPlaylist playlist: Playlist, callback: ErrorBlock?) {
        
        if let libraryPlaylist = self.playlistCache[playlist.id] {
            DispatchQueue.global(qos: .userInitiated).async {
                libraryPlaylist.addItem(withProductID: trackID, completionHandler: callback)
            }
        } else {
            let playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: playlist.name)
            playlistCreationMetadata.authorDisplayName = " " // users don't want "jMusic" on their playlists
            
            self.playlistWith(uuid: UUID(uuidString: playlist.id)!, creationMetadata: playlistCreationMetadata, callback: { (libraryPlaylist, error) in
                if let error = error {
                    callback?(error)
                } else {
                    self.addTrack(withID: trackID, toPlaylist: playlist, callback: callback)
                }
            })
        }
    }
}
