//
//  SelectAllCell.swift
//  jMusic
//
//  Created by Jota Melo on 1/13/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import UIKit

protocol SelectAllCellDelegate: class {
    func didTapToggle(on cell: SelectAllCell)
}

class SelectAllCell: UITableViewCell {
    
    @IBOutlet var button: UIButton!
    
    weak var delegate: SelectAllCellDelegate?
    
    func setSelectAllMode() {
        self.button.setTitle(NSLocalizedString("Select All", comment: ""), for: .normal)
    }
    
    func setDeselectAllMode() {
        self.button.setTitle(NSLocalizedString("Deselect All", comment: ""), for: .normal)
    }

    @IBAction func go(_ sender: Any) {
        self.delegate?.didTapToggle(on: self)
    }
}
