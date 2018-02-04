//
//  ServiceAuthenticationViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol ServiceAuthenticationViewControllerDelegate: class {
    func didTapLogoutSpotify(on serviceAuthenticationViewController: ServiceAuthenticationViewController)
    func didTapSpotify(on serviceAuthenticationViewController: ServiceAuthenticationViewController)
}

class ServiceAuthenticationViewController: BaseViewController {
    
    @IBOutlet var userInfoView: UIView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var goButton: JMButton!
    
    weak var delegate: ServiceAuthenticationViewControllerDelegate?
    var loggedUsername: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
    }
    
    func updateUI() {
        
        var newAlpha = 0 as CGFloat
        if let loggedUsername = self.loggedUsername {
            self.usernameLabel.text = loggedUsername
            self.goButton.setTitle(NSLocalizedString("CONTINUE", comment: ""), for: .normal)
            
            self.userInfoView.alpha = 0
            self.userInfoView.isHidden = false
            newAlpha = 1
        } else {
            self.goButton.setTitle(NSLocalizedString("CONNECT", comment: ""), for: .normal)
            newAlpha = 0
        }
        
        UIView.animate(withDuration: 0.25) {
            self.userInfoView.alpha = newAlpha
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        self.loggedUsername = nil
        self.updateUI()
        self.delegate?.didTapLogoutSpotify(on: self)
    }
    
    @IBAction func connectSpotity(_ sender: Any?) {
        self.delegate?.didTapSpotify(on: self)
    }
}
