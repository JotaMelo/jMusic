//
//  PlaylistRefreshCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 19/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol PlaylistRefreshCoordinatorDelegate: CoordinatorDelegate {
    func didTapImportNewPlaylist(sourceService: SourceServiceProviding?, on refreshCoordinator: PlaylistRefreshCoordinator)
}

class PlaylistRefreshCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private var firstViewController: PlaylistRefreshViewController?
    private var selectedImports: [Import] = []
    private var sourceService: SourceServiceProviding?
    
    required init(navigationController: UINavigationController, delegate: PlaylistRefreshCoordinatorDelegate?) {
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    func start() {
        self.showPlaylistRefresh()
    }
    
    func showPlaylistRefresh() {
        
        let playlistRefreshViewController = PlaylistRefreshViewController.initFromStoryboard(named: "Main")
        playlistRefreshViewController.imports = ImportManager.persistedImports()
        playlistRefreshViewController.delegate = self
        playlistRefreshViewController.baseDelegate = self
        
        self.firstViewController = playlistRefreshViewController
        self.navigationController.pushViewController(playlistRefreshViewController, animated: true)
    }
    
    func showAuthentication() {
        
        let authenticationCoordinator = ServiceAuthenticationCoordinator(navigationController: self.navigationController, delegate: self, selectedService: self.selectedImports[0].sourcePlaylist.service)
        authenticationCoordinator.start()
        
        self.childCoordinators.append(authenticationCoordinator)
    }
    
    func loadTracks() {
        guard let sourceService = self.sourceService else { return }
        
        let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        hud.label.text = NSLocalizedString("Fetching latest tracks...", comment: "")
        
        var imports = self.selectedImports
        var loadedPlaylists: [Playlist] = []
        var fetchTracks: ((Import) -> Void)!
        fetchTracks = { `import` in
            sourceService.tracksFor(playlist: `import`.sourcePlaylist, callback: { [weak self] playlist, tracks, error in
                
                if let error = error {
                    hud.hide(animated: true)
                    let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                    self?.navigationController.present(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                guard let tracks = tracks else { return }
                var currentTrackIDs: [String] = []
                var unimportedTracks: [Track] = []
                
                for track in `import`.tracks {
                    currentTrackIDs.append(track.id)
                    
                    if track.status != .found {
                        unimportedTracks.append(track)
                    }
                }
                
                for track in tracks {
                    if !currentTrackIDs.contains(track.id) {
                        unimportedTracks.append(track)
                    }
                }
                
                let playlist = `import`.sourcePlaylist!
                playlist.tracks = unimportedTracks
                loadedPlaylists.append(playlist)
                
                if imports.count == 0 {
                    hud.hide(animated: true)
                    self?.showSelection(with: loadedPlaylists)
                } else {
                    fetchTracks(imports.removeFirst())
                }
            })
        }
        fetchTracks(imports.removeFirst())
    }
    
    func showSelection(with playlists: [Playlist]) {
        guard let sourceService = self.sourceService else { return }
        
        if playlists.reduce(0, { $0 + ($1.tracks?.count ?? 0) }) == 0 {
            
            let alertController = UIAlertController(title: NSLocalizedString("No new songs found", comment: ""), message: NSLocalizedString("Would you like to import a new playlist?", comment: ""), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Let's go", comment: ""), style: .default, handler: { action in
                if let delegate = self.delegate as? PlaylistRefreshCoordinatorDelegate {
                    delegate.didTapImportNewPlaylist(sourceService: self.sourceService, on: self)
                }
            })
            let nopeAction = UIAlertAction(title: NSLocalizedString("No, thanks", comment: ""), style: .cancel, handler: { action in
                self.firstViewController?.clearTableSelection()
            })
            alertController.addAction(okAction)
            alertController.addAction(nopeAction)
            self.navigationController.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        let selectionCoordinator = SelectionCoordinator(sourceService: sourceService, navigationController: self.navigationController, delegate: self, playlists: playlists)
        self.childCoordinators.append(selectionCoordinator)
        
        UIView.animate(withDuration: 0.25, animations: {
            self.firstViewController?.scrollToTop()
        }, completion: { finished in
            selectionCoordinator.start()
        })
    }
    
    func showImport(with selections: [PlaylistSelection]) {
        
        let service = AppleMusicService()
        if let importManager = ImportManager(imports: self.selectedImports, playlistSelections: selections, destinationProvider: service) {
            let importCoordinator = ImportCoordinator(importManager: importManager, navigationController: self.navigationController, delegate: self)
            importCoordinator.start()
            
            self.childCoordinators.append(importCoordinator)
        }
    }
    
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool {
        guard let viewController = self.firstViewController else { return false }
        
        self.navigationController.popToViewController(viewController, animated: true)
        self.childCoordinators = []
        return true
    }
}

extension PlaylistRefreshCoordinator: BaseViewControllerDelegate {
    
    func viewControllerDidExit(_ viewController: BaseViewController) {
        
        if viewController == self.firstViewController {
            self.delegate?.coordinatorDidExit(self)
        }
    }
}

extension PlaylistRefreshCoordinator: PlaylistRefreshViewControllerDelegate {
    
    func persistedImports(on playlistRefreshViewController: PlaylistRefreshViewController) -> [Import] {
        return ImportManager.persistedImports()
    }
    
    func didRemove(import: Import, on playlistRefreshViewController: PlaylistRefreshViewController) {
        
        ImportManager.delete(persistedImport: `import`)
        
        if ImportManager.persistedImports().count == 0 {
            self.navigationController.popViewController(animated: true)
            self.delegate?.coordinatorDidExit(self)
        }
    }
    
    func didSelect(imports: [Import], on playlistRefreshViewController: PlaylistRefreshViewController) {
        
        self.selectedImports = imports
        
        if SpotifyService().authenticated {
            self.sourceService = SpotifyService()
        }
        
        if self.sourceService == nil {
            self.showAuthentication()
        } else {
            self.loadTracks()
        }
    }
}

extension PlaylistRefreshCoordinator: ServiceAuthenticationCoordinatorDelegate {
    
    func didAuthenticate(sourceService: SourceServiceProviding, on authenticationCoordinator: ServiceAuthenticationCoordinator) {
        
        self.sourceService = sourceService
        self.loadTracks()
    }
}

extension PlaylistRefreshCoordinator: SelectionCoordinatorDelegate {
    
    func didSelect(_ selections: [PlaylistSelection], on selectionCoordinator: SelectionCoordinator) {
        self.showImport(with: selections)
    }
}
