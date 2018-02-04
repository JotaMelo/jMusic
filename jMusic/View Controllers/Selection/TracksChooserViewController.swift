//
//  TracksChooserViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol TracksChooserViewControllerDelegate: class {
    func didSelectTracks(_ tracks: [Track], on tracksChooserViewController: TracksChooserViewController)
}

class TracksChooserViewController: BaseViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var toggleSelectionButton: UIButton!
    @IBOutlet var tableView: UITableView!

    weak var delegate: TracksChooserViewControllerDelegate?
    var tracks: [Track] = []
    var titleText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let titleText = self.titleText {
            self.titleLabel.text = titleText
        }
    }
    
    func updateToggleSelectionState() {
        
        if let indexPaths = self.tableView.indexPathsForSelectedRows, indexPaths.count == self.tracks.count {
            self.toggleSelectionButton.setTitle(NSLocalizedString("Deselect All", comment: ""), for: .normal)
        } else {
            self.toggleSelectionButton.setTitle("Select All", for: .normal)
        }
    }
    
    func scrollToTop() {
        self.tableView.contentOffset = CGPoint.zero
    }
    
    // MARK: - UI Actions
    
    @IBAction func toggleSelection(_ sender: Any) {
        
        if let indexPaths = self.tableView.indexPathsForSelectedRows, indexPaths.count == self.tracks.count {
            for indexPath in indexPaths {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        } else {
            for i in 0..<self.tracks.count {
                let indexPath = IndexPath(row: i, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        
        self.updateToggleSelectionState()
    }
    
    @IBAction func go(_ sender: Any) {
        
        if let indexPaths = self.tableView.indexPathsForSelectedRows, indexPaths.count > 0 {
            let tracks = indexPaths.map({ (indexPath) -> Track in
                return self.tracks[indexPath.row]
            })
            
            self.delegate?.didSelectTracks(tracks, on: self)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: NSLocalizedString("You need to select at least 1 song.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - Table View data source / delegate

extension TracksChooserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
        cell.track = self.tracks[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.updateToggleSelectionState()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.updateToggleSelectionState()
    }
}
