//
//  AppleMusicSearchResult.swift
//  jMusic
//
//  Created by Jota Melo on 11/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation
import UIKit

struct AppleMusicSearchResult: SearchResult, Mappable {
    
    var service = Service.appleMusic
    var trackID: String
    var trackName: String
    var artist: String
    var album: String
    var albumCoverURL: URL?
    var duration: TimeInterval
    var isStreamable: Bool
    
    init(mapper: Mapper) {
        
        self.trackID = mapper.keyPath("id")
        self.trackName = mapper.keyPath("attributes.name")
        self.artist = mapper.keyPath("attributes.artistName")
        self.album = ""
        self.duration = (mapper.keyPath("attributes.durationInMillis") ?? 0) / 1000
        
        let attributes: [String: Any] = mapper.keyPath("attributes")
        self.isStreamable = attributes["playParams"] != nil
        
        if let albumCoverURLString: String = mapper.keyPath("attributes.artwork.url") {
            let size = String(describing: Int(UIScreen.main.scale * 60))
            self.albumCoverURL = URL(string: albumCoverURLString.replacingOccurrences(of: "{h}", with: size).replacingOccurrences(of: "{w}", with: size))
        }
    }
}
