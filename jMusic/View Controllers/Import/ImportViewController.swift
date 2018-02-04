//
//  ImportViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import BEMCheckBox
import MediaPlayer

protocol ImportViewControllerDelegate: class {
    func didTapProgressButton(on viewController: ImportViewController)
}

class ImportViewController: BaseViewController {
    
    @IBOutlet var playlistProgressButton: UIButton!
    @IBOutlet var checkBox: BEMCheckBox!
    @IBOutlet var trackNameLabel: UILabel!
    @IBOutlet var trackArtistAlbumLabel: UILabel!
    @IBOutlet var progressCounterLabel: UILabel!
    @IBOutlet var playlistNameLabel: UILabel!
    
    weak var delegate: ImportViewControllerDelegate?
    weak var importInfo: ImportInfo!
    
    private var albumCoversViewController: AlbumCoversViewController?
    private var animationsQueue = AnimationsQueue()
    private var currentIndex: Int = 0
    private var checkBoxAnimationCallback: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Importing", comment: "")
        
        self.navigationBarBackgroundColor = Colors.inProgressNavigationBarBackgrondColor
        self.navigationItem.hidesBackButton = true
        self.checkBox.onAnimationType = .fill
        self.checkBox.offAnimationType = .fill
        self.checkBox.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
    
        self.updateCurrentPlaylistInfo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "albumCovers" {
            self.albumCoversViewController = segue.destination as? AlbumCoversViewController
        }
    }
    
    func showCheckbox(withCompletion completion: (() -> Void)?) {
        
        self.checkBoxAnimationCallback = completion
        self.checkBox.setOn(true, animated: true)
    }
    
    func hideCheckbox(withCompletion completion: (() -> Void)?) {
        
        self.checkBoxAnimationCallback = completion
        self.checkBox.setOn(false, animated: true)
    }
    
    func updateCurrentPlaylistInfo(animated: Bool = false) {
     
        if self.importInfo.imports.count == 1 {
            self.playlistProgressButton.isUserInteractionEnabled = false
            self.playlistProgressButton.setTitle(NSLocalizedString("IMPORTING", comment: ""), for: .normal)
        } else {
            let text = "IMPORTING PLAYLIST \(self.importInfo.totalProcessed + 1) OF \(self.importInfo.imports.count)"
            let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: self.playlistProgressButton.titleLabel!.textColor, .font: UIFont(name: "Avenir-Heavy", size: 14)!, .underlineStyle: NSUnderlineStyle.styleThick.rawValue]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            self.playlistProgressButton.setAttributedTitle(attributedString, for: .normal)
        }
        
        self.playlistNameLabel.text = self.importInfo.currentImport.playlist.name
        
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.albumCoversViewController?.view.alpha = 0
        }, completion: { _ in
            self.albumCoversViewController?.imagesURLs = self.importInfo.currentImport.tracks.map { $0.albumCoverURL }
            self.albumCoversViewController?.advanceTo(index: self.importInfo.currentImport.totalProcessed, beginCallback: nil, endCallback: nil, animated: false)
            
            UIView.animate(withDuration: duration, animations: {
                self.albumCoversViewController?.view.alpha = 1
            })
        })
        
        self.currentIndex = self.importInfo.currentImport.totalProcessed
        self.updateTrackLabels(forIndex: self.currentIndex)
        self.updateCounterLabel(forIndex: self.currentIndex)
    }
    
    func goNext() {
        
        self.animationsQueue.add { callback in
            self.checkBox.setOn(true, animated: true)
            
            self.currentIndex += 1
            let currentIndex = self.currentIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.albumCoversViewController?.advanceTo(index: currentIndex, beginCallback: {
                    self.checkBox.setOn(false, animated: true)
                    
                    UIView.animate(withDuration: 0.15, animations: {
                        self.trackNameLabel.alpha = 0
                        self.trackArtistAlbumLabel.alpha = 0
                    }, completion: { finished in
                        UIView.animate(withDuration: 0.15, animations: {
                            self.updateCounterLabel(forIndex: currentIndex)
                            self.updateTrackLabels(forIndex: currentIndex)
                            
                            self.view.layoutIfNeeded()
                        })
                    })
                }, endCallback: {
                    callback()
                })
            }
        }
    }
    
    func updateUI() {
        
        self.currentIndex = self.importInfo.currentImport.totalProcessed
        self.albumCoversViewController?.advanceTo(index: self.currentIndex, beginCallback: {
            self.updateCounterLabel(forIndex: self.currentIndex)
            self.updateTrackLabels(forIndex: self.currentIndex)
        }, endCallback: nil)
    }
    
    func updateCounterLabel(forIndex index: Int) {
        
        let heavyAttributes = [NSAttributedStringKey.foregroundColor: Colors.contentTextColor, NSAttributedStringKey.font: UIFont(name: "Avenir-Heavy", size: 17)!]
        let regularAttributes = [NSAttributedStringKey.foregroundColor: Colors.contentTextColor, NSAttributedStringKey.font: UIFont(name: "Avenir-Book", size: 17)!]
        
        let progressAttributesString = NSMutableAttributedString(string: "\(index) ", attributes: heavyAttributes)
        progressAttributesString.append(NSAttributedString(string: NSLocalizedString("of", comment: ""), attributes: regularAttributes))
        progressAttributesString.append(NSAttributedString(string: " \(self.importInfo.currentImport.tracks.count) ", attributes: heavyAttributes))
        progressAttributesString.append(NSAttributedString(string: NSLocalizedString("songs", comment: ""), attributes: regularAttributes))
        
        self.progressCounterLabel.attributedText = progressAttributesString
    }
    
    func updateTrackLabels(forIndex index: Int) {
        guard index < self.importInfo.currentImport.tracks.count else { return }
        
        let currentTrack = self.importInfo.currentImport.tracks[index]
        
        self.trackNameLabel.text = currentTrack.name
        self.trackNameLabel.alpha = 1
        
        self.trackArtistAlbumLabel.text = "\(currentTrack.artist) - \(currentTrack.album)"
        self.trackArtistAlbumLabel.alpha = 1
    }
    
    @IBAction func progressAction(_ sender: Any) {
        self.delegate?.didTapProgressButton(on: self)
    }
}

// MARK: - BEMCheckBox delegate

extension ImportViewController: BEMCheckBoxDelegate {
    
    func animationDidStop(for checkBox: BEMCheckBox) {
        
        let callback = self.checkBoxAnimationCallback
        self.checkBoxAnimationCallback = nil
        callback?()
    }
}
