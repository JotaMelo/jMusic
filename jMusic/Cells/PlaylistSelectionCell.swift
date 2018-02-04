//
//  PlaylistSelectionCell.swift
//  jMusic
//
//  Created by Jota Melo on 1/12/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import UIKit

class PlaylistSelectionCell: UITableViewCell {
    
    @IBOutlet var playlistNameLabel: UILabel!
    @IBOutlet var importCountLabel: UILabel!
    @IBOutlet var chevronImageView: UIImageView!
    
    var selection: PlaylistSelection! {
        didSet {
            self.playlistNameLabel.text = self.selection.playlist.name
            self.importCountLabel.text = "\(self.selection.tracks.count)/\(self.selection.playlist.tracks!.count) selected"
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        UIView.animate(withDuration: 0.25) {
            self.chevronImageView.transform = selected ? CGAffineTransform.identity.rotated(by: .pi / 2) : CGAffineTransform.identity
        }
    }
}
