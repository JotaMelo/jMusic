//
//  API.swift
//
//  Created by Jota Melo on 24/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import Foundation

protocol ParameterEncoding {
    static var contentTypeHeader: String { get }
    static func encode(parameters: [String: Any]) -> String
}

struct API {
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    enum CacheOption {
        case cacheOnly
        case networkOnly
        case both
    }
    
    struct RequestError: Error {
        var responseObject: Any?
        var urlResponse: HTTPURLResponse?
        var originalError: Error?
    }
    
    static func checkForDataObjectsIn(_ parameters: [Any]) -> Bool {
        
        for object in parameters {
            if object is Data {
                return true
            } else if let object = object as? [String: Any] {
                let hasData = self.checkForDataObjectsIn(Array(object.values))
                
                if hasData {
                    return true
                }
            } else if let object = object as? [Any] {
                let hasData = self.checkForDataObjectsIn(object)
                
                if hasData {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func flatten(dictionary: [String: Any], keyString: String? = nil) -> [String: Any] {
        
        var flattenedDictionary: [String: Any] = [:]
        
        for (key, value) in dictionary {
            var newKey = ""
            if let keyString = keyString {
                newKey = "\(keyString)[\(key)]"
            } else {
                newKey = key
            }
            
            if let value = value as? [String: Any] {
                let flattenedSubDictionary = self.flatten(dictionary: value, keyString: newKey)
                flattenedSubDictionary.forEach { flattenedDictionary[$0.key] = $0.value }
            } else if let value = value as? [Any] {
                let flattenedSubDictionary = self.flatten(array: value, keyString: newKey)
                flattenedSubDictionary.forEach { flattenedDictionary[$0.key] = $0.value }
            } else {
                flattenedDictionary[newKey] = value
            }
        }
        
        return flattenedDictionary
    }
    
    static func flatten(array: [Any], keyString: String) -> [String: Any] {
        
        var flattenedDictionary: [String: Any] = [:]
        
        for i in 0..<array.count {
            let value = array[i]
            
            let newKey = "\(keyString)[\(i)]"
            
            if let value = value as? [String: Any] {
                let flattenedSubDictionary = self.flatten(dictionary: value, keyString: newKey)
                flattenedSubDictionary.forEach { flattenedDictionary[$0.key] = $0.value }
            } else if let value = value as? [Any] {
                let flattenedSubDictionary = self.flatten(array: value, keyString: newKey)
                flattenedSubDictionary.forEach { flattenedDictionary[$0.key] = $0.value }
            } else {
                flattenedDictionary[newKey] = value
            }
        }
        
        return flattenedDictionary
    }
    
    // RFC2388 https://www.ietf.org/rfc/rfc2388.txt
    struct MultipartFormDataBuilder {
        
        let boundary = "__X_API_BOUNDARY__\(arc4random())__"
        private(set) var body = Data()
        var contentTypeHeader: String {
            get {
                return "multipart/form-data; charset=utf-8; boundary=\(self.boundary)"
            }
        }
        
        mutating func requestBody(with parameters: [String: Any]) -> Data {
            
            guard let boundaryData = "\r\n--\(self.boundary)".data(using: .utf8) else {
                fatalError("Couldn't build boundaryData")
            }
            
            self.body.append(boundaryData)
            
            for (key, value) in parameters {
                if let value = value as? Data {
                    var fileName = "\(arc4random())"
                    
                    let fileInfo = self.fileInfo(for: value)
                    if let fileExtension = fileInfo.extension {
                        fileName += ".\(fileExtension)"
                    }
                    
                    self.addPart(value, key: key, fileName: fileName, contentType: fileInfo.mimeType)
                } else {
                    self.addPart(value, key: key)
                }
                
                self.body.append(boundaryData)
            }
            
            // last boundary is marked with a trailing "--"
            self.body.append("--".data(using: .utf8)!)
            
            return self.body
        }
        
        mutating func addPart(_ data: Data, key: String, fileName: String, contentType: String) {
            
            var header = "\r\n"
            header += "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(fileName)\""
            header += "\r\n"
            header += "Content-Type: \(contentType)"
            header += "\r\n\r\n"
            
            guard let headerData = header.data(using: .utf8) else {
                fatalError("Couldn't build headerData")
            }
            
            self.body.append(headerData)
            self.body.append(data)
        }
        
        mutating func addPart(_ data: Any, key: String) {
            
            var partString = "\r\n"
            partString += "Content-Disposition: form-data; name=\"\(key)\""
            partString += "\r\n\r\n"
            partString += "\(data)"
            
            guard let partData = partString.data(using: .utf8) else {
                fatalError("Couldn't build partData")
            }
            
            self.body.append(partData)
        }
        
        func fileInfo(for data: Data) -> (mimeType: String, extension: String?) {
            
            var bytes = [UInt8](data)
            
            switch bytes[0] {
            case 0xFF:
                return ("image/jpeg", "jpg")
            case 0x89:
                return ("image/png", "png")
            case 0x47:
                return ("image/gif", "gif")
            case 0x49, 0x4D:
                return ("image/tiff", "tiff")
            case 0x25:
                return ("application/pdf", "pdf")
            case 0xD0:
                return ("application/vnd", nil)
            case 0x46:
                return ("text/plain", "txt")
            default:
                return ("application/octet-stream", nil)
            }
        }
    }
    
    struct URLParameterEncoder: ParameterEncoding {
        
        static let contentTypeHeader = "application/x-www-form-urlencoded"
        
        static func encode(string: String) -> String {
            
            var allowedCharacterSet = CharacterSet.urlQueryAllowed
            allowedCharacterSet.remove(charactersIn: ";/?:@&=+$, ()")
            return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        }
        
        static func encode(parameters: [String: Any]) -> String {
            
            var encodedString = ""
            for (key, value) in parameters {
                let encodedValue = self.encode(string: "\(value)")
                encodedString += "\(key)=\(encodedValue)&"
            }
            
            return String(encodedString.dropLast())
        }
        
        static func decode(queryString: String) -> [String: String]? {
            
            var decodedParameters: [String: String] = [:]
            
            guard let queryString = queryString.components(separatedBy: "?").last else { return nil }
            for component in queryString.components(separatedBy: "&") {
                var parameterComponents = component.components(separatedBy: "=")
                
                guard parameterComponents.count >= 2 else {
                    return nil
                }
                
                let parameterName = parameterComponents[0]
                parameterComponents.removeFirst()
                decodedParameters[parameterName] = parameterComponents.joined().removingPercentEncoding
            }
            
            return decodedParameters
        }
        
    }
    
    struct JSONParameterEncoder: ParameterEncoding {
        
        static let contentTypeHeader = "application/json"
        
        static func encode(parameters: [String: Any]) -> String {
            
            let jsonData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
            return String(data: jsonData, encoding: .utf8)!
        }
    }
    
    class RequestProgressWatcher: NSObject {
        
        static let shared = RequestProgressWatcher()
        
        let bytesSentKeyPath = NSStringFromSelector(#selector(getter: URLSessionTask.countOfBytesSent))
        let bytesReceivedKeyPath = NSStringFromSelector(#selector(getter: URLSessionTask.countOfBytesReceived))
        var requests: [URLSessionDataTask: APIRequest] = [:]
        
        func add(task: URLSessionDataTask?, forRequest request: APIRequest) {
            
            guard let task = task else { return }
            
            requests[task] = request
            task.addObserver(self, forKeyPath: self.bytesSentKeyPath, options: .new, context: nil)
            task.addObserver(self, forKeyPath: self.bytesReceivedKeyPath, options: .new, context: nil)
        }
        
        func remove(task: URLSessionDataTask?) {
            
            guard let task = task else { return }
            
            task.removeObserver(self, forKeyPath: self.bytesSentKeyPath)
            task.removeObserver(self, forKeyPath: self.bytesReceivedKeyPath)
            requests.removeValue(forKey: task)
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            
            if let object = object as? URLSessionDataTask, let request = self.requests[object] {
                if keyPath == self.bytesSentKeyPath && object.countOfBytesExpectedToSend > 0 {
                    request.uploadBlock?(object.countOfBytesSent, object.countOfBytesExpectedToSend)
                } else if keyPath == self.bytesReceivedKeyPath {
                    request.downloadBlock?(object.countOfBytesReceived, object.countOfBytesExpectedToReceive)
                }
            }
        }
    }
}
