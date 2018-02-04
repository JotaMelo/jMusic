//
//  WelcomeViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol WelcomeViewControllerDelegate: class {
    func viewDidAppear(on welcomeViewController: WelcomeViewController)
    func didTapAbout(on welcomeViewController: WelcomeViewController)
    func didTapStart(on welcomeViewController: WelcomeViewController)
    func didTapRefresh(on welcomeViewController: WelcomeViewController)
}

class WelcomeViewController: BaseViewController {
    
    var delegate: WelcomeViewControllerDelegate?

    @IBOutlet var playlistRefresherButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Colors.defaultNavigationBarBackgroundColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("About", comment: ""), style: .done, target: self, action: #selector(aboutTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.title = "jMusic"
        self.playlistRefresherButton.isHidden = ImportManager.persistedImports().count == 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.delegate?.viewDidAppear(on: self)
    }
    
    @objc func aboutTapped() {
        self.delegate?.didTapAbout(on: self)
    }

    @IBAction func start(_ sender: Any) {
        self.delegate?.didTapStart(on: self)
    }
    
    @IBAction func refresh(_ sender: Any) {
        self.delegate?.didTapRefresh(on: self)
    }
}
