//
//  ImportCell.swift
//  jMusic
//
//  Created by Jota Melo on 18/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class ImportCell: UITableViewCell {
    
    @IBOutlet var playlistNameLabel: UILabel!
    @IBOutlet var serviceNameLabel: UILabel!
    @IBOutlet var importDateLabel: UILabel!
    @IBOutlet var importedCountLabel: UILabel!
    @IBOutlet var radioButtonView: JMView!
    
    var playlistImport: Import? {
        didSet {
            self.updateUI()
        }
    }
    
    func updateUI() {
        guard let playlistImport = self.playlistImport else { return }
        
        self.playlistNameLabel.text = playlistImport.sourcePlaylist.name
        self.serviceNameLabel.text = "From \(playlistImport.sourcePlaylist.service.rawValue)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        self.importDateLabel.text = "Imported on \(dateFormatter.string(from: playlistImport.date))"
        
        let tracks = Array(playlistImport.tracks)
        let totalFound = tracks.filter({ $0.status == .found }).count
        
        self.importedCountLabel.text = "\(totalFound) of \(tracks.count) songs imported"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.radioButtonView.backgroundColor = selected ? Colors.radioButtonSelectedColor : Colors.radioButtonDeselectedColor
    }
}
