//
//  PlaylistPaging.swift
//  jMusic
//
//  Created by Jota Melo on 28/12/16.
//  Copyright © 2016 Jota. All rights reserved.
//

import Foundation

typealias PageBlock = (PlaylistPaging?, Error?) -> Void

protocol PlaylistPaging {

    var hasNextPage: Bool { get }
    var items: [Playlist] { get }
    
    func loadNextPage(_ callback: PageBlock?)
}
