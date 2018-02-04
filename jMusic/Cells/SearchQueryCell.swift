//
//  SearchQueryCell.swift
//  jMusic
//
//  Created by Jota Melo on 16/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class SearchQueryCell: UITableViewCell {
    
    @IBOutlet var searchTermLabel: UILabel!
    
    var search: Search? {
        didSet {
            guard let search = self.search else { return }
            self.searchTermLabel.text = search.query
        }
    }
    
}
