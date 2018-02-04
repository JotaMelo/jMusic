//
//  PlaylistImportCell.swift
//  jMusic
//
//  Created by Jota Melo on 1/13/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import UIKit

class PlaylistImportCell: UITableViewCell {

    @IBOutlet var playlistNameLabel: UILabel!
    @IBOutlet var importCountLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var chevronImageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var isCurrentImport: Bool!
    var importInfo: PlaylistImportInfo! {
        didSet {
            self.playlistNameLabel.text = self.importInfo.playlist.name
            
            if self.importInfo.isFinished {
                let totalImportedTracks = self.importInfo.tracks.count - self.importInfo.unsuccessfulTracks.count
                self.importCountLabel.text = "\(totalImportedTracks) of \(self.importInfo.tracks.count) tracks imported"
                
                if totalImportedTracks < self.importInfo.tracks.count {
                    self.errorLabel.text = "\(self.importInfo.unsuccessfulTracks.count) not imported"
                    self.errorLabel.isHidden = false
                } else {
                    self.errorLabel.isHidden = true
                }
                
                self.chevronImageView.isHidden = false
                self.activityIndicator.isHidden = true
            } else {
                self.importCountLabel.text = "\(self.importInfo.totalProcessed) of \(self.importInfo.tracks.count) tracks processed"
                self.errorLabel.isHidden = true
                self.chevronImageView.isHidden = true
                
                if self.isCurrentImport {
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
}
