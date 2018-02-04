//
//  Import.swift
//  jMusic
//
//  Created by Jota Melo on 09/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation
import RealmSwift

class RealmPlaylist: Object, Playlist {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var userID: String?
    @objc dynamic var enumType: Int = 0
    @objc dynamic var enumService: String = ""
    
    var tracks: [Track]?
    
    var type: PlaylistType {
        return PlaylistType(rawValue: self.enumType)!
    }
    
    var service: Service {
        return Service(rawValue: self.enumService)!
    }
    
    convenience init(_ playlist: Playlist) {
        self.init()
        
        self.uuid = UUID().uuidString
        self.id = playlist.id
        self.name = playlist.name
        self.userID = playlist.userID
        self.enumType = playlist.type.rawValue
        self.enumService = playlist.service.rawValue
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["tracks"]
    }
}

class RealmTrack: Object, Track {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var album: String = ""
    @objc dynamic var albumCoverURLString: String? = nil
    @objc dynamic var duration: TimeInterval = 0 // in seconds
    @objc dynamic var errorDescription: String?
    @objc private dynamic var enumStatus: Int = TrackStatus.unprocessed.rawValue
    @objc private dynamic var enumService: String = Service.unspecified.rawValue
    
    @objc dynamic var realmMatchedResult: RealmSearchResult? = nil
    private let realmSearches = List<RealmSearch>()
    
    // protocol conformance
    var albumCoverURL: URL? {
        if let albumCoverURLString = self.albumCoverURLString {
            return URL(string: albumCoverURLString)
        }
        
        return nil
    }
    
    var status: TrackStatus {
        get {
            return TrackStatus(rawValue: self.enumStatus)!
        }
        
        set(value) {
            self.enumStatus = value.rawValue
        }
    }
    
    var service: Service {
        get {
            return Service(rawValue: self.enumService)!
        }
        
        set(value) {
            self.enumService = value.rawValue
        }
    }
    
    var searches: [Search] {
        return Array(self.realmSearches)
    }
    
    var matchedResult: SearchResult? {
        get {
            return self.realmMatchedResult
        }
        
        set(value) {
            if let value = value {
                self.realmMatchedResult = RealmSearchResult(value)
                return
            }
            
            self.realmMatchedResult = nil
        }
    }
    
    var error: Error?
    
    convenience init(_ track: Track) {
        self.init()
        
        self.uuid = UUID().uuidString
        self.id = track.id
        self.name = track.name
        self.artist = track.artist
        self.album = track.album
        self.albumCoverURLString = track.albumCoverURL?.absoluteString
        self.duration = track.duration
        self.enumStatus = track.status.rawValue
        self.enumService = track.service.rawValue
        
        if let matchedResult = track.matchedResult {
            self.realmMatchedResult = RealmSearchResult(matchedResult)
        }
        
        track.searches.forEach { search in
            let realmSearch = RealmSearch(search)
            self.realmSearches.append(realmSearch)
        }
    }
    
    func add(_ searches: [Search]) {
        searches.forEach { (search) in
            let realmSearch = RealmSearch(search)
            self.realmSearches.append(realmSearch)
        }
    }
    
    func removeAllSearches() {
        self.realmSearches.removeAll()
    }
    
    override static func ignoredProperties() -> [String] {
        return ["albumCoverURL", "status", "source", "searches", "matchedResult"]
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

class RealmSearch: Object, Search {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var query: String = ""
    @objc dynamic var date: Date = Date()
    let realmResults = List<RealmSearchResult>()
    
    var results: [SearchResult] {
        return Array(self.realmResults)
    }
    
    convenience init(_ search: Search) {
        self.init()
        
        self.uuid = UUID().uuidString
        self.query = search.query
        self.date = search.date
        search.results.forEach { result in
            let realmResult = RealmSearchResult(result)
            self.realmResults.append(realmResult)
        }
    }
    
    override static func ignoredProperties() -> [String] {
        return ["results"]
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

class RealmSearchResult: Object, SearchResult {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var trackID: String = ""
    @objc dynamic var trackName: String = ""
    @objc dynamic var artist: String = ""
    @objc dynamic var album: String = ""
    @objc dynamic var albumCoverURLString: String?
    @objc dynamic var duration: TimeInterval = 0
    @objc dynamic var isStreamable: Bool = false
    @objc dynamic var enumService: String = ""
    
    var albumCoverURL: URL? {
        if let albumCoverURLString = self.albumCoverURLString {
            return URL(string: albumCoverURLString)
        }
        
        return nil
    }
    
    var service: Service {
        return Service(rawValue: self.enumService)!
    }
    
    convenience init(_ result: SearchResult) {
        self.init()
        
        self.uuid = UUID().uuidString
        self.trackID = result.trackID
        self.trackName = result.trackName
        self.artist = result.artist
        self.album = result.album
        self.albumCoverURLString = result.albumCoverURL?.absoluteString
        self.duration = result.duration
        self.isStreamable = result.isStreamable
        self.enumService = result.service.rawValue
    }
    
    override static func ignoredProperties() -> [String] {
        return ["albumCoverURL"]
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

class Import: Object {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var sourcePlaylist: RealmPlaylist!
    @objc dynamic var destinationPlaylist: RealmPlaylist?
    @objc dynamic var date = Date()
    let tracks = List<RealmTrack>()
    
    static func persistImport(withSelection selection: PlaylistSelection) -> Import? {
        guard let realm = try? Realm() else { return nil }
        
        let playlistImport = Import()
        playlistImport.uuid = UUID().uuidString
        playlistImport.sourcePlaylist = RealmPlaylist(selection.playlist)
        playlistImport.date = Date()
        
        selection.tracks.forEach { track in
            let realmTrack = RealmTrack(track)
            playlistImport.tracks.append(realmTrack)
        }
        
        do {
            try realm.write {
                realm.add(playlistImport)
            }
        } catch {
            return nil
        }
        
        return playlistImport
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}

// bad name but renaming models apparently is not a thing in Realm
// (the ideal would be to match the "Info" classes on ImportManager:
// PlaylistImport and Import, the latter being the collection of PlaylistImports)
class ImportCollection: Object {
    
    @objc dynamic var uuid: String = ""
    @objc dynamic var date = Date()
    let imports = List<Import>()
    
    static func persistImportCollection(withImports imports: [Import]) -> ImportCollection? {
        guard let realm = try? Realm() else { return nil }
        
        let importCollection = ImportCollection()
        importCollection.uuid = UUID().uuidString
        importCollection.date = Date()
        
        imports.forEach {
            importCollection.imports.append($0)
        }
        
        do {
            try realm.write {
                realm.add(importCollection)
            }
        } catch {
            return nil
        }
        
        return importCollection
    }
    
    override static func primaryKey() -> String {
        return "uuid"
    }
}
