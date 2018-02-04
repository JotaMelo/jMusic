//
//  TrackCell.swift
//  jMusic
//
//  Created by Jota Melo on 08/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class TrackCell: UITableViewCell {
    
    @IBOutlet var separatorView: UIView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var radioButtonView: UIView!
    
    var track: Track? {
        didSet {
            self.setupUI()
        }
    }
    
    var isStatusCell = false
    var isLastCell = false
    
    private func setupUI() {
        
        guard let track = self.track else { return }
        
        let nameAttributedString = NSMutableAttributedString(string: track.name, attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir-Heavy", size: 15)!, NSAttributedStringKey.foregroundColor: Colors.contentTextColor])
        let artistAttributedString = NSMutableAttributedString(string: " - \(track.artist)", attributes: [NSAttributedStringKey.font: UIFont(name: "Avenir-Book", size: 15)!, NSAttributedStringKey.foregroundColor: Colors.contentTextColor])
        nameAttributedString.append(artistAttributedString)
        
        self.nameLabel.attributedText = nameAttributedString
        
        if self.isStatusCell {
            if track.errorDescription != nil || track.status == .notFound {
                self.radioButtonView.backgroundColor = Colors.errorColor
            } else {
                self.radioButtonView.backgroundColor = Colors.doneNavigationBarBackgroundColor
            }
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        if self.isStatusCell {
            super.setHighlighted(highlighted, animated: animated)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if !self.isStatusCell {
            self.radioButtonView.backgroundColor = selected ? Colors.radioButtonSelectedColor : Colors.radioButtonDeselectedColor
        }
    }
}
