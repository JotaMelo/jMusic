//
//  BaseNavigationController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    var navigationControllerDelegate = NavigationControllerTransitionManager()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let lastViewController = self.viewControllers.last else { return .lightContent }
        return lastViewController.preferredStatusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self.navigationControllerDelegate
    }
}
