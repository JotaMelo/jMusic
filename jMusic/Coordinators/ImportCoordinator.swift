//
//  ImportCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import UserNotifications
import MediaPlayer
import MBProgressHUD
import SDWebImage
import StoreKit

enum ImportMode {
    case `default`
    case resume
}

final class ImportCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private var playlistSelections: [PlaylistSelection] = []
    private var mode: ImportMode
    
    private var destinationService: DestinationServiceProviding
    private var importManager: ImportManager?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = 0
    private var noConnectionHUD: MBProgressHUD?
    private var needsPlaylistUIUpdate: Bool = false
    
    private var importViewController: ImportViewController?
    private weak var importOverviewViewController: ImportOverviewViewController?
    private weak var playlistImportOverviewViewController: PlaylistImportOverviewViewController?
    
    init(playlistSelections: [PlaylistSelection], navigationController: UINavigationController, delegate: CoordinatorDelegate?) {
        
        self.mode = .default
        self.playlistSelections = playlistSelections
        self.destinationService = AppleMusicService()
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    init(importManager: ImportManager, navigationController: UINavigationController, delegate: CoordinatorDelegate?) {
        
        self.mode = .resume
        self.importManager = importManager
        self.destinationService = importManager.destinationProvider
        self.navigationController = navigationController
        self.delegate = delegate
    }

    func start() {
        
        self.setupImportManager { importManager in
            if self.mode == .resume {
                self.showImport()
                return
            }
            
            self.importManager = importManager
            if let tracksViewController = self.navigationController.viewControllers.last as? TracksChooserViewController {
                UIView.animate(withDuration: 0.25, animations: {
                    tracksViewController.scrollToTop()
                }, completion: { (finished) in
                    self.showImport()
                })
            } else {
                self.showImport()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    func showCheckup() {
        
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.navigationController.view, animated: true)
            
            let checkupViewController = CheckupViewController.initFromStoryboard(named: "Main")
            let navigationController = BaseNavigationController(rootViewController: checkupViewController)
            self.navigationController.present(navigationController, animated: true, completion: nil)
            
            self.delegate?.coordinatorDidExit(self)
        }
    }
    
    func showAppleMusicSubscription() {
        
        let controller = SKCloudServiceSetupViewController()
        
        var setupOptions: [SKCloudServiceSetupOptionsKey: Any] = [.action: SKCloudServiceSetupAction.subscribe]
        if #available(iOS 11.0, *) {
            setupOptions[.messageIdentifier] = SKCloudServiceSetupMessageIdentifier.addMusic
        }
        
        controller.load(options: setupOptions) { success, error in
            if success {
                self.navigationController.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func showImport() {
        
        let importViewController = ImportViewController.initFromStoryboard(named: "Main")
        importViewController.importInfo = self.importManager?.importInfo
        importViewController.delegate = self
        self.navigationController.pushViewController(importViewController, animated: true)
        
        self.importViewController = importViewController
        
        self.askForNotifications {
            self.startImport()
        }
    }
    
    func showOverview() {
        guard let importManager = self.importManager else { return }
        self.log(importInfo: importManager.importInfo)
        
        if importManager.importInfo.imports.count == 1 {
            self.showOverview(forPlaylistImport: importManager.importInfo.imports[0])
        } else if self.importOverviewViewController == nil {
            let importOverviewViewController = ImportOverviewViewController.initFromStoryboard(named: "Main")
            importOverviewViewController.importInfo = importManager.importInfo
            importOverviewViewController.delegate = self
            self.navigationController.pushViewController(importOverviewViewController, animated: true)
            
            self.importOverviewViewController = importOverviewViewController
        }
    }
    
    func showOverview(forPlaylistImport importInfo: PlaylistImportInfo) {
        guard let importManager = self.importManager else { return }
        
        let importOverviewViewController = PlaylistImportOverviewViewController.initFromStoryboard(named: "Main")
        importOverviewViewController.playlistImportInfo = importInfo
        importOverviewViewController.isLastStep = importManager.importInfo.imports.count == 1
        importOverviewViewController.isImportDone = importManager.importInfo.isFinished
        importOverviewViewController.delegate = self
        self.navigationController.pushViewController(importOverviewViewController, animated: true)
        
        self.playlistImportOverviewViewController = importOverviewViewController
    }
    
    func showSearches(forTrack track: Track, importInfo: PlaylistImportInfo) {
        guard let destinationPlaylist = importInfo.destinationPlaylist else { return }
        
        let searchesCoordinator = SearchesCoordinator(track: track, destinationPlaylist: destinationPlaylist, destinationService: self.destinationService, navigationController: self.navigationController, delegate: self)
        searchesCoordinator.start()
        
        self.childCoordinators.append(searchesCoordinator)
    }
    
    func startImport() {

        self.beginBackgroundTask()
    
        let trackProgressHandler: TrackImportProgressHandler = { [unowned self] track, last, error in
            DispatchQueue.main.async {
                if self.noConnectionHUD != nil {
                    self.noConnectionHUD?.hide(animated: true)
                }
                
                let destinationPlaylist = self.importManager?.importInfo.currentImport.destinationPlaylist
                if let error = error as? MPError, let destinationPlaylist = destinationPlaylist, error.code == .notFound {
                    guard let importManager = self.importManager else { return }
                    
                    let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
                    hud.label.text = NSLocalizedString("There was an issue connecting\nto Apple Music, retrying...", comment: "")
                    hud.label.numberOfLines = 0
                    
                    importManager.destinationProvider.retrieve(playlist: destinationPlaylist, callback: { playlist, error in
                        hud.hide(animated: true)
                        
                        if let error = error {
                            self.showErrorAndExit(error)
                        } else {
                            self.startImport()
                        }
                    })
                } else if let error = error as? ImportError {
                    self.handle(importError: error)
                    return
                }
                
                if !last && track != nil && UIApplication.shared.applicationState == .active {
                    self.importOverviewViewController?.updateUI()
                    self.importViewController?.goNext()
                }
            }
        }
        
        let playlistProgressHandler: PlaylistImportProgressHandler = { [unowned self] playlist, last in
            DispatchQueue.main.async {
                
                if !last {
                    if UIApplication.shared.applicationState != .active {
                        self.needsPlaylistUIUpdate = true
                        return
                    }
                    
                    self.importOverviewViewController?.updateUI()
                    self.importViewController?.showCheckbox { [weak self] in
                        self?.importViewController?.hideCheckbox {
                            self?.importViewController?.updateCurrentPlaylistInfo(animated: true)
                        }
                    }
                } else {
                    if UIApplication.shared.applicationState == .active {
                        self.importOverviewViewController?.updateUI()
                        self.playlistImportOverviewViewController?.animateToImportDone()
                        NotificationCenter.default.removeObserver(self)
                    }
                    
                    Helper.set(nil, forKey: Constants.currentImportCollectionID)
                    Helper.showNotificationWith(body: NSLocalizedString("Your import has finished! Open the app to see it.", comment: ""), alert: true)
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
                    
                    self.importViewController?.showCheckbox { [weak self] in
                        self?.showOverview()
                    }
                }
            }
        }
        
        Helper.set(self.importManager?.persistedImportID, forKey: Constants.currentImportCollectionID)
        self.importManager?.startImport(trackProgressHandler: trackProgressHandler, playlistProgressHandler: playlistProgressHandler)
    }
    
    @objc func appDidBecomeActive() {
        guard let importManager = self.importManager else { return }
        
        if importManager.importInfo.isFinished {
            NotificationCenter.default.removeObserver(self)
            Helper.set(nil, forKey: Constants.currentImportCollectionID)
            self.showOverview()
            self.playlistImportOverviewViewController?.animateToImportDone()
        } else if importManager.isPaused {
            self.startImport()
        }
        
        if self.needsPlaylistUIUpdate {
            self.needsPlaylistUIUpdate = false
            self.importViewController?.updateCurrentPlaylistInfo()
        }
        
        self.importViewController?.updateUI()
        self.importOverviewViewController?.updateUI()
    }
    
    @objc func appDidEnterBackground() {
        guard let importManager = self.importManager else { return }
        
        if !importManager.importInfo.isFinished && !importManager.isPaused {
            Helper.showNotificationWith(body: NSLocalizedString("Your import is still in progress. We'll notify you when it finishes or if something goes terribly wrong.", comment: ""), alert: false)
        }
    }
}

// MARK: - Helpers

extension ImportCoordinator {
    
    func showErrorAndExit(_ error: Error) {
        self.showMessageAndExit(error.localizedDescription)
    }
    
    func showMessageAndExit(_ message: String) {
        
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.navigationController.view, animated: true)
            
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.navigationController.present(alertController, animated: true, completion: nil)
            
            self.delegate?.coordinatorDidExit(self)
        }
    }
    
    func setupImportManager(callback: @escaping (ImportManager) -> Void) {
        
        var urls: [URL] = []
        var tracks: [Track] = self.playlistSelections.reduce([], { $0 + $1.tracks })
        for i in 0..<(tracks.count >= 3 ? 3 : tracks.count) {
            let track = tracks[i]
            if let url = track.albumCoverURL {
                urls.append(url)
            }
        }
        SDWebImagePrefetcher.shared().prefetchURLs(urls)
        
        DispatchQueue.main.async {
            let hud = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
            hud.label.text = NSLocalizedString("Authenticating with Apple Music...", comment: "")
        }
        
        self.destinationService.startAuthenticationWith(handler: { [unowned self] error in
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.navigationController.view, animated: true)
            }
            
            if let error = error {
                if let error = error as? AppleMusicError {
                    if error == .unknown {
                        self.showCheckup()
                    } else if error == .eligibleForSubscription {
                        self.showAppleMusicSubscription()
                    } else {
                        self.showErrorAndExit(error)
                    }
                } else {
                    self.showErrorAndExit(error)
                }
                
                return
            }
            
            if let importManager = self.importManager {
                callback(importManager)
                return
            }
            
            let importManager = ImportManager(playlistSelections: self.playlistSelections, destinationProvider: self.destinationService)
            if let importManager = importManager {
                DispatchQueue.main.async {
                    callback(importManager)
                }
            } else {
                self.showMessageAndExit(NSLocalizedString("Sorry but terrible things happened. Please try again!", comment: ""))
            }
        })
    }
    
    func askForNotifications(callback: (() -> Void)?) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var notificationSettings: UNNotificationSettings!
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            notificationSettings = settings
            semaphore.signal()
        }
        semaphore.wait()
        let isEmpty = notificationSettings.authorizationStatus == .notDetermined &&
                      notificationSettings.soundSetting != .enabled &&
                      notificationSettings.badgeSetting != .enabled &&
                      notificationSettings.alertSetting != .enabled
        
        if isEmpty && Helper.defaultsObject(forKey: Constants.userAcceptedFirstNotificationDialogDefaultsKey) == nil {
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: NSLocalizedString("Let us send you notifications", comment: ""), message: NSLocalizedString("These are just to inform you if the import finished after you closed the app, or if something wrong happened and you need to open the app to continue. I promise.", comment: ""), preferredStyle: .alert)
                let okAction = UIAlertAction(title: NSLocalizedString("Sure!", comment: ""), style: .default, handler: { _ in
                    Helper.set(true, forKey: Constants.userAcceptedFirstNotificationDialogDefaultsKey)
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { _, _ in
                    })
                    callback?()
                })
                let nopeAction = UIAlertAction(title: NSLocalizedString("Nope", comment: ""), style: .cancel, handler: { _ in
                    callback?()
                })
                
                alertController.addAction(okAction)
                alertController.addAction(nopeAction)
                
                self.navigationController.present(alertController, animated: true, completion: nil)
            }
        } else {
            callback?()
        }
    }
    
    func beginBackgroundTask() {
        
        UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.importManager?.pause()
            Helper.showNotificationWith(body: NSLocalizedString("Bad iOS, no donuts for you! Reopen the app to continue the import.", comment: ""), alert: true)
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
        })
    }
    
    func handle(importError: ImportError) {
        
        var errorMessage: String?
        
        switch importError {
        case .noConnection:
            self.noConnectionHUD = MBProgressHUD.showAdded(to: self.navigationController.view, animated: true)
            self.noConnectionHUD?.label.text = NSLocalizedString("Where did the internet go?\nWaiting for it to come back...", comment: "")
            self.noConnectionHUD?.label.numberOfLines = 0
        case .token, .storefrontFailed:
            errorMessage = NSLocalizedString("There was a problem authenticating with the Apple Music API. Would you like to try again?", comment: "")
        case .playlistCreation(let originalError):
            errorMessage = NSLocalizedString("There was an error creating the playlist:\n\(originalError.localizedDescription)", comment: "")
        }
        
        if let errorMessage = errorMessage {
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Sure let's try again", comment: ""), style: .default, handler: { _ in
                self.importManager?.resume()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Nah", comment: ""), style: .cancel, handler: { _ in
                self.delegate?.coordinatorDidAskForRestart(self)
            }))
            self.navigationController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func log(importInfo: ImportInfo) {
        
//        if let startTime = importInfo.imports.first?.startTime, let endTime = importInfo.imports.last?.endTime {
//            let total = importInfo.imports.reduce(0, { $0 + $1.tracks.count })
//            let totalWithError = importInfo.imports.reduce(0, { $0 + $1.unsuccessfulTracks.count })
//            let numberOfInterruptions = importInfo.imports.reduce(0, { $0 + $1.numberOfInterruptions })
//            Answers.logCustomEvent(withName: "Import finished",
//                                   customAttributes: ["total": total,
//                                                      "totalWithError": totalWithError,
//                                                      "numberOfInterruptions": numberOfInterruptions,
//                                                      "secondsElapsed": endTime.timeIntervalSince(startTime),
//                                                      "playlists": importInfo.imports.count])
//        }
    }
}

// MARK: - Import View Controller delegate

extension ImportCoordinator: ImportViewControllerDelegate {
    
    func didTapProgressButton(on viewController: ImportViewController) {
        self.showOverview()
    }
}

// MARK: - Import Overview View Controller delegate

extension ImportCoordinator: ImportOverviewViewControllerDelegate {
    
    func didSelect(playlistImportInfo: PlaylistImportInfo, on viewController: ImportOverviewViewController) {
        guard playlistImportInfo.isFinished else { return }
        
        self.showOverview(forPlaylistImport: playlistImportInfo)
    }
    
    func didTapRestart(on viewController: ImportOverviewViewController) {
        self.delegate?.coordinatorDidAskForRestart(self)
    }
}

// MARK: - Playlist Import Overview View Controller delegate

extension ImportCoordinator: PlaylistImportOverviewViewControllerDelegate {
    
    func didTapRestart(on importOverviewViewController: PlaylistImportOverviewViewController) {
        self.delegate?.coordinatorDidAskForRestart(self)
    }
    
    func didSelect(track: Track, on importOverviewViewController: PlaylistImportOverviewViewController) {
        
        if track.status == .error, let error = track.errorDescription {
            let errorMessage = String.localizedStringWithFormat("There was an error while matching this track:\n%@", error)
            
            let alert = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: errorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self.navigationController.present(alert, animated: true, completion: nil)
        } else if track.status == .notFound || track.status == .found {
            self.showSearches(forTrack: track, importInfo: importOverviewViewController.playlistImportInfo)
        }
    }
}
