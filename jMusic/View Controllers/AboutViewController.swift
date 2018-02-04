//
//  AboutViewController.swift
//  jMusic
//
//  Created by Jota Melo on 01/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit
import iRate

class AboutViewController: BaseViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var clearCacheButton: UIButton!
    
    var cacheDirectory: URL?
    var didTap = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("About", comment: "")

        self.navigationController?.navigationBar.barTintColor = Colors.defaultNavigationBarBackgroundColor
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
        
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")
        
        if let version = version, let build = build {
            self.versionLabel.text = "jMusic \(version) (\(build))"
        }
        
        self.cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        self.updateCacheButton()
    }
    
    @objc func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateCacheButton() {
        
        let cacheSize = self.cacheDirectoryFileSize()
        
        let attributedTitleString = self.clearCacheButton.titleLabel?.attributedText?.mutableCopy() as? NSMutableAttributedString
        let sizeString = ByteCountFormatter.string(fromByteCount: Int64(cacheSize), countStyle: .file)
        let labelText = String.localizedStringWithFormat("Clear album covers cache (%@)", sizeString)
        
        attributedTitleString?.mutableString.setString(labelText)
        self.clearCacheButton.setAttributedTitle(attributedTitleString, for: .normal)
    }
    
    func cacheDirectoryFileSize() -> Int {
        
        // implementation based on NRFileManager
        // https://github.com/NikolaiRuhe/NRFoundation
        
        guard let cacheDirectory = self.cacheDirectory else { return 0 }
        
        var cacheDirectorySize = 0
        
        let properties: Set = [URLResourceKey.isRegularFileKey, URLResourceKey.fileAllocatedSizeKey, URLResourceKey.totalFileAllocatedSizeKey]
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: Array(properties)) else { return 0 }
        
        for item in enumerator {
            let itemURL = item as! URL
            
            guard let resourceValues = try? itemURL.resourceValues(forKeys: properties) else { continue }
            
            let isRegularFile = resourceValues.isRegularFile ?? false
            if (!isRegularFile) {
                continue // ignore anything except regular files
            }
            
            // We first try the most comprehensive value in terms of what the file may use on disk.
            // This includes metadata, compressin (on file system level) and block size.
            var fileSize = resourceValues.totalFileAllocatedSize
            
            // In case the value is inavailable we use the fallback value (excluding metadata and compression)
            // This value should always be available
            if fileSize == nil {
                fileSize = resourceValues.fileAllocatedSize
            }
            
            if let fileSize = fileSize {
                cacheDirectorySize += fileSize
            }
        }
        
        return cacheDirectorySize
    }
    
    //MARK - Actions
    
    @IBAction func openJota(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://jota.pm")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func openBruno(_ sender: Any) {
        UIApplication.shared.open(URL(string: "http://twitter.com/BrunoLvL")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func openTwitter(_ sender: Any) {
        UIApplication.shared.open(URL(string: "http://twitter.com/Jota")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func openEmail(_ sender: Any) {
        UIApplication.shared.open(URL(string: "mailto:jpmfagundes+jMusic@gmail.com")!, options: [:], completionHandler: nil)
    }
    
    @IBAction func openRate(_ sender: Any) {
        iRate.sharedInstance().openRatingsPageInAppStore()
    }
    
    @IBAction func clearCache(_ sender: Any) {
        
        guard let cacheDirectory = self.cacheDirectory else { return }
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        
        for item in enumerator {
            let itemURL = item as! URL
            try? FileManager.default.removeItem(at: itemURL)
        }
        
        self.updateCacheButton()
    }
    
    @IBAction func tapHandler(_ sender: Any) {
        self.didTap = true

        self.scrollView.isScrollEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.scrollView.isScrollEnabled = true
        }
    }
    
    @IBAction func swipeHandler(_ sender: Any) {
        
        if self.didTap {
            Helper.testMode = !Helper.testMode
            let alert = UIAlertController(title: "Test mode: \(Helper.testMode)", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: false, completion: nil)
        }
        
        self.didTap = false
    }
}

