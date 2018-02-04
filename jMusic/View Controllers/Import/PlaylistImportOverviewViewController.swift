//
//  PlaylistImportOverviewViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import iRate

protocol PlaylistImportOverviewViewControllerDelegate: class {
    func didTapRestart(on importOverviewViewController: PlaylistImportOverviewViewController)
    func didSelect(track: Track, on importOverviewViewController: PlaylistImportOverviewViewController)
}

class PlaylistImportOverviewViewController: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var middleBallView: JMView!
    @IBOutlet var middleLineView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var whiteGradientImageView: UIImageView!
    @IBOutlet var startOverButton: JMButton!
    
    @IBOutlet var allSongsButton: UIButton!
    @IBOutlet var notFoundButton: UIButton!
    
    @IBOutlet var chooserHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: PlaylistImportOverviewViewControllerDelegate?
    var playlistImportInfo: PlaylistImportInfo!
    var isLastStep = false
    var isImportDone = false
    
    private var showFailedOnly = false
    private lazy var indexPathsForSuccessfulTracks: [IndexPath] = {
        var indexPaths: [IndexPath] = []
        for i in 0..<self.playlistImportInfo.tracks.count {
            let track = self.playlistImportInfo.tracks[i]
            
            if track.status == .found {
                let indexPath = IndexPath(row: i, section: 0)
                indexPaths.append(indexPath)
            }
        }
        
        return indexPaths
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.isLastStep {
            iRate.sharedInstance().logEvent(false)
            self.title = NSLocalizedString("All Done", comment: "")
            self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
            self.navigationItem.hidesBackButton = true
        } else {
            if self.isImportDone {
                self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
            } else {
                self.navigationBarBackgroundColor = Colors.inProgressNavigationBarBackgrondColor
                self.middleBallView.backgroundColor = Colors.inProgressNavigationBarBackgrondColor
                self.middleLineView.backgroundColor = Colors.inProgressNavigationBarBackgrondColor
            }
            
            self.title = self.playlistImportInfo.playlist.name
            self.titleLabel.text = self.title
            self.whiteGradientImageView.isHidden = true
            
            // "why not just hide it?" removing it has the nice
            // side effect of deleting the bottom constraint from
            // the table view to it
            self.startOverButton.removeFromSuperview()
        }
        
        if self.playlistImportInfo.unsuccessfulTracks.count > 0 {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareFailedSongs))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateUI()
        self.sizeTableHeaderToFit()
    }
    
    func updateUI() {
        
        if self.playlistImportInfo.unsuccessfulTracks.count == 0 {
            self.descriptionLabel.text = String.localizedStringWithFormat("%lu song%@ imported", self.playlistImportInfo.tracks.count, self.playlistImportInfo.tracks.count > 1 ? "s" : "")
        } else if self.playlistImportInfo.unsuccessfulTracks.count == 1 {
            self.descriptionLabel.text = NSLocalizedString("One song couldn't be imported. Tap on it to find out why.", comment: "")
        } else {
            self.descriptionLabel.text = String.localizedStringWithFormat("%lu songs couldn't be imported. Tap on them to find out why.", self.playlistImportInfo.unsuccessfulTracks.count)
        }
        
        if self.playlistImportInfo.unsuccessfulTracks.count == 0 {
            self.chooserHeightConstraint.constant = 0
        } else {
            self.chooserHeightConstraint.constant = 50
        }
        
        if self.showFailedOnly && self.playlistImportInfo.unsuccessfulTracks.count == 0 {
            self.showFailedOnly = false
        }
        
        self.tableView.reloadData()
    }
    
    func sizeTableHeaderToFit() {
    
        guard let header = self.tableView.tableHeaderView else { return }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        header.frame.size.height = header.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
    }
    
    func animateToImportDone() {
        guard self.middleLineView != nil else { return }
        
        UIView.animate(withDuration: 0.25, animations: {
            let lineDoneColor = Colors.doneNavigationBarBackgroundColor.withAlphaComponent(0.52).cgColor
            self.middleLineView.layer.backgroundColor = lineDoneColor
            self.middleBallView.layer.backgroundColor = Colors.doneNavigationBarBackgroundColor.cgColor
            
            self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
            self.navigationController?.navigationBar.barTintColor = Colors.doneNavigationBarBackgroundColor
            self.navigationController?.navigationBar.layoutIfNeeded()
        })
    }
    
    // MARK: - UI Actions
    
    @objc func shareFailedSongs() {
        
        var shareText = "\(self.playlistImportInfo.playlist.name)\n\n"
        for song in self.playlistImportInfo.unsuccessfulTracks {
            shareText += "\(song.name) - \(song.artist)\n"
        }
        let activityController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    @IBAction func toggleSongsDisplay(_ sender: UIButton) {
        
        if sender == self.allSongsButton && self.showFailedOnly {
            self.showFailedOnly = false
            
            self.allSongsButton.backgroundColor = Colors.segmentedControlSelectedColor
            self.allSongsButton.setTitleColor(Colors.segmentedControlDeselectedColor, for: .normal)
            
            self.notFoundButton.backgroundColor = Colors.segmentedControlDeselectedColor
            self.notFoundButton.setTitleColor(Colors.segmentedControlSelectedColor, for: .normal)
            
            self.tableView.insertRows(at: self.indexPathsForSuccessfulTracks, with: .automatic)
        } else  if sender == self.notFoundButton && !self.showFailedOnly {
            self.showFailedOnly = true
            
            self.notFoundButton.backgroundColor = Colors.segmentedControlSelectedColor
            self.notFoundButton.setTitleColor(Colors.segmentedControlDeselectedColor, for: .normal)
            
            self.allSongsButton.backgroundColor = Colors.segmentedControlDeselectedColor
            self.allSongsButton.setTitleColor(Colors.segmentedControlSelectedColor, for: .normal)
            
            self.tableView.deleteRows(at: self.indexPathsForSuccessfulTracks, with: .automatic)
        }
    }
    
    @IBAction func restart(_ sender: Any) {
        self.delegate?.didTapRestart(on: self)
    }
}

// MARK: - Table View data source / delegate

extension PlaylistImportOverviewViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.showFailedOnly ? self.playlistImportInfo.unsuccessfulTracks.count : self.playlistImportInfo.tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tracks = self.showFailedOnly ? self.playlistImportInfo.unsuccessfulTracks : self.playlistImportInfo.tracks
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
        cell.isStatusCell = true
        cell.track = tracks[indexPath.row]
        cell.isLastCell = indexPath.row == tracks.count - 1
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let tracks = self.showFailedOnly ? self.playlistImportInfo.unsuccessfulTracks : self.playlistImportInfo.tracks
        self.delegate?.didSelect(track: tracks[indexPath.row], on: self)
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
