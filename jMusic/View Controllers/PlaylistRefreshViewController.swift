//
//  PlaylistRefreshViewController.swift
//  jMusic
//
//  Created by Jota Melo on 18/02/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol PlaylistRefreshViewControllerDelegate: class {
    func persistedImports(on playlistRefreshViewController: PlaylistRefreshViewController) -> [Import]
    func didRemove(import: Import, on playlistRefreshViewController: PlaylistRefreshViewController)
    func didSelect(imports: [Import], on playlistRefreshViewController: PlaylistRefreshViewController)
}

class PlaylistRefreshViewController: BaseViewController {
    
    @IBOutlet var tableView: UITableView!
    
    weak var delegate: PlaylistRefreshViewControllerDelegate?
    var imports: [Import] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Playlist Refresher", comment: "")
        self.tableView.estimatedRowHeight = 80
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.clearTableSelection()
        
        // always keep it updated
        if let delegate = self.delegate {
            self.imports = delegate.persistedImports(on: self)
            self.tableView.reloadData()
        }
    }
    
    func clearTableSelection() {
        
        if let selectedIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    func scrollToTop() {
        self.tableView.contentOffset = CGPoint.zero
    }
    
    @IBAction func go(_ sender: Any) {
        
        if let indexPaths = self.tableView.indexPathsForSelectedRows, indexPaths.count > 0 {
            let imports = indexPaths.map { self.imports[$0.row] }
            self.delegate?.didSelect(imports: imports, on: self)
        } else {
            let alertController = UIAlertController(title: NSLocalizedString("Oh no :(", comment: ""), message: NSLocalizedString("You need to select at least 1 playlist to refresh.", comment: ""), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK - Table View delegate / data source

extension PlaylistRefreshViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.imports.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImportCell", for: indexPath) as! ImportCell
        cell.playlistImport = self.imports[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            self.delegate?.didRemove(import: self.imports[indexPath.row], on: self)
            self.imports.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
