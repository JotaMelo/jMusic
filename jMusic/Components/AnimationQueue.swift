//
//  AnimationQueue.swift
//  jMusic
//
//  Created by Jota Melo on 21/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

// It's called animation queue but really it can be used for any kind of task.
typealias AnimationQueueItem = (@escaping () -> Void) -> Void
class AnimationsQueue {
    
    var items: [AnimationQueueItem] = []
    var lastQueuedIndex: Int = 0
    
    func add(item: @escaping AnimationQueueItem) {
        
        self.items.append(item)
        if items.count == 1 {
            self.next()
        }
    }
    
    func next() {
        
        if self.items.count == 0 {
            return
        }
        
        let firstItem = self.items.removeFirst()
        firstItem() {
            self.next()
        }
    }
}
