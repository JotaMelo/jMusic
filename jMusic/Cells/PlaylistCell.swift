//
//  PlaylistCell.swift
//  jMusic
//
//  Created by Jota Melo on 07/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class PlaylistCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var separatorView: UIView!
    @IBOutlet var radioButtonView: UIView!
    
    var playlist: Playlist? {
        didSet {
            self.nameLabel.text = playlist?.name
        }
    }
    
    var isLastCell = false {
        didSet {
            self.separatorView.isHidden = isLastCell
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.radioButtonView.backgroundColor = selected ? Colors.radioButtonSelectedColor : Colors.radioButtonDeselectedColor
    }
}
