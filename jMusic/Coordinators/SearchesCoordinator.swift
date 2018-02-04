//
//  SearchesCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import CloudKit

final class SearchesCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    var track: Track
    var destinationPlaylist: Playlist
    var destinationService: DestinationServiceProviding
    
    required init(track: Track, destinationPlaylist: Playlist, destinationService: DestinationServiceProviding, navigationController: UINavigationController, delegate: CoordinatorDelegate?) {
        
        self.track = track
        self.destinationPlaylist = destinationPlaylist
        self.destinationService = destinationService
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    func start() {
        self.showSearches()
    }
    
    func showSearches() {
        
        let searchesViewController = TrackSearchesViewController.initFromStoryboard(named: "Main")
        searchesViewController.track = self.track
        searchesViewController.delegate = self
        
        self.navigationController.pushViewController(searchesViewController, animated: true)
    }
    
    func showResultsFor(search: Search) {
        
        let searchResultsViewController = TrackSearchResultsViewController.initFromStoryboard(named: "Main")
        searchResultsViewController.track = self.track
        searchResultsViewController.search = search
        searchResultsViewController.delegate = self
        
        self.navigationController.pushViewController(searchResultsViewController, animated: true)
    }
}

// MARK: - Track Searches View Controller delegate

extension SearchesCoordinator: TrackSearchesViewControllerDelegate {
    
    func didSelect(search: Search, on trackSearchesViewController: TrackSearchesViewController) {
        self.showResultsFor(search: search)
    }
}

// MARK: - Track Search Results View Controller delegate

extension SearchesCoordinator: TrackSearchResultsViewControllerDelegate {
    
    func didReportCorrectSearchResult(_ searchResult: SearchResult, forTrack track: Track, on trackSearchResultsViewController: TrackSearchResultsViewController) {
        
        let errorReportRecordID = CKRecordID(recordName: UUID().uuidString)
        let errorReportRecord = CKRecord(recordType: Constants.cloudKitErrorReportRecordType, recordID: errorReportRecordID)
        errorReportRecord["sourceService"] = track.service.rawValue as NSString
        errorReportRecord["destinationService"] = searchResult.service.rawValue as NSString
        
        errorReportRecord["sourceTrackID"] = track.id as NSString
        errorReportRecord["sourceTrackName"] = track.name as NSString
        errorReportRecord["sourceArtist"] = track.artist as NSString
        errorReportRecord["sourceAlbum"] = track.album as NSString
        errorReportRecord["sourceAlbumCoverURL"] = track.albumCoverURL?.absoluteString as NSString?
        errorReportRecord["sourceTrackDuration"] = NSNumber(value: track.duration)
        
        errorReportRecord["destinationTrackID"] = searchResult.trackID as NSString
        errorReportRecord["destinationTrackName"] = searchResult.trackName as NSString
        errorReportRecord["destinationArtist"] = searchResult.artist as NSString
        errorReportRecord["destinationAlbum"] = searchResult.album as NSString
        errorReportRecord["destinationAlbumCoverURL"] = searchResult.albumCoverURL?.absoluteString as NSString?
        errorReportRecord["destinationTrackDuration"] = NSNumber(value: searchResult.duration)
        
        errorReportRecord["regionIdentifier"] = self.destinationService.regionIdentifier as NSString
        errorReportRecord["query"] = trackSearchResultsViewController.search.query as NSString
        errorReportRecord["date"] = NSDate()
        
        CKContainer.default().publicCloudDatabase.save(errorReportRecord) { (record, error) in
            NSLog("Saved error report in CloudKit")
        }
    }
    
    func didTapAddSearchResult(_ searchResult: SearchResult, on trackSearchResultsViewController: TrackSearchResultsViewController) {
        self.destinationService.addTrack(fromSearchResult: searchResult, toPlaylist: self.destinationPlaylist, callback: nil)
    }
}
