//
//  NavigationControllerTransitionManager.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation
import UIKit

class NavigationControllerTransitionManager: NSObject {
    
    var shouldPerformCustomTransition = true
    
    private var navigationController: UINavigationController?
    private var interactionController: UIPercentDrivenInteractiveTransition?
    private var gestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var currentOperation: UINavigationControllerOperation?
    
    override init() {
        super.init()
        
        self.gestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panHandler(_:)))
        self.gestureRecognizer?.edges = [.left]
    }
    
    @objc private func panHandler(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        
        guard let view = gestureRecognizer.view else { return }
        let translatedPoint = gestureRecognizer.translation(in: view)
        let percentage = translatedPoint.x / view.frame.size.width
        
        switch gestureRecognizer.state {
        case .began:
            self.interactionController = UIPercentDrivenInteractiveTransition()
            _ = self.navigationController?.popViewController(animated: true)
            
        case .changed:
            self.interactionController?.update(percentage)
            
        case .ended:
            let velocity = gestureRecognizer.velocity(in: view)
            
            if percentage > 0.5 || velocity.x > 0 {
                self.interactionController?.finish()
            } else {
                self.interactionController?.cancel()
            }
            
            self.interactionController = nil
        default:
            break
        }
    }
    
}

extension NavigationControllerTransitionManager: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        if navigationController.viewControllers.count > 0 && !viewController.navigationItem.hidesBackButton, let gestureRecognizer = self.gestureRecognizer {
            self.navigationController = navigationController
            viewController.view.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if !self.shouldPerformCustomTransition {
            return nil
        }
        
        self.currentOperation = operation
        return self
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactionController
    }
}

extension NavigationControllerTransitionManager: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? BaseViewController,
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? BaseViewController,
        let currentOperation = self.currentOperation else { return }
        
        transitionContext.containerView.addSubview(toViewController.view)
        
        if currentOperation == .push {
            toViewController.view.frame = CGRect(x: toViewController.view.frame.size.width, y: fromViewController.view.frame.origin.y, width: toViewController.view.frame.size.width, height: toViewController.view.frame.size.height)
        } else if currentOperation == .pop {
            toViewController.view.frame = CGRect(x: -toViewController.view.frame.size.width, y: fromViewController.view.frame.origin.y, width: toViewController.view.frame.size.width, height: toViewController.view.frame.size.height)
        } else {
            return
        }
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            toViewController.view.frame = fromViewController.view.frame
            toViewController.navigationController?.navigationBar.barTintColor = toViewController.navigationBarBackgroundColor
            
            if currentOperation == .push {
                fromViewController.view.frame = CGRect(x: -fromViewController.view.frame.size.width, y: fromViewController.view.frame.origin.y, width: toViewController.view.frame.size.width, height: toViewController.view.frame.size.height);
            } else if currentOperation == .pop {
                fromViewController.view.frame = CGRect(x: fromViewController.view.frame.size.width, y: fromViewController.view.frame.origin.y, width: toViewController.view.frame.size.width, height: toViewController.view.frame.size.height);
            }
        }, completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
}
