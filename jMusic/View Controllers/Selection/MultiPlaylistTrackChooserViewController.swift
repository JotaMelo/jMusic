//
//  MultiPlaylistTrackChooserViewController.swift
//  jMusic
//
//  Created by Jota Melo on 1/13/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import UIKit

protocol MultiPlaylistTrackChooserViewControllerDelegate: class {
    func didSelect(_ selections: [PlaylistSelection], on viewController: MultiPlaylistTrackChooserViewController)
}

class MultiPlaylistTrackChooserViewController: BaseViewController {

    @IBOutlet var toggleSelectionButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    weak var delegate: MultiPlaylistTrackChooserViewControllerDelegate?
    var playlists: [Playlist] = []

    private var selections: [PlaylistSelection] = []
    private var openPlaylistsIndexes: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for i in 0..<self.playlists.count {
            let selection = PlaylistSelection(playlist: self.playlists[i], tracks: [])
            self.selections.append(selection)
        }
    }
    
    func updateToggleSelectionState() {
        
        let fullSelection = self.selections.filter { $0.isFullSelection }
        if fullSelection.count == self.playlists.count {
            self.toggleSelectionButton.setTitle(NSLocalizedString("Deselect All Playlists", comment: ""), for: .normal)
        } else {
            self.toggleSelectionButton.setTitle("Select All Playlists", for: .normal)
        }
        
        let indexPaths = self.openPlaylistsIndexes.map { IndexPath(row: 1, section: $0) }
        self.tableView.reloadRows(at: indexPaths, with: .none)
    }
    
    func scrollToTop() {
        self.tableView.contentOffset = CGPoint.zero
    }
    
    func trackIndexPaths(forPlaylistAt index: Int) -> [IndexPath] {
        
        let playlist = self.playlists[index]
        var indexPaths: [IndexPath] = []
        for i in 0..<playlist.tracks!.count {
            let indexPath = IndexPath(row: i + 2, section: index)
            indexPaths.append(indexPath)
        }
        
        return indexPaths
    }
    
    // MARK: - UI Actions
    
    @IBAction func toggleSelection(_ sender: Any) {
        
        let fullSelections = self.selections.filter { $0.isFullSelection }
        if fullSelections.count == self.playlists.count {
            for selection in self.selections {
                selection.tracks = []
            }
        } else {
            for selection in self.selections {
                selection.tracks = selection.playlist.tracks!
            }
        }
        
        for i in 0..<self.playlists.count {
            let indexPath = IndexPath(row: 0, section: i)
            self.tableView.reloadRows(at: [indexPath], with: .fade)

            
            let indexPaths = self.trackIndexPaths(forPlaylistAt: i)
            if fullSelections.count == self.playlists.count {
                for indexPath in indexPaths {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            } else {
                for indexPath in indexPaths {
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }
        }
        
        self.updateToggleSelectionState()
    }
    
    @IBAction func go(_ sender: Any) {
        
        let totalSelectedTracks = self.selections.reduce(0, { $0 + $1.tracks.count })
        if totalSelectedTracks == 0 {
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: NSLocalizedString("You need to select at least 1 song.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        self.delegate?.didSelect(self.selections.filter { $0.tracks.count > 0 }, on: self)
    }
}

// MARK: - Table View data source / delegate

extension MultiPlaylistTrackChooserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.playlists.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.openPlaylistsIndexes.contains(section) {
            return self.playlists[section].tracks!.count + 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistSelectionCell", for: indexPath) as! PlaylistSelectionCell
            cell.selection = self.selections[indexPath.section]
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SelectAllCell", for: indexPath) as! SelectAllCell
            cell.delegate = self
            
            if self.selections[indexPath.section].isFullSelection {
                cell.setDeselectAllMode()
            } else {
                cell.setSelectAllMode()
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackCell
            cell.track = self.playlists[indexPath.section].tracks?[indexPath.row - 2]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            CATransaction.begin()
            CATransaction.setCompletionBlock {
                var cellFrame = tableView.rectForRow(at: indexPath)
                cellFrame = self.view.convert(cellFrame, from: self.tableView)
                if cellFrame.minY > self.tableView.frame.height * (2 / 3) {
                    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                }
            }
            
            self.openPlaylistsIndexes.append(indexPath.section)
            let indexPathsToInsert = [IndexPath(row: 1, section: indexPath.section)] + self.trackIndexPaths(forPlaylistAt: indexPath.section)
            tableView.insertRows(at: indexPathsToInsert, with: .automatic)
            
            CATransaction.commit()
            
            let selection = self.selections[indexPath.section]
            for track in selection.tracks {
                guard let index = selection.playlist.tracks!.index(where: { $0.id == track.id }) else { continue }
                let indexPath = IndexPath(row: index + 2, section: indexPath.section)
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        } else if indexPath.row > 1 {
            let track = self.playlists[indexPath.section].tracks![indexPath.row - 2]
            self.selections[indexPath.section].tracks.append(track)
            
            let indexPath = IndexPath(row: 0, section: indexPath.section)
            if let cell = tableView.cellForRow(at: indexPath) as? PlaylistSelectionCell {
                cell.selection = self.selections[indexPath.section]
            }
        }
        
        self.updateToggleSelectionState()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            if let index = self.openPlaylistsIndexes.index(of: indexPath.section) {
                self.openPlaylistsIndexes.remove(at: index)
            }
            
            let indexPathsToRemove = [IndexPath(row: 1, section: indexPath.section)] + self.trackIndexPaths(forPlaylistAt: indexPath.section)
            tableView.deleteRows(at: indexPathsToRemove, with: .automatic)
        } else if indexPath.row > 1 {
            let track = self.playlists[indexPath.section].tracks![indexPath.row - 2]
            
            if let index = self.selections[indexPath.section].tracks.index(where: { $0.id == track.id }) {
                self.selections[indexPath.section].tracks.remove(at: index)
            }
            
            let indexPath = IndexPath(row: 0, section: indexPath.section)
            if let cell = tableView.cellForRow(at: indexPath) as? PlaylistSelectionCell {
                cell.selection = self.selections[indexPath.section]
            }
        }
        
        self.updateToggleSelectionState()
    }
}

// MARK: - Select All Cell delegate

extension MultiPlaylistTrackChooserViewController: SelectAllCellDelegate {
    
    func didTapToggle(on cell: SelectAllCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else { return }
        
        let selection = self.selections[indexPath.section]
        let indexPaths = self.trackIndexPaths(forPlaylistAt: indexPath.section)
        if selection.isFullSelection {
            selection.tracks = []
            for indexPath in indexPaths {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        } else {
            selection.tracks = selection.playlist.tracks!
            for indexPath in indexPaths {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        
        let playlistCellIndexPath = IndexPath(row: 0, section: indexPath.section)
        if let cell = tableView.cellForRow(at: playlistCellIndexPath) as? PlaylistSelectionCell {
            cell.selection = self.selections[indexPath.section]
        }
        
        self.updateToggleSelectionState()
    }
}

