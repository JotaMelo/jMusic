//
//  SelectionCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol SelectionCoordinatorDelegate: CoordinatorDelegate {
    func didSelect(_ selections: [PlaylistSelection], on selectionCoordinator: SelectionCoordinator)
}

final class SelectionCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private var sourceService: SourceServiceProviding
    private weak var firstViewController: UIViewController?
    private var selectedPlaylists: [Playlist] = []

    required init(sourceService: SourceServiceProviding, navigationController: UINavigationController, delegate: SelectionCoordinatorDelegate?, playlists: [Playlist]? = nil) {
        
        self.sourceService = sourceService
        self.navigationController = navigationController
        self.delegate = delegate
        
        if let playlists = playlists {
            self.selectedPlaylists = playlists
        }
    }
    
    func start() {
        
        if self.selectedPlaylists.count > 0 {
            let tracksViewController = self.showTrackChooser()
            tracksViewController?.titleText = NSLocalizedString("SECOND STEP", comment: "")
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        hud.label.text = NSLocalizedString("Fetching your playlists...", comment: "")
        
        self.sourceService.userPlaylists { [weak self] (playlistPage, error) in
            hud.hide(animated: true)
            
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                
                self?.navigationController.present(alertController, animated: true, completion: nil)
            } else if let playlistPage = playlistPage {
                self?.showPlaylistChooser(playlistPage: playlistPage)
            }
        }
    }
    
    func showPlaylistChooser(playlistPage: PlaylistPaging) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let playlistChooserViewController = storyboard.instantiateViewController(withIdentifier: "PlaylistChooserViewController") as! PlaylistChooserViewController //PlaylistChooserViewController.initFromStoryboard(named: "Main")
        playlistChooserViewController.sourceService = self.sourceService
        playlistChooserViewController.currentPage = playlistPage
        playlistChooserViewController.delegate = self
        playlistChooserViewController.baseDelegate = self
        
        self.navigationController.pushViewController(playlistChooserViewController, animated: true)
        
        self.firstViewController = playlistChooserViewController
    }
    
    @discardableResult
    func showTrackChooser() -> TracksChooserViewController! {
        
        if self.selectedPlaylists.count == 1 {
            let tracksChooserViewController = TracksChooserViewController.initFromStoryboard(named: "Main")
            tracksChooserViewController.tracks = self.selectedPlaylists[0].tracks ?? []
            tracksChooserViewController.delegate = self
            self.navigationController.pushViewController(tracksChooserViewController, animated: true)
            
            return tracksChooserViewController
        } else {
            let tracksChooserViewController = MultiPlaylistTrackChooserViewController.initFromStoryboard(named: "Main")
            tracksChooserViewController.playlists = self.selectedPlaylists
            tracksChooserViewController.delegate = self
            self.navigationController.pushViewController(tracksChooserViewController, animated: true)
            
            self.selectedPlaylists = []
            return nil
        }
    }
    
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool {
        
        guard let viewController = self.firstViewController else { return false }
        self.navigationController.popToViewController(viewController, animated: true)
        return true
    }
}

// MARK: - Base View Controller delegate

extension SelectionCoordinator: BaseViewControllerDelegate {
    
    func viewControllerDidExit(_ viewController: BaseViewController) {
        
        if viewController is PlaylistChooserViewController {
            self.delegate?.coordinatorDidExit(self)
        }
    }
}

// MARK: - Playlist Chooser View Controller delegate

extension SelectionCoordinator: PlaylistChooserViewControllerDelegate {
    
    func didSelect(playlists: [Playlist], on playlistChooserViewController: PlaylistChooserViewController) {
        self.loadTracks(forPlaylists: playlists, playlistChooserViewController: playlistChooserViewController)
    }
    
    func didEnterPlaylistURL(_ playlistURL: URL, on playlistChooserViewController: PlaylistChooserViewController) {
        self.loadTracks(forPlaylistURL: playlistURL, playlistChooserViewController: playlistChooserViewController)
    }
    
    func show(error: Error) {
        
        let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func loadTracks(forPlaylists playlists: [Playlist], playlistChooserViewController: PlaylistChooserViewController) {
        
        var playlists = playlists
        let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        hud.label.text = NSLocalizedString("Fetching all tracks...", comment: "")
        
        var fetchTracks: ((Playlist) -> Void)!
        fetchTracks = { playlist in
            self.sourceService.tracksFor(playlist: playlist, callback: { [weak self] playlist, tracks, error in
                
                if let error = error {
                    self?.selectedPlaylists = []
                    hud.hide(animated: true)
                    self?.show(error: error)
                } else if let tracks = tracks, var playlist = playlist {
                    playlist.tracks = tracks
                    self?.selectedPlaylists.append(playlist)
                    if playlists.count > 0 {
                        fetchTracks(playlists.removeFirst())
                        return
                    }
                    
                    hud.hide(animated: true)
                    UIView.animate(withDuration: 0.25, animations: {
                        playlistChooserViewController.scrollToTop()
                    }, completion: { (finished) in
                        _ = self?.showTrackChooser()
                    })
                }
            })
        }
        fetchTracks(playlists.removeFirst())
    }
    
    func loadTracks(forPlaylistURL url: URL, playlistChooserViewController: PlaylistChooserViewController) {
        
        let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        hud.label.text = NSLocalizedString("Fetching all tracks...", comment: "")
        self.sourceService.tracksFor(playlistURL: url) { [weak self] playlist, tracks, error in
            hud.hide(animated: true)
            
            if let error = error {
                self?.show(error: error)
            } else if let tracks = tracks, var playlist = playlist {
                playlist.tracks = tracks
                self?.selectedPlaylists.append(playlist)

                hud.hide(animated: true)
                UIView.animate(withDuration: 0.25, animations: {
                    playlistChooserViewController.scrollToTop()
                }, completion: { (finished) in
                    _ = self?.showTrackChooser()
                })
            }
        }
    }
}

// MARK: - Tracks Chooser View Controller delegate

extension SelectionCoordinator: TracksChooserViewControllerDelegate {
    
    func didSelectTracks(_ tracks: [Track], on tracksChooserViewController: TracksChooserViewController) {
        
        if let delegate = self.delegate as? SelectionCoordinatorDelegate {
            let selection = PlaylistSelection(playlist: self.selectedPlaylists[0], tracks: tracks)
            delegate.didSelect([selection], on: self)
            self.selectedPlaylists = []
        }
    }
}

// MARK: - Multi Playlist Tracks Chooser View Controller delegate

extension SelectionCoordinator: MultiPlaylistTrackChooserViewControllerDelegate {
    
    func didSelect(_ selections: [PlaylistSelection], on viewController: MultiPlaylistTrackChooserViewController) {
        
        if let delegate = self.delegate as? SelectionCoordinatorDelegate {
            delegate.didSelect(selections, on: self)
        }
    }
}
