//
//  APICacheManager.swift
//
//  Created by Jota Melo on 24/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

class APICacheManager {
    
    fileprivate class MemoryCacheItem {
        
        fileprivate var key: String
        fileprivate var data: Any
        fileprivate var size: Int
        fileprivate var accessCount: Int = 0
        
        init(key: String, data: Any, size: Int) {
            self.key = key
            self.data = data
            self.size = size
        }
    }
    
    fileprivate struct Constants {
        static var cacheFileExtension = "apicache"
        static var inMemoryCacheDefaultMaxSize = 1000000
    }
    
    static var shared = APICacheManager()
    var inMemoryCacheMaxSize = Constants.inMemoryCacheDefaultMaxSize
    
    fileprivate var cacheFiles: [URL] {
        let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let localFileManager = FileManager()
        guard let directoryEnumerator = localFileManager.enumerator(at: documentsDirectory, includingPropertiesForKeys: nil) else { return [] }
        
        return directoryEnumerator.flatMap { fileURL -> URL? in
            guard let fileURL = fileURL as? URL else { return nil }
            if fileURL.pathExtension == Constants.cacheFileExtension {
                return fileURL
            } else {
                return nil
            }
        }
    }
    
    fileprivate var memoryCache: [String: MemoryCacheItem] = [:]
    fileprivate var currentSize = 0
    
    init() {
        self.loadMemoryCache()
    }
    
    private func loadMemoryCache() {
        
        for fileURL in self.cacheFiles {
            guard let item = self.cacheItemFor(url: fileURL) else { continue }
            
            if self.currentSize + item.size <= self.inMemoryCacheMaxSize {
                self.memoryCache[item.key] = item
                self.currentSize += item.size
            } else {
                break;
            }
        }
    }
    
    fileprivate func URLForFileName(_ fileName: String) -> URL {
        
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    fileprivate func calculateSHA1ForData(_ data: Data) -> String {
        
        let dataBytes = [UInt8](data)
        
        let length = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        CC_SHA1(dataBytes, CC_LONG(data.count), &digest)
        
        return digest.map { String(format: "%02x", $0) }.joined(separator: "")
    }
    
    fileprivate func cacheItemFor(url: URL) -> MemoryCacheItem? {
        
        guard let fileData = try? Data(contentsOf: url) else { return nil }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: fileData)
        guard let response = unarchiver.decodeObject(forKey: "data") as? [String: AnyObject],
            let data = response["data"] else { return nil }
        
        return MemoryCacheItem(key: url.lastPathComponent, data: data, size: fileData.count)
    }
    
    fileprivate func callResponseBlock(_ block: APIRequest.ResponseBlock<Any>?, onMainThreadWithData data: Any?) {
        
        if Thread.isMainThread {
            block?(data, nil, true)
        } else {
            DispatchQueue.main.async {
                block?(data, nil, true)
            }
        }
    }
    
    fileprivate func optimizeInMemoryCache() {
        
        let sortedItems = self.memoryCache.values.sorted { item1, item2 -> Bool in
            return item1.accessCount > item2.accessCount
        }
        
        self.memoryCache = [:]
        self.currentSize = 0
        
        for item in sortedItems {
            if self.currentSize + item.size <= self.inMemoryCacheMaxSize {
                self.memoryCache[item.key] = item
                self.currentSize += item.size
            } else {
                break
            }
        }
    }
}

// MARK: - Public Methods

extension APICacheManager {
    
    func cacheFileNameWith(path: String, method: String, parameters: [String: Any]?) -> String {
        
        let encodedData = NSMutableData()
        
        let archiver = NSKeyedArchiver(forWritingWith: encodedData)
        archiver.encode(path, forKey: "path")
        archiver.encode(method, forKey: "method")
        archiver.encode(parameters, forKey: "parameters")
        archiver.finishEncoding()
        
        let fileName = self.calculateSHA1ForData(encodedData as Data)
        return "\(fileName).\(Constants.cacheFileExtension)"
    }
    
    func write(data: Any, toCacheFile cacheFileName: String) {
        
        DispatchQueue.global(qos: .utility).async {
            if let cacheItem = self.memoryCache[cacheFileName] {
                cacheItem.data = data
                self.currentSize -= cacheItem.size // new size will be added at the end
            } else {
                self.memoryCache[cacheFileName] = MemoryCacheItem(key: cacheFileName, data: data, size: 0)
            }
            
            let cacheURL = self.URLForFileName(cacheFileName)
            let fileData = NSMutableData()
            
            let archiver = NSKeyedArchiver(forWritingWith: fileData)
            archiver.encode(["data": data], forKey: "data")
            archiver.finishEncoding()
            
            fileData.write(to: cacheURL, atomically: true)
            
            self.memoryCache[cacheFileName]?.size = fileData.length
            self.currentSize += fileData.length
            
            if self.currentSize > self.inMemoryCacheMaxSize {
                self.optimizeInMemoryCache()
            }
        }
    }
    
    func isFilePresentInMemoryCache(fileName: String) -> Bool {
        return self.memoryCache[fileName] != nil
    }
    
    @discardableResult
    func callBlock(_ block: APIRequest.ResponseBlock<Any>?, ifCacheExistsForFileName fileName: String) -> Bool {
        
        if let item = self.memoryCache[fileName] {
            item.accessCount += 1
            self.callResponseBlock(block, onMainThreadWithData: item.data)
            
            return true
        }
        
        let localFileManager = FileManager()
        let cacheURL = self.URLForFileName(fileName)
        
        if localFileManager.fileExists(atPath: cacheURL.path) {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let item = self.cacheItemFor(url: cacheURL) else { return }
                self.callResponseBlock(block, onMainThreadWithData: item.data)
            }
            
            return true
        }
        
        return false
    }
    
    func clearCache() {
        
        self.memoryCache = [:]
        
        let localFileManager = FileManager()
        for file in self.cacheFiles {
            try? localFileManager.removeItem(at: file)
        }
    }
}
