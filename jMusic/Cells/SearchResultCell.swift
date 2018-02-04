//
//  SearchResultCell.swift
//  jMusic
//
//  Created by Jota Melo on 16/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import SDWebImage

class SearchResultCell: UITableViewCell {
    
    @IBOutlet var albumCoverImageView: UIImageView!
    @IBOutlet var trackNameLabel: UILabel!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var albumLabel: UILabel!
    
    var searchResult: SearchResult? {
        didSet {
            self.setupUI()
        }
    }
    
    func setupUI() {
        
        guard let searchResult = self.searchResult else { return }
        
        if let coverURL = searchResult.albumCoverURL {
            self.albumCoverImageView.sd_setImage(with: coverURL)
        }
        
        self.trackNameLabel.text = searchResult.trackName
        self.artistLabel.text = searchResult.artist
        self.albumLabel.text = searchResult.album
    }
}
