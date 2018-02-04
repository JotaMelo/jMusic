//
//  AlbumCoversViewController.swift
//  jMusic
//
//  Created by Jota Melo on 08/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import SDWebImage


struct AlbumImage {
    let url: URL?
    let image: UIImage?
}

class AlbumCoversViewController: UIViewController {

    @IBOutlet var containerView: UIView!
    @IBOutlet var leftCoverImageView: UIImageView!
    @IBOutlet var centerCoverImageView: UIImageView!
    @IBOutlet var rightCoverImageView: UIImageView!
    @IBOutlet var auxiliaryRightCoverImageView: UIImageView!
    
    @IBOutlet var rightCoverRightConstraint: NSLayoutConstraint!
    @IBOutlet var leftCoverLeftConstraint: NSLayoutConstraint!
    
    private var albumImages: [AlbumImage] = []
    private var animationsQueue = AnimationsQueue()
    private var animationView: AlbumCoversAnimationView?
    private(set) var currentIndex = 0
    
    var imagesURLs: [URL?] = [] {
        didSet {
            SDWebImagePrefetcher.shared().prefetchURLs(self.imagesURLs.flatMap { $0 })
            
            self.albumImages = self.imagesURLs.map { AlbumImage(url: $0, image: nil) }
            self.currentIndex = 0
            self.updateImages()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layoutIfNeeded()
        
        self.rightCoverRightConstraint.constant = -(self.rightCoverImageView.frame.size.width / 2.0)
        self.leftCoverLeftConstraint.constant = self.rightCoverRightConstraint.constant
    }
    
    private func updateImages() {
        
        self.leftCoverImageView.setAlbumImage(self.albumImages[safe: self.currentIndex - 1])
        self.centerCoverImageView.setAlbumImage(self.albumImages[safe: self.currentIndex])
        self.rightCoverImageView.setAlbumImage(self.albumImages[safe: self.currentIndex + 1])
        self.auxiliaryRightCoverImageView.setAlbumImage(self.albumImages[safe: self.currentIndex + 2])
    }
    
    private func addAnimationView() {
        
        let animationView = AlbumCoversAnimationView(albumCoversViewController: self)
        self.animationView = animationView
        
        self.view.addSubview(animationView)
        self.containerView.isHidden = true
    }
    
    private func removeAnimationView() {
        
        self.containerView.isHidden = false
        self.animationView?.removeFromSuperview()
        self.animationView = nil
    }
    
    // MARK: - Public methods
    
    func next(beginCallback: (() -> Void)?, endCallback: (() -> Void)?) {
        
        if self.animationsQueue.lastQueuedIndex >= self.albumImages.count - 1 {
            return
        }
        
        self.animationsQueue.add { (itemCallback) in
            // repeat check because currentIndex might've changed until this is run
            if self.animationsQueue.lastQueuedIndex >= self.albumImages.count - 1 {
                beginCallback?()
                endCallback?()
                itemCallback()
                return
            }
            
            self.addAnimationView()
            
            beginCallback?()
            self.animationView?.animateNext {
                self.currentIndex += 1
                self.updateImages()
                
                self.removeAnimationView()
                
                endCallback?()
                itemCallback()
            }
        }
        self.animationsQueue.lastQueuedIndex += 1
    }
    
    func advanceTo(index: Int, beginCallback: (() -> Void)?, endCallback: ((() -> Void)?), animated: Bool = true) {
        
        if index == self.animationsQueue.lastQueuedIndex || index >= self.albumImages.count {
            return
        }
        
        if index == self.animationsQueue.lastQueuedIndex + 1 {
            self.next(beginCallback: beginCallback, endCallback: endCallback)
            return
        }
        
        var images: [AlbumImage]
        if index == 0 {
            images = [self.albumImages[index]]
            if self.albumImages.count > 1 {
                images.append(self.albumImages[1])
            }
        } else {
            images = [self.albumImages[index - 1], self.albumImages[index]]
            if index < self.albumImages.count - 2 {
                images.append(self.albumImages[index + 1])
            }
        }
        
        self.animationsQueue.add { (itemCallback) in
            self.addAnimationView()
            
            beginCallback?()
            
            let finishBlock = {
                self.currentIndex = index
                
                self.updateImages()
                self.removeAnimationView()
                
                endCallback?()
                itemCallback()
            }
            
            if !animated {
                finishBlock()
                return
            }
            
            self.animationView?.animateTo(images: images.flatMap { $0 }, callback: {
                finishBlock()
            })
        }
        self.animationsQueue.lastQueuedIndex = index
    }

}

// MARK: - Extensions

fileprivate extension UIImageView {
    
    func setAlbumImage(_ albumImage: AlbumImage?) {
        
        if albumImage == nil {
            self.image = nil
            return
        }
        
        if let image = albumImage?.image {
            self.image = image
        } else if let url = albumImage?.url {
            self.sd_setImage(with: url)
        } else {
            self.image = #imageLiteral(resourceName: "albumCoverPlaceholder")
        }
    }
}

extension Collection {
    
    // Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Helper classes

class AlbumCoversAnimationView: UIView {
    
    var leftCoverImageView: UIImageView!
    var centerCoverImageView: UIImageView!
    var rightCoverImageView: UIImageView!
    var rightCoverOverlayImageView: UIImageView!
    var auxiliaryRightCoverImageView: UIImageView!
    
    var leftCoverImageViewOriginalFrame: CGRect = CGRect.zero
    var centerCoverImageViewOriginalFrame: CGRect = CGRect.zero
    var rightCoverImageViewOriginalFrame: CGRect = CGRect.zero
    
    convenience init(albumCoversViewController: AlbumCoversViewController) {
        self.init(frame: albumCoversViewController.view.bounds)
        
        self.leftCoverImageView = UIImageView(frame: albumCoversViewController.leftCoverImageView.frame)
        self.leftCoverImageView.image = albumCoversViewController.leftCoverImageView.image
        self.leftCoverImageViewOriginalFrame = self.leftCoverImageView.frame
        self.addSubview(self.leftCoverImageView)
        
        self.auxiliaryRightCoverImageView = UIImageView(frame: albumCoversViewController.auxiliaryRightCoverImageView.frame)
        self.auxiliaryRightCoverImageView.image = albumCoversViewController.auxiliaryRightCoverImageView.image
        self.addSubview(self.auxiliaryRightCoverImageView)
        
        self.rightCoverImageView = UIImageView(frame: albumCoversViewController.rightCoverImageView.frame)
        self.rightCoverImageView.image = albumCoversViewController.rightCoverImageView.image
        self.rightCoverImageViewOriginalFrame = self.rightCoverImageView.frame
        self.addSubview(self.rightCoverImageView)
        
        self.centerCoverImageView = UIImageView(frame: albumCoversViewController.centerCoverImageView.frame)
        self.centerCoverImageView.image = albumCoversViewController.centerCoverImageView.image
        self.centerCoverImageViewOriginalFrame = self.centerCoverImageView.frame
        self.addSubview(self.centerCoverImageView)
        
        self.rightCoverOverlayImageView = UIImageView(frame: albumCoversViewController.rightCoverImageView.frame)
        self.rightCoverOverlayImageView.image = albumCoversViewController.rightCoverImageView.image
        self.rightCoverOverlayImageView.alpha = 0
        self.addSubview(self.rightCoverOverlayImageView)
    }
    
    func animateNext(callback: @escaping () -> Void) {
        
        UIView.animate(withDuration: 0.3, animations: {
            self.rightCoverOverlayImageView.alpha = 1
            self.auxiliaryRightCoverImageView.frame = self.rightCoverImageView.frame
            self.rightCoverImageView.frame = self.centerCoverImageView.frame
            self.rightCoverOverlayImageView.frame = self.rightCoverImageView.frame
            self.centerCoverImageView.frame = self.leftCoverImageView.frame
            self.leftCoverImageView.frame = self.leftCoverImageView.frame.offsetBy(dx: -self.leftCoverImageView.frame.size.width, dy: 0)
        }, completion: { finished in
            callback()
        })
    }
    
    func animateTo(images: [AlbumImage], callback: @escaping () -> Void) {
        
        // only 2 or 3 images supported
        if images.count < 2 || images.count > 3 {
            return
        }
        
        var images = images // make it mutable
        let margin: CGFloat = 10
        let animationDuration: TimeInterval = 0.25
        
        self.bringSubview(toFront: self.centerCoverImageView)
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [UIViewAnimationOptions.curveEaseInOut], animations: {
            // shrink center image to same size as others while keeping it centered
            self.centerCoverImageView.frame.size = self.leftCoverImageView.frame.size
            self.centerCoverImageView.frame.origin.x = (self.frame.size.width - self.centerCoverImageView.frame.size.width) / 2
            self.centerCoverImageView.frame.origin.y = self.leftCoverImageView.frame.origin.y
            
            // move other covers to have a 10px margin to the center image
            self.leftCoverImageView.frame.origin.x = self.centerCoverImageView.frame.origin.x - margin - self.leftCoverImageView.frame.size.width
            self.rightCoverImageView.frame.origin.x = self.centerCoverImageView.frame.origin.x + margin + self.centerCoverImageView.frame.size.width
            self.auxiliaryRightCoverImageView.frame.origin.x = self.rightCoverImageView.frame.origin.x + margin + self.rightCoverImageView.frame.size.width
            
        }, completion: { _ in
            self.auxiliaryRightCoverImageView.setAlbumImage(images[0])
            images.remove(at: 0)

            var additionalImageViews: [UIImageView] = []

            var lastImageView = self.auxiliaryRightCoverImageView!
            for image in images {
                var imageViewFrame = CGRect()
                imageViewFrame.origin = CGPoint(x: lastImageView.frame.origin.x + lastImageView.frame.size.width + margin, y: lastImageView.frame.origin.y)
                imageViewFrame.size = lastImageView.frame.size

                let imageView = UIImageView(frame: imageViewFrame)
                imageView.setAlbumImage(image)
                self.addSubview(imageView)

                lastImageView = imageView
                additionalImageViews.append(imageView)
            }

            // "offset" is the total width taken by the 3 visible images, including their off-screen portion
            let offset = (self.leftCoverImageView.frame.size.width * 3) + (margin * 2)
            UIView.animate(withDuration: animationDuration, delay: 0, options: [UIViewAnimationOptions.curveEaseInOut], animations: {
                for subview in self.subviews {
                    if subview is UIImageView {
                        let imageView = subview as! UIImageView
                        imageView.frame.origin.x -= offset
                    }
                }
            }, completion: { _ in
                let leftImageView = self.auxiliaryRightCoverImageView
                let centerImageView = additionalImageViews[0]
                let rightImageView: UIImageView? = additionalImageViews.count == 2 ? additionalImageViews.last : nil

                self.bringSubview(toFront: centerImageView)

                UIView.animate(withDuration: animationDuration, delay: 0, options: [UIViewAnimationOptions.curveEaseInOut], animations: {
                    leftImageView?.frame = self.leftCoverImageViewOriginalFrame
                    centerImageView.frame = self.centerCoverImageViewOriginalFrame
                    rightImageView?.frame = self.rightCoverImageViewOriginalFrame
                }, completion: { _ in
                    callback()
                })
            })
        })
    }
    
}
