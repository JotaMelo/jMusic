//
//  ServiceAuthenticationCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol ServiceAuthenticationCoordinatorDelegate: CoordinatorDelegate {
    func didAuthenticate(sourceService: SourceServiceProviding, on authenticationCoordinator: ServiceAuthenticationCoordinator)
}

class ServiceAuthenticationCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    fileprivate var firstViewController: UIViewController?
    fileprivate var sourceService: SourceServiceProviding?
    
    required init(navigationController: UINavigationController, delegate: ServiceAuthenticationCoordinatorDelegate?, selectedService: Service? = nil) {
        
        self.navigationController = navigationController
        self.delegate = delegate
        
        if let selectedService = selectedService {
            switch selectedService {
            case .spotify:
                self.sourceService = SpotifyService()
            default:
                break
            }
        }
    }
    
    func start() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleURLNotification(_:)), name: .jMusicOpenURL, object: nil)
        
        if self.sourceService != nil {
            self.authenticate()
            return
        }
        
        let serviceAuthenticationViewController = ServiceAuthenticationViewController.initFromStoryboard(named: "Main")
        serviceAuthenticationViewController.loggedUsername = SpotifyService().username
        serviceAuthenticationViewController.baseDelegate = self
        serviceAuthenticationViewController.delegate = self
        self.navigationController.pushViewController(serviceAuthenticationViewController, animated: true)
        
        self.firstViewController = serviceAuthenticationViewController
    }
    
    @objc func handleURLNotification(_ notification: Notification) {
        
        if let url = notification.userInfo?["URL"] as? URL {
            self.sourceService?.finishAuthenticationWithURL(url)
        }
     }
    
    func authenticate() {
        
        let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
        hud.label.text = NSLocalizedString("Authenticating...", comment: "")
        
        self.sourceService?.startAuthentication { [unowned self] (success, error) in
            hud.hide(animated: true)
            
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                
                self.navigationController.present(alertController, animated: true, completion: nil)
            } else if let delegate = self.delegate as? ServiceAuthenticationCoordinatorDelegate, let sourceService = self.sourceService, success {
                let okAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { action in
                    if let firstViewController = self.firstViewController as? ServiceAuthenticationViewController {
                        firstViewController.loggedUsername = sourceService.username
                        firstViewController.updateUI()
                    }
                    
                    sourceService.persistAuthentication()
                    delegate.didAuthenticate(sourceService: sourceService, on: self)
                })
                let cancelAction = UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .cancel, handler: { action in
                    delegate.didAuthenticate(sourceService: sourceService, on: self)
                })
                let alert = UIAlertController(title: NSLocalizedString("Save your login", comment: ""), message: NSLocalizedString("Do you allow jMusic to save your Spotify credentials so you won't have to login every time?", comment: ""), preferredStyle: .alert)
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.navigationController.present(alert, animated: true, completion: nil)
            } else {
                self.sourceService = nil
            }
        }
    }
    
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool {
        
        guard let viewController = self.firstViewController else { return false }
        self.navigationController.popToViewController(viewController, animated: true)
        return true
    }
}

extension ServiceAuthenticationCoordinator: BaseViewControllerDelegate {
    
    func viewControllerDidExit(_ viewController: BaseViewController) {
        if viewController is ServiceAuthenticationViewController {
            self.delegate?.coordinatorDidExit(self)
        }
    }
}

extension ServiceAuthenticationCoordinator: ServiceAuthenticationViewControllerDelegate {
    
    func didTapLogoutSpotify(on serviceAuthenticationViewController: ServiceAuthenticationViewController) {
        SpotifyService().logout()
    }
    
    func didTapSpotify(on serviceAuthenticationViewController: ServiceAuthenticationViewController) {
        
        let service = SpotifyService()
        self.sourceService = service
        if let delegate = self.delegate as? ServiceAuthenticationCoordinatorDelegate, service.authenticated {
            delegate.didAuthenticate(sourceService: service, on: self)
        } else {
            
            
            self.authenticate()
        }
    }
}
