//
//  CheckupViewController.swift
//  jMusic
//
//  Created by Jota Melo on 08/05/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class CheckupViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = Colors.defaultNavigationBarBackgroundColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissVC))
    }
    
    @objc func dismissVC() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openMusicSettings(_ sender: Any) {
//        UIApplication.shared.openURL(URL(string: "App-Prefs:root=MUSIC")!)
    }
    
    @IBAction func openAppSettings(_ sender: Any) {
//        UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
    }
    
    @IBAction func openEmail(_ sender: Any) {
//        UIApplication.shared.openURL(URL(string: "mailto:jpmfagundes+jMusic@gmail.com")!)
    }
}
