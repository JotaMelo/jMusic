//
//  ImportManager.swift
//  jMusic
//
//  Created by Jota Melo on 31/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation
import RealmSwift
import MediaPlayer
import CloudKit

typealias TrackImportProgressHandler = (Track?, Bool, Error?) -> Void
typealias PlaylistImportProgressHandler = (Playlist?, Bool) -> Void

class PlaylistImportInfo {
    
    fileprivate(set) var playlist: Playlist
    fileprivate(set) var tracks: [RealmTrack]
    
    fileprivate(set) var totalProcessed: Int = 0
    fileprivate(set) var numberOfInterruptions: Int = 0
    
    fileprivate(set) var startTime: Date?
    fileprivate(set) var endTime: Date?
    
    private var ignoreImportedTracks: Bool
    private var persistedImportID: String
    fileprivate(set) var destinationPlaylist: Playlist? {
        didSet {
            guard let destinationPlaylist = self.destinationPlaylist else { return }
            guard let persistedImport = self.persistedImport else { return }
            try? persistedImport.realm?.write {
                persistedImport.destinationPlaylist = RealmPlaylist(destinationPlaylist)
            }
        }
    }
    
    private var persistedImport: Import? {
        guard let realm = try? Realm() else { return nil }
        return realm.object(ofType: Import.self, forPrimaryKey: self.persistedImportID)
    }
    
    var unsuccessfulTracks: [RealmTrack] {
        return self.tracks.filter { $0.status != .found }
    }
    
    var isFinished: Bool {
        return self.tracks.count == self.totalProcessed
    }
    
    init(persistedImport: Import, ignoreImportedTracks: Bool) {
        
        // when on Playlist Refresher mode we only want to show
        // the newly imported tracks on the import screen
        if ignoreImportedTracks {
            self.tracks = Array(persistedImport.tracks.filter { $0.status != .found })
        } else {
            self.tracks = Array(persistedImport.tracks)
        }
        
        self.ignoreImportedTracks = ignoreImportedTracks
        self.playlist = persistedImport.sourcePlaylist
        self.destinationPlaylist = persistedImport.destinationPlaylist
        self.totalProcessed = (self.tracks.filter { $0.status != TrackStatus.unprocessed }).count
        self.persistedImportID = persistedImport.uuid
    }
    
    func updateTracks() {
        guard let persistedImport = self.persistedImport else { return }
        
        if self.ignoreImportedTracks {
            var lookupDict: [String: String] = [:]
            self.tracks.forEach { lookupDict[$0.uuid] = $0.uuid }
            
            self.tracks = persistedImport.tracks.filter { lookupDict[$0.uuid] != nil }
        } else {
            self.tracks = Array(persistedImport.tracks)
        }
    }
}

class ImportInfo {
    
    private(set) var currentImport: PlaylistImportInfo
    private(set) var totalProcessed: Int
    private(set) var imports: [PlaylistImportInfo]
    
    var isFinished: Bool {
        return self.totalProcessed >= self.imports.count
    }
    
    init(imports: [PlaylistImportInfo]) {
        
        self.imports = imports
        
        var counter = 0
        for i in imports {
            if i.totalProcessed == i.tracks.count {
                counter += 1
            }
        }
        
        self.totalProcessed = counter
        if counter > imports.count - 1 {
            self.currentImport = imports.last!
        } else {
            self.currentImport = imports[counter]
        }
    }
    
    func moveToNextPlaylist() {
        
        self.currentImport.endTime = Date()
        self.totalProcessed += 1
        if self.totalProcessed < self.imports.count {
            self.currentImport = self.imports[self.totalProcessed]
        }
    }
}

enum ImportError: Error {
    case noConnection
    case token
    case storefrontFailed
    case playlistCreation(originalError: Error)
}

class ImportManager {
    
    private(set) var persistedImportID: String
    private(set) var destinationProvider: DestinationServiceProviding
    private(set) var isPaused = false
    private(set) var importInfo: ImportInfo

    private var ignoreImportedTracks: Bool
    private var trackProgressHandler: TrackImportProgressHandler?
    private var playlistProgressHandler: PlaylistImportProgressHandler?
    
    private var reachability = NetworkReachabilityManager()
    private var isPausedForNoConnection = false
    private var isInRetryMode = false
    private var refreshMode = false
    
    // initialize an import from scratch
    convenience init?(playlistSelections: [PlaylistSelection], destinationProvider: DestinationServiceProviding) {
        
        var imports: [Import] = []
        for selection in playlistSelections {
            if let persistedImport = Import.persistImport(withSelection: selection) {
                imports.append(persistedImport)
            } else {
                return nil
            }
        }
        
        if let persistedImport = ImportCollection.persistImportCollection(withImports: imports) {
            self.init(persistedImport: persistedImport, destinationProvider: destinationProvider)
        } else {
            return nil
        }
    }
    
    // playlist refresher
    convenience init?(imports: [Import], playlistSelections: [PlaylistSelection], destinationProvider: DestinationServiceProviding) {
        guard imports.count == playlistSelections.count else { return nil }
        
        for i in 0..<imports.count {
            let persistedImport = imports[i]
            let selection = playlistSelections[i]
            
            persistedImport.realm?.beginWrite()
            for track in selection.tracks {
                if !(track is RealmTrack) {
                    let realmTrack = RealmTrack(track)
                    persistedImport.tracks.append(realmTrack)
                }
            }
            try? persistedImport.realm?.commitWrite()
        }
        
        guard let importCollection = ImportCollection.persistImportCollection(withImports: imports) else { return nil }
        self.init(persistedImport: importCollection, destinationProvider: destinationProvider, ignoreImportedTracks: true)
        self.refreshMode = true
    }
    
    init(persistedImport: ImportCollection, destinationProvider: DestinationServiceProviding, ignoreImportedTracks: Bool = false) {
        
        self.ignoreImportedTracks = ignoreImportedTracks
        self.persistedImportID = persistedImport.uuid
        self.destinationProvider = destinationProvider
        
        let importInfos = persistedImport.imports.map { PlaylistImportInfo(persistedImport: $0, ignoreImportedTracks: ignoreImportedTracks) }
        self.importInfo = ImportInfo(imports: Array(importInfos))
        
        self.monitorNetwork()
    }
    
    private func monitorNetwork() {
        
        self.reachability?.startListening()
        self.reachability?.listener = { [weak self] status in
            guard let strongSelf = self else { return }

            switch status {
            case .notReachable:
                strongSelf.isPausedForNoConnection = true
                
                if !strongSelf.isPaused {
                    strongSelf.pause()
                    strongSelf.trackProgressHandler?(nil, false, ImportError.noConnection)
                }
                
            case .reachable:
                if strongSelf.isPausedForNoConnection {
                    strongSelf.resume()
                }
                
            default:
                break
            }
        }
    }
    
    private func endImport() {
        
        self.isPaused = true
        
        self.reachability?.stopListening()
        self.reachability?.listener = nil
    }
    
    private func find(track trackID: String, callback: TrackSearchBlock?) {
    
        self.findCloudKitMatchFor(track: trackID) { record in
            if let record = record {
                let searchResult = CloudKitSearchResult(dictionary: record.dictionaryRepresentation())
                callback?(searchResult, [], nil)
            } else {
                guard let track = self.databaseTrack(withID: trackID) else { return }
                self.destinationProvider.find(track: RealmTrack(value: track), callback: callback)
            }
        }
    }
    
    private func databaseTrack(withID trackID: String) -> RealmTrack? {
        
        guard let realm = try? Realm() else { fatalError("Couldn't get realm") }
        if let track = realm.object(ofType: RealmTrack.self, forPrimaryKey: trackID) {
            self.isInRetryMode = false
            return track
        } else if self.isInRetryMode {
            fatalError("No track for trackID \(trackID) after retry")
        } else {
            self.isInRetryMode = true
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1, execute: {
                self.importInfo.currentImport.totalProcessed -= 1
                self.importNext()
            })
            return nil
        }
    }
    
    private func importTrack(_ trackID: String) {
        
        let nextHandler: (RealmTrack) -> Void = { track in
            self.importInfo.currentImport.totalProcessed += 1
            if !self.isInRetryMode {
                self.trackProgressHandler?(track, self.importInfo.currentImport.isFinished, track.error)
            }
            self.importNext()
        }
        
        self.find(track: trackID) { searchResult, searches, error in
            if self.isPausedForNoConnection {
                return
            } else if let error = error as? ImportError, error == ImportError.token || error == ImportError.storefrontFailed {
                self.pause()
                self.trackProgressHandler?(nil, false, error)
                return
            }
            
            guard let realm = try? Realm() else { fatalError("Couldn't get realm") }
            guard let track = self.databaseTrack(withID: trackID) else { return }
            
            if !realm.isInWriteTransaction {
                realm.beginWrite()
            }
            
            track.add(searches)
            
            if error != nil {
                track.errorDescription = error?.localizedDescription
                track.status = .error
                
                if realm.isInWriteTransaction {
                    do {
                        try realm.commitWrite()
                    } catch {
                        fatalError("Coudln't commit write on importTrack error != nil")
                    }
                }
            } else if searchResult == nil {
                track.status = .notFound
                
                if realm.isInWriteTransaction {
                    do {
                        try realm.commitWrite()
                    } catch {
                        fatalError("Coudln't commit write on importTrack searchResult == nil")
                    }
                }
            } else if let searchResult = searchResult {
                try? realm.commitWrite()
                self.destinationProvider.addTrack(fromSearchResult: searchResult, toPlaylist: self.importInfo.currentImport.destinationPlaylist!, callback: { error in
                    
                    guard let realm = try? Realm() else { fatalError("Couldn't get realm") }
                    guard let track = self.databaseTrack(withID: trackID) else { return }
                    
                    if !realm.isInWriteTransaction {
                        realm.beginWrite()
                    }
                    
                    if self.isPausedForNoConnection {
                        track.removeAllSearches()
                        try? realm.commitWrite()
                        return
                    }
                    
                    if let error = error as? MPError, error.code == .notFound {
                        self.trackProgressHandler?(nil, false, error)
                        self.pause()
                        return
                    }
                    
                    if error == nil {
                        track.matchedResult = searchResult
                        track.status = .found
                        
                        self.persistMatchToCloudKit(track: track, search: searches.last, searchResult: searchResult)
                    } else {
                        track.error = error
                        track.status = .error
                    }
                    
                    try? realm.commitWrite()
                    nextHandler(track)
                })
                
                return
            }
            
            nextHandler(track)
        }
    }
    
    private func importNext() {

        if self.isPaused {
            return
        }
        
        if self.importInfo.currentImport.isFinished {
            self.importInfo.currentImport.updateTracks()
            self.importInfo.moveToNextPlaylist()
            if self.importInfo.isFinished {
                self.endImport()
                self.playlistProgressHandler?(self.importInfo.currentImport.playlist, true)
            } else {
                self.playlistProgressHandler?(self.importInfo.currentImport.playlist, false)
                self.importNext()
            }
            
            return
        }
        
        if self.importInfo.currentImport.destinationPlaylist == nil {
            self.destinationProvider.createPlaylist(name: self.importInfo.currentImport.playlist.name, callback: { playlist, error in
                
                if let playlist = playlist {
                    self.importInfo.currentImport.destinationPlaylist = playlist
                    self.importNext()
                } else if let error = error {
                    let importError = ImportError.playlistCreation(originalError: error)
                    self.trackProgressHandler?(nil, false, importError)
                }
            })
            return
        }
        
        let track = self.importInfo.currentImport.tracks[self.importInfo.currentImport.totalProcessed]
        
        if track.status != .unprocessed && !self.refreshMode {
            self.importInfo.currentImport.totalProcessed += 1
            self.importNext()
            return
        }
        
        self.importTrack(track.uuid)
    }
}

// MARK: - Cloud Kit

extension ImportManager {
    
    fileprivate func findCloudKitMatchFor(track trackID: String, callback: @escaping (CKRecord?) -> Void) {

        if Helper.testMode {
            callback(nil)
            return
        }
        
        guard let track = self.databaseTrack(withID: trackID) else { return }
        print("sourceService: \(track.service) - destinationService: \(self.destinationProvider.service) - trackID: \(track.id) - regionIdentifier: \(self.destinationProvider.regionIdentifier)")
        
        let predicate = NSPredicate(format: "sourceService == %@ AND destinationService == %@ AND sourceServiceTrackID == %@ AND regionIdentifier == %@", track.service.rawValue, self.destinationProvider.service.rawValue, track.id, self.destinationProvider.regionIdentifier)
        let query = CKQuery(recordType: Constants.cloudKitMatchRecordType, predicate: predicate)
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            
            if let records = records, records.count > 0 {
                
                let record = records[0]
                record["totalMatches"] = NSNumber(value: (record["totalMatches"] as! Int) + 1)
                
                let updateOperation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
                updateOperation.modifyRecordsCompletionBlock = { _, _, _ in
                    NSLog("Updated match count")
                }
                CKContainer.default().publicCloudDatabase.add(updateOperation)
                
                callback(record)
            } else {
                callback(nil)
            }
        }
    }
    
    fileprivate func persistMatchToCloudKit(track: Track, search: Search?, searchResult: SearchResult) {
        
        guard let search = search, !(searchResult is CloudKitSearchResult), searchResult.isStreamable else {
            return
        }
        
        let trackMatchRecordID = CKRecordID(recordName: UUID().uuidString)
        let trackMatchRecord = CKRecord(recordType: Constants.cloudKitMatchRecordType, recordID: trackMatchRecordID)
        trackMatchRecord["sourceService"] = track.service.rawValue as NSString
        trackMatchRecord["sourceServiceTrackID"] = track.id as NSString
        trackMatchRecord["destinationService"] = self.destinationProvider.service.rawValue as NSString
        trackMatchRecord["destinationServiceTrackID"] = searchResult.trackID as NSString
        trackMatchRecord["regionIdentifier"] = self.destinationProvider.regionIdentifier as NSString
        trackMatchRecord["trackName"] = searchResult.trackName as NSString
        trackMatchRecord["artist"] = searchResult.artist as NSString
        trackMatchRecord["album"] = searchResult.album as NSString
        trackMatchRecord["albumCoverURL"] = searchResult.albumCoverURL?.absoluteString as NSString?
        trackMatchRecord["duration"] = NSNumber(value: searchResult.duration)
        trackMatchRecord["isStreamable"] = NSNumber(value: searchResult.isStreamable)
        trackMatchRecord["query"] = search.query as NSString
        trackMatchRecord["totalMatches"] = NSNumber(value: 1)
        trackMatchRecord["foundAt"] = NSDate()
        
        CKContainer.default().publicCloudDatabase.save(trackMatchRecord) { (record, error) in
            NSLog("Saved match in CloudKit")
        }
    }
}

// MARK: - Public methods

extension ImportManager {
    
    static func restoreImport(withImportCollectionID importID: String, destinationProvider: DestinationServiceProviding) -> ImportManager? {
        guard let realm = try? Realm(), let persistedImport = realm.object(ofType: ImportCollection.self, forPrimaryKey: importID) else { return nil }
        return ImportManager(persistedImport: persistedImport, destinationProvider: destinationProvider)
    }
    
    static func persistedImports() -> [Import] {
        
        guard let realm = try? Realm() else { return [] }
        let imports = realm.objects(Import.self).sorted(byKeyPath: "date", ascending: false)
        
        return Array(imports)
    }
    
    static func delete(persistedImport: Import) {
        
        try? persistedImport.realm?.write {
            persistedImport.realm?.delete(persistedImport)
        }
    }
    
    public func startImport(trackProgressHandler: @escaping TrackImportProgressHandler, playlistProgressHandler: @escaping PlaylistImportProgressHandler) {

        self.isPaused = false
        self.trackProgressHandler = trackProgressHandler
        self.playlistProgressHandler = playlistProgressHandler
        
        if self.importInfo.currentImport.startTime == nil {
            self.importInfo.currentImport.startTime = Date()
        } else {
            self.importInfo.currentImport.numberOfInterruptions += 1 // Only start counting from the second start
        }
        
        self.importNext()
    }
    
    public func pause() {
        self.isPaused = true
    }
    
    public func resume() {
        
        self.isPaused = false
        self.isPausedForNoConnection = false
        self.importNext()
    }
}

// MARK: - 

extension CKRecord {
    
    func dictionaryRepresentation() -> [String: Any] {
        
        var dictionary: [String: Any] = [:]
        for key in self.allKeys() {
            dictionary[key] = self[key]
        }
        return dictionary
    }
}
