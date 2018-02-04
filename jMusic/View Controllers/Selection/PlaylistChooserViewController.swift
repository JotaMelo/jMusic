//
//  PlaylistChooserViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import UIScrollView_InfiniteScroll

protocol PlaylistChooserViewControllerDelegate: class {
    func didSelect(playlists: [Playlist], on playlistChooserViewController: PlaylistChooserViewController)
    func didEnterPlaylistURL(_ playlistURL: URL, on playlistChooserViewController: PlaylistChooserViewController)
}

class PlaylistChooserViewController: BaseViewController {

    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet var myPlaylistsButton: UIButton!
    @IBOutlet var playlistURLButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var emptyPlaceholderLabel: UILabel!
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var playlistURLView: UIView!
    @IBOutlet var playlistURLTextField: UITextField!
    @IBOutlet var playlistURLViewHeightConstraint: NSLayoutConstraint!

    weak var delegate: PlaylistChooserViewControllerDelegate?

    var sourceService: SourceServiceProviding?
    var currentPage: PlaylistPaging? {
        didSet {
            if let page = currentPage, self.playlists.count == 0 {
                self.playlists = page.items
            }
        }
    }

    private var pasteboardString: String?
    private var playlists: [Playlist] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pasteboardString = UIPasteboard.general.string
        
        if self.playlists.count == 0 {
            self.emptyPlaceholderLabel.isHidden = false
            NSLayoutConstraint.deactivate([self.tableViewHeightConstraint])
            self.showPlaylistURL(nil)
        } else {
            self.updateTableViewHeight()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for indexPath in self.tableView.indexPathsForSelectedRows ?? [] {
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.scrollView.addInfiniteScroll { [weak self] (scrollView) in
            guard let strongSelf = self else { return }
            
            guard let currentPage = strongSelf.currentPage else {
                scrollView.finishInfiniteScroll()
                return
            }
            
            if !currentPage.hasNextPage {
                scrollView.finishInfiniteScroll()
                return
            }
            
            currentPage.loadNextPage { newPage, error in
                scrollView.finishInfiniteScroll()
                
                if let newPage = newPage, error == nil {
                    let previousPlaylistsCount = strongSelf.playlists.count
                    strongSelf.currentPage = newPage
                    strongSelf.playlists.append(contentsOf: newPage.items)
                    
                    var indexPathsToInsert: [IndexPath] = []
                    for i in previousPlaylistsCount..<strongSelf.playlists.count {
                        let indexPath = IndexPath(row: i, section: 0)
                        indexPathsToInsert.append(indexPath)
                    }
                    
                    strongSelf.updateTableViewHeight()
                    strongSelf.tableView.insertRows(at: indexPathsToInsert, with: .automatic)
                }
            }
        }
    }
    
    func updateTableViewHeight() {
        
        self.tableViewHeightConstraint.constant = CGFloat(self.playlists.count * Constants.tableCellHeight)
        self.view.layoutIfNeeded()
    }
    
    func scrollToTop() {
        self.scrollView.contentOffset = CGPoint.zero
    }

    // MARK - UI Actions
    
    @IBAction func showPlaylists(_ sender: Any?) {
        
        self.scrollView.finishInfiniteScroll()
        
        NSLayoutConstraint.activate([self.tableViewBottomConstraint])
        
        UIView.animate(withDuration: 0.25) {
            self.myPlaylistsButton.backgroundColor = Colors.segmentedControlSelectedColor
            self.myPlaylistsButton.setTitleColor(Colors.segmentedControlDeselectedColor, for: .normal)
            
            self.playlistURLButton.backgroundColor = Colors.segmentedControlDeselectedColor
            self.playlistURLButton.setTitleColor(Colors.segmentedControlSelectedColor, for: .normal)
            
            self.playlistURLView.alpha = 0
            self.tableView.alpha = 1
            self.emptyPlaceholderLabel.alpha = 1
            
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func showPlaylistURL(_ sender: Any?) {
        
        let textFieldText = self.playlistURLTextField.text ?? ""
        if let pasteboardString = self.pasteboardString, textFieldText.isEmpty {
            let parsedURL = self.sourceService?.parsePlaylistURL(pasteboardString)
            if parsedURL != nil {
                self.playlistURLTextField.text = pasteboardString
            }
        }
        
        self.scrollView.finishInfiniteScroll()
        
        NSLayoutConstraint.deactivate([self.tableViewBottomConstraint])
        
        UIView.animate(withDuration: 0.25) {
            self.playlistURLButton.backgroundColor = Colors.segmentedControlSelectedColor
            self.playlistURLButton.setTitleColor(Colors.segmentedControlDeselectedColor, for: .normal)
            
            self.myPlaylistsButton.backgroundColor = Colors.segmentedControlDeselectedColor
            self.myPlaylistsButton.setTitleColor(Colors.segmentedControlSelectedColor, for: .normal)
            
            self.tableView.alpha = 0
            self.emptyPlaceholderLabel.alpha = 0
            self.playlistURLView.alpha = 1
            
            self.view.layoutIfNeeded()
        }
    }
    
    func parsePlaylistURL() {
        
        let playlistURL = self.sourceService?.parsePlaylistURL(self.playlistURLTextField.text ?? "")
        if let playlistURL = playlistURL {
            self.delegate?.didEnterPlaylistURL(playlistURL, on: self)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: NSLocalizedString("That doesn't look like a valid playlist URL.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func go(_ sender: Any) {
        
        if !self.tableViewBottomConstraint.isActive {
            self.parsePlaylistURL()
        } else {
            let indexPaths = self.tableView.indexPathsForSelectedRows ?? []
            if indexPaths.count == 0 {
                let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: NSLocalizedString("You need to select at least 1 playlist.", comment: ""), preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            let playlists = indexPaths.map { self.playlists[$0.row] }
            self.delegate?.didSelect(playlists: playlists, on: self)
        }
    }
}

// MARK: - Table View data source / delegate

extension PlaylistChooserViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCell
        cell.playlist = self.playlists[indexPath.row]
        cell.isLastCell = cell.playlist!.id == self.playlists.last!.id
        
        return cell
    }
}

// MARK: - Text Field delegate

extension PlaylistChooserViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        self.parsePlaylistURL()

        return true
    }
}
