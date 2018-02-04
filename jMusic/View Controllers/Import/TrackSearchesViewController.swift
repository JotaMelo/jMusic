//
//  TrackSearchesViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol TrackSearchesViewControllerDelegate: class {
    func didSelect(search: Search, on trackSearchesViewController: TrackSearchesViewController)
}

class TrackSearchesViewController: BaseViewController {
    
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var description2Label: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: TrackSearchesViewControllerDelegate?
    var track: Track!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.track.name
        self.tableViewHeightConstraint.constant = CGFloat(self.track.searches.count * Constants.tableCellHeight)
        
        if self.track.status == .found {
            self.descriptionLabel.text = self.descriptionLabel.text?.replacingOccurrences(of: ", but sometimes things can go wrong.", with: "... and we did!")
            
            if self.track.searches.count == 0 {
                self.description2Label.text = NSLocalizedString("This song was found in jMusic's Match Cache. Every matched song is saved to the cloud so future imports of that song are much faster and realiable.", comment: "")
            }
            
            self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
        } else {
            self.navigationBarBackgroundColor = Colors.errorColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }
}

// MARK: - Table View delegate / data source

extension TrackSearchesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.track.searches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchQueryCell", for: indexPath) as! SearchQueryCell
        cell.search = self.track.searches[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(search: self.track.searches[indexPath.row], on: self)
    }
}
