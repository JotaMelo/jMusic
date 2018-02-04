//
//  jMusicTests.swift
//  jMusicTests
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import XCTest
@testable import jMusic

struct TestTrack: Track {

    var id: String
    var name: String
    var artist: String
    var album: String
    var albumCoverURL: URL?
    var duration: TimeInterval
    var service: Service
    var status: TrackStatus
    var matchedResult: SearchResult?
    var searches: [Search]
    var errorDescription: String?
}

struct TestPlaylist: Playlist {

    var id: String
    var name: String
    var userID: String?
    var type: PlaylistType
    var service: Service
    var tracks: [Track]?
}

class jMusicTests: XCTestCase {

    let testTrack = TestTrack(id: UUID().uuidString, name: "Go With It - Yung Skeeter Remix", artist: "TOKiMONSTA", album: "Go With It (Remixes)", albumCoverURL: nil, duration: 217, service: .spotify, status: .unprocessed, matchedResult: nil, searches: [], errorDescription: nil)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSpotifyService() {
        let spotify = SpotifyService()
        
        // acceptable formats:
        // spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty
        // https://open.spotify.com/user/brunolvl/playlist/6sa5ys5q1BTNNdtDO3zxty
        
        XCTAssertNil(spotify.parsePlaylistURL("spotify:brunolvl:playlist:44343434"))
        XCTAssertNil(spotify.parsePlaylistURL("spotify:user:brunolvl:348734843"))
        XCTAssertNil(spotify.parsePlaylistURL("spotify:brunolvl:348734843"))
        XCTAssertNil(spotify.parsePlaylistURL("https://open.spotify.com/brunolvl/playlist/6sa5ys5q1BTNNdtDO3zxty"))
        XCTAssertNil(spotify.parsePlaylistURL("https://open.spotify.com/user/brunolvl/6sa5ys5q1BTNNdtDO3zxty"))
        XCTAssertNil(spotify.parsePlaylistURL("https://open.spotify.com/brunolvl/6sa5ys5q1BTNNdtDO3zxty"))
        XCTAssertEqual(spotify.parsePlaylistURL("spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty")?.absoluteString, "spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty")
        XCTAssertEqual(spotify.parsePlaylistURL("https://open.spotify.com/user/brunolvl/playlist/6sa5ys5q1BTNNdtDO3zxty")?.absoluteString, "spotify:user:brunolvl:playlist:6sa5ys5q1BTNNdtDO3zxty")
    }
    
    func testAppleMusicService() {
        
        Helper.set("us", forKey: "storefrontIdentifier")
        let service = AppleMusicService()

        let expectation = self.expectation(description: "trackSearch")
        service.find(track: self.testTrack) { (searchResult, searches, error) in
            XCTAssertNotNil(searchResult, "Must find result for this track")
            XCTAssertTrue(searches.count > 0, "Must have 1 or more searches")
            XCTAssertNil(error, "No error")

            XCTAssertEqual(searchResult?.trackID, "621683531")

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { error in
            print("\(String(describing: error))")
        }

        Helper.removeDefaultsObject(forKey: "storefrontIdentifier")
    }
    
    func testImportManager() {

        let playlist = TestPlaylist(id: UUID().uuidString, name: "Test Platlist", userID: nil, type: .destination, service: .appleMusic, tracks: nil)
        let playlistSelection = PlaylistSelection(playlist: playlist, tracks: [self.testTrack])

        let destinationService = AppleMusicService()

        var importManager = ImportManager(playlistSelections: [playlistSelection], destinationProvider: destinationService)
        importManager = ImportManager.restoreImport(withImportCollectionID: importManager!.persistedImportID, destinationProvider: destinationService)

        XCTAssertNotNil(importManager, "Can't be nil, restore failed")
        XCTAssertEqual(importManager!.importInfo.imports[0].playlist.id, playlist.id)
        XCTAssertEqual(importManager!.importInfo.imports[0].tracks[0].id, self.testTrack.id)
    }
}
