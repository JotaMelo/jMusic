//
//  HomeCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class HomeCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    var firstViewController: UIViewController?
    
    required init(navigationController: UINavigationController, delegate: CoordinatorDelegate?) {
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    func start() {
        
        let welcomeViewController = WelcomeViewController.initFromStoryboard(named: "Main")
        welcomeViewController.baseDelegate = self
        welcomeViewController.delegate = self
        self.navigationController.viewControllers = [welcomeViewController]
        
        self.firstViewController = welcomeViewController
    }
    
    func checkForPendingImport() {
        
        guard let importID = Helper.defaultsObject(forKey: Constants.currentImportCollectionID) as? String else { return }
        if let importManager = ImportManager.restoreImport(withImportCollectionID: importID, destinationProvider: AppleMusicService()) {
            
            let alertController = UIAlertController(title: NSLocalizedString("Shall we continue?", comment: ""), message: String.localizedStringWithFormat("I found a pending import for playlist \"%@\". Do you want to continue?", importManager.importInfo.currentImport.playlist.name), preferredStyle: .alert)
            let okAction = UIAlertAction(title: NSLocalizedString("Yes, please", comment: ""), style: .default) { (action) in
                DispatchQueue.main.async {
                    self.showImport(with: importManager)
                }
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("Nope", comment: ""), style: .default) { (action) in
                Helper.set(nil, forKey: Constants.currentImportCollectionID)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self.navigationController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showImport(with importManager: ImportManager) {
        
        let importCoordinator = ImportCoordinator(importManager: importManager, navigationController: self.navigationController, delegate: self)
        importCoordinator.start()
        
        self.childCoordinators.append(importCoordinator)
    }
    
    func showAbout() {
        
        let navigationController = BaseNavigationController()
        let aboutCoordinator = AboutCoordinator(navigationController: navigationController, delegate: self)
        aboutCoordinator.start()
        
        self.navigationController.present(navigationController, animated: true)
        
        self.childCoordinators.append(aboutCoordinator)
    }
    
    func showServiceAuthentication(selectedService: Service? = nil) {
        
        self.navigationController.viewControllers.last?.title = ""
        
        let serviceAuthenticationCoordinator = ServiceAuthenticationCoordinator(navigationController: self.navigationController, delegate: self, selectedService: selectedService)
        serviceAuthenticationCoordinator.start()
        
        self.childCoordinators.append(serviceAuthenticationCoordinator)
    }
    
    func showPlaylistRefresh() {
        
        self.navigationController.viewControllers.last?.title = ""
        
        let playlistRefreshCoordinator = PlaylistRefreshCoordinator(navigationController: self.navigationController, delegate: self)
        playlistRefreshCoordinator.start()
        
        self.childCoordinators.append(playlistRefreshCoordinator)
    }
    
    func showSelectionCoordinator(sourceService: SourceServiceProviding) {
        
        let selectionCoordinator = SelectionCoordinator(sourceService: sourceService, navigationController: self.navigationController, delegate: self)
        selectionCoordinator.start()
        
        self.childCoordinators.append(selectionCoordinator)
    }
    
    func showImport(with selections: [PlaylistSelection]) {
        
        let importCoordinator = ImportCoordinator(playlistSelections: selections, navigationController: self.navigationController, delegate: self)
        importCoordinator.start()
        
        self.childCoordinators.append(importCoordinator)
    }
    
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool {
        
        for coordinator in self.childCoordinators.reversed() {
            let result = coordinator.coordinatorDidAskForRestart(coordinator)
            if result {
                return true
            } else {
                guard let index = self.childCoordinators.index(where: { $0 === coordinator }) else { continue }
                self.childCoordinators.remove(at: index)
            }
        }
        
        guard let viewController = self.firstViewController else { return false }
        self.navigationController.popToViewController(viewController, animated: true)
        return true
    }
}

// MARK: - Base View Controller Delegate

extension HomeCoordinator: BaseViewControllerDelegate {
    
    func viewControllerDidExit(_ viewController: BaseViewController) {
        if viewController is WelcomeViewController {
            self.delegate?.coordinatorDidExit(self)
        }
    }
}

// MARK: - Welcome View Controller Delegate

extension HomeCoordinator: WelcomeViewControllerDelegate {
    
    func viewDidAppear(on welcomeViewController: WelcomeViewController) {
        self.checkForPendingImport()
    }
    
    func didTapAbout(on welcomeViewController: WelcomeViewController) {
        self.showAbout()
    }
    
    func didTapStart(on welcomeViewController: WelcomeViewController) {
        self.showServiceAuthentication()
    }
    
    func didTapRefresh(on welcomeViewController: WelcomeViewController) {
        self.showPlaylistRefresh()
    }
}

// MARK: - Playlist Refresh Coordinator Delegate

extension HomeCoordinator: PlaylistRefreshCoordinatorDelegate {
    
    func didTapImportNewPlaylist(sourceService: SourceServiceProviding?, on refreshCoordinator: PlaylistRefreshCoordinator) {
        
        self.navigationController.popViewController(animated: true)
        if let sourceService = sourceService {
            self.showSelectionCoordinator(sourceService: sourceService)
        } else {
            self.showServiceAuthentication()
        }
    }
}

// MARK: - Service Authentication Coordinator Delegate

extension HomeCoordinator: ServiceAuthenticationCoordinatorDelegate {
    
    func didAuthenticate(sourceService: SourceServiceProviding, on authenticationCoordinator: ServiceAuthenticationCoordinator) {
        self.showSelectionCoordinator(sourceService: sourceService)
    }
}

// MARK: - Selection Coordinator Delegate

extension HomeCoordinator: SelectionCoordinatorDelegate {
    
    func didSelect(_ selections: [PlaylistSelection], on selectionCoordinator: SelectionCoordinator) {
        self.showImport(with: selections)
    }
}
