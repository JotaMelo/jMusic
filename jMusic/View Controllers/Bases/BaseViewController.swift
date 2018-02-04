//
//  BaseViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

protocol BaseViewControllerDelegate: class {
    func viewControllerDidExit(_ viewController: BaseViewController)
}

class BaseViewController: UIViewController {
    
    weak var baseDelegate: BaseViewControllerDelegate?
    
    var navigationBarBackgroundColor = Colors.defaultNavigationBarBackgroundColor
    
    var shouldPerformCustomTransition = false {
        didSet {
            let navigationController = self.navigationController as? BaseNavigationController
            navigationController?.navigationControllerDelegate.shouldPerformCustomTransition = shouldPerformCustomTransition
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    static func initFromStoryboard(named storyboardName: String) -> Self {
        return initFromStoryboardHelper(storyboardName: storyboardName)
    }
    
    private class func initFromStoryboardHelper<T>(storyboardName: String) -> T {
        let storyoard = UIStoryboard(name: storyboardName, bundle: nil)
        let className = String(describing: self)
        let viewController = storyoard.instantiateViewController(withIdentifier: className) as! T
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.navigationController == nil {
            self.baseDelegate?.viewControllerDidExit(self)
        }
    }
}
