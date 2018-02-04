//
//  TestViewController.swift
//  jMusic
//
//  Created by Jota Melo on 11/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    var viewController: AlbumCoversViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        let aa = ["https://i.scdn.co/image/01cecf7ec880727d7848afed2568414eede35f25", "https://i.scdn.co/image/f6d95ce96ce62a59917f1722e8446faeb79beb2a", "https://i.scdn.co/image/4c8f3b81559a20bd0656811b9a118c88be049726", "https://i.scdn.co/image/1b86be975370a788dd56d67ef38d42011a890e67", "https://i.scdn.co/image/ea1a113595f53a9221fe63363bf3dfca72ac364a", "https://i.scdn.co/image/b7f0c2a7483bf7e72a40e5669d6089f317930dbd", "https://i.scdn.co/image/40a1a165b4b5d8076979a8f1fdc4a6414a73c69b", "https://i.scdn.co/image/e66a363d55a75ab182b020b1643b6c1f7fe49fb8", "https://i.scdn.co/image/b32291de8500496a27717fa05a8e7137a0149c3d", "https://i.scdn.co/image/fd11eeaa4a6c3031b68d4dfa1fa7b0e8264c592d", "https://i.scdn.co/image/4e86c9150ebcc1594cf69bee950ac485fba32bdd", "https://i.scdn.co/image/a6d92cc77e4363e8cd5c26c8897484059b3015af", "https://i.scdn.co/image/e82dfdc5c3d0bb32c9e8a54522659af03824b5e9", "https://i.scdn.co/image/ae0efd2a1efbc21b95816cb7fbfb44a32c7251fd", "https://i.scdn.co/image/ddc9f794830a320187c3e26f2db054ef032dcd00", "https://i.scdn.co/image/c0dd8c9e73867b3c73b990b998d56e6bb5c5012a", "https://i.scdn.co/image/494d5169a2fb416aea4ce455c8e1eafa9151433a", "https://i.scdn.co/image/f950f93e5367ab7db32ff08eb9e8c4ebfda1521f", "https://i.scdn.co/image/081b5cb4367d7c85d2d6273cac7f49cf81d51515", "https://i.scdn.co/image/c4e309dd2f9180009998e4f3e50e7e655c65c6d3", "https://i.scdn.co/image/dc8df982dbfe421964e0504d05f922ba1fb5762e", "https://i.scdn.co/image/aa0926dbbcc314bdba703eba05db822f956f4862", "https://i.scdn.co/image/2c0c9f52d48734851d399e2008e4d56468d30032", "https://i.scdn.co/image/029aa834d8d326667022c1af24514aae96ac6719", "https://i.scdn.co/image/e099b75fda1212a72f2c45a5960c464a7560e8f5", "https://i.scdn.co/image/5e6a86596d7b4dd3ed49d41b2d7255dc0bfcb778", "https://i.scdn.co/image/7a81fab54aa31186d3a9bbd8d422169dc896faf9", "https://i.scdn.co/image/d9efe976f51676a5877e008b6cee259fe08e317b", "https://i.scdn.co/image/60e6348047c97b95e4ed5510c8383118bdc82e10", "https://i.scdn.co/image/2d9ee66803e2a3b8134632f00f90ad0e9380b893"]
        self.viewController?.imagesURLs = aa.flatMap { URL(string: $0) }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.viewController = segue.destination as? AlbumCoversViewController
    }

    @IBAction func aaaa(_ sender: Any) {
        self.viewController?.next(beginCallback: { 
            NSLog("begin")
        }, endCallback: { 
            NSLog("end")
        })
        
        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })

        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })

        self.viewController?.advanceTo(index: 10, beginCallback: {
            NSLog("begin advance")
        }, endCallback: {
            NSLog("end advance")
        })

        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })

        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })
        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })
        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })

        self.viewController?.advanceTo(index: 18, beginCallback: {
            NSLog("begin advance")
        }, endCallback: {
            NSLog("end advance")
        })

        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })
        self.viewController?.next(beginCallback: {
            NSLog("begin")
        }, endCallback: {
            NSLog("end")
        })
    }
}
