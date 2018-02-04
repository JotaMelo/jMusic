//
//  ImportOverviewViewController.swift
//  jMusic
//
//  Created by Jota Melo on 1/13/18.
//  Copyright © 2018 Jota. All rights reserved.
//

import UIKit
import iRate

protocol ImportOverviewViewControllerDelegate: class {
    func didSelect(playlistImportInfo: PlaylistImportInfo, on viewController: ImportOverviewViewController)
    func didTapRestart(on viewController: ImportOverviewViewController)
}

class ImportOverviewViewController: BaseViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var leftLineView: UIView!
    @IBOutlet var middleBallView: JMView!
    @IBOutlet var rightLineView: UIView!
    @IBOutlet var progressButton: UIButton!
    @IBOutlet var whiteGradientImageView: UIImageView!
    @IBOutlet var startOverButton: JMButton!
    @IBOutlet var tableViewBottomToButtonConstraint: NSLayoutConstraint!
    
    weak var delegate: ImportOverviewViewControllerDelegate?
    weak var importInfo: ImportInfo!
    private var previousPlaylistIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.importInfo.isFinished {
            self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
        } else {
            self.startOverButton.alpha = 0
            self.whiteGradientImageView.alpha = 0
            NSLayoutConstraint.deactivate([self.tableViewBottomToButtonConstraint])
        }
        
        self.updateUI()
    }
    
    func updateUI() {
        guard self.tableView != nil else { return }
        
        if self.importInfo.isFinished {
            iRate.sharedInstance().logEvent(false)
            
            self.navigationItem.hidesBackButton = true
            self.title = NSLocalizedString("All Done", comment: "")
            self.progressButton.setTitle(NSLocalizedString("ALL DONE", comment: ""), for: .normal)
            
            // no turning back now
            for gestureRecognizer in self.view.gestureRecognizers ?? [] {
                if let gestureRecognizer = gestureRecognizer as? UIScreenEdgePanGestureRecognizer, gestureRecognizer.edges == .left {
                    self.view.removeGestureRecognizer(gestureRecognizer)
                    break
                }
            }
            
            NSLayoutConstraint.activate([self.tableViewBottomToButtonConstraint])
            UIView.animate(withDuration: 0.25, animations: {
                let lineDoneColor = Colors.doneNavigationBarBackgroundColor.withAlphaComponent(0.52).cgColor
                self.leftLineView.layer.backgroundColor = lineDoneColor
                self.rightLineView.layer.backgroundColor = lineDoneColor
                self.middleBallView.layer.backgroundColor = Colors.doneNavigationBarBackgroundColor.cgColor
                
                self.navigationBarBackgroundColor = Colors.doneNavigationBarBackgroundColor
                self.navigationController?.navigationBar.barTintColor = Colors.doneNavigationBarBackgroundColor
                self.navigationController?.navigationBar.layoutIfNeeded()
                
                self.startOverButton.alpha = 1
                self.whiteGradientImageView.alpha = 1
                self.view.layoutIfNeeded()
            })
        } else if self.importInfo.totalProcessed != self.previousPlaylistIndex {
            self.navigationBarBackgroundColor = Colors.inProgressNavigationBarBackgrondColor
            self.previousPlaylistIndex = self.importInfo.totalProcessed
            let text = "IMPORTING PLAYLIST \(self.importInfo.totalProcessed + 1) OF \(self.importInfo.imports.count)"
            self.progressButton.setTitle(text, for: .normal)
        }
        
        self.tableView.reloadData()
    }
    
    @IBAction func restart(_ sender: Any) {
        self.delegate?.didTapRestart(on: self)
    }
}

// MARK: - Table View data source / delegate

extension ImportOverviewViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.importInfo.imports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistImportCell", for: indexPath) as! PlaylistImportCell
        cell.isCurrentImport = self.importInfo.totalProcessed == indexPath.row
        cell.importInfo = self.importInfo.imports[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(playlistImportInfo: self.importInfo.imports[indexPath.row], on: self)
    }
}
