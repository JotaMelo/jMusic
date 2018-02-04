//
//  AppCoordinator.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation
import UIKit

protocol CoordinatorDelegate: class {
    @discardableResult
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool
    func coordinatorDidExit(_ coordinator: Coordinator)
}

protocol Coordinator: CoordinatorDelegate {
    var delegate: CoordinatorDelegate? { get }
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

extension Coordinator {
    
    func coordinatorDidExit(_ coordinator: Coordinator) {
        
        if coordinator === self.childCoordinators.last {
            self.delegate?.coordinatorDidExit(self)
        }
        
        guard let index = self.childCoordinators.index(where: { $0 === coordinator }) else { return }
        self.childCoordinators.remove(at: index)
    }
    
    // returning true means an action was performed
    func coordinatorDidAskForRestart(_ coordinator: Coordinator) -> Bool {
        return false
    }
}

class AppCoordinator: Coordinator {
    
    weak var delegate: CoordinatorDelegate?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    required init(navigationController: UINavigationController, delegate: CoordinatorDelegate?) {
        
        self.navigationController = navigationController
        self.delegate = delegate
    }
    
    func start() {
        
        let homeCoordinator = HomeCoordinator(navigationController: self.navigationController, delegate: self)
        homeCoordinator.start()
        
        self.childCoordinators.append(homeCoordinator)
    }
}
