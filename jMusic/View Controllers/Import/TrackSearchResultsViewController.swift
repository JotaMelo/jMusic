//
//  TrackSearchResultsViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol TrackSearchResultsViewControllerDelegate: class {
    func didReportCorrectSearchResult(_ searchResult: SearchResult, forTrack track: Track, on trackSearchResultsViewController: TrackSearchResultsViewController)
    func didTapAddSearchResult(_ searchResult: SearchResult, on trackSearchResultsViewController: TrackSearchResultsViewController)
}

class TrackSearchResultsViewController: BaseViewController {

    @IBOutlet var queryLabel: UILabel!
    @IBOutlet var noResultsLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    weak var delegate: TrackSearchResultsViewControllerDelegate?
    var search: Search!
    var track: Track!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Search Results", comment: "")
        
        self.queryLabel.text = self.search.query
        self.noResultsLabel.isHidden = self.search.results.count > 0
        self.tableView.isScrollEnabled = self.noResultsLabel.isHidden
        
        if self.track.status == .found {
            self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
            self.tableView.allowsSelection = false
        } else {
            self.navigationBarBackgroundColor = Colors.errorColor
        }
    }
    
    func clearTableSelection() {
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    func showTrackCorrectionAlert(forSearchResult searchResult: SearchResult) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Is this the right song?", comment: ""), message: NSLocalizedString("If it is, data about the track will be sent to us to improve the matching algorithm.", comment: ""), preferredStyle: .actionSheet)
        let yepAction = UIAlertAction(title: NSLocalizedString("Yes that's the song", comment: ""), style: .default) { action in
            self.delegate?.didReportCorrectSearchResult(searchResult, forTrack: self.track, on: self)
            self.showTrackAddConfirmationAlert(forSearchResult: searchResult)
        }
        let nopeAction = UIAlertAction(title: NSLocalizedString("Nope", comment: ""), style: .cancel) { action in
            self.clearTableSelection()
        }
        
        alertController.addAction(yepAction)
        alertController.addAction(nopeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showTrackAddConfirmationAlert(forSearchResult searchResult: SearchResult) {
     
        let alertController = UIAlertController(title: NSLocalizedString("Do you want to add this song to the playlist?", comment: ""), message: NSLocalizedString("The Apple Music API doesn't allow inserting songs to a playlist at a specific position, but we can add it to the end. Should we do that?", comment: ""), preferredStyle: .actionSheet)
        let yepAction = UIAlertAction(title: NSLocalizedString("Please!", comment: ""), style: .default) { action in
            self.delegate?.didTapAddSearchResult(searchResult, on: self)
        }
        let nopeAction = UIAlertAction(title: NSLocalizedString("Nah", comment: ""), style: .cancel) { action in
            self.clearTableSelection()
        }
        
        alertController.addAction(yepAction)
        alertController.addAction(nopeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Table View data source / delegate

extension TrackSearchResultsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.search.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        cell.searchResult = self.search.results[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showTrackCorrectionAlert(forSearchResult: self.search.results[indexPath.row])
    }
}
