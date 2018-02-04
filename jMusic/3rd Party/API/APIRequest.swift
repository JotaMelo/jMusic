//
//  APIRequest.swift
//
//  Created by Jota Melo on 29/01/17.
//  Copyright © 2017 Jota. All rights reserved.
//

import UIKit

public class APIRequest {
    
    typealias ResponseBlock<T> = (_ response: T?, _ error: API.RequestError?, _ cache: Bool) -> Void
    typealias ProgressBlock = (_ totalBytesSent: Int64, _ totalBytesExpectedToSend: Int64) -> Void
    
    struct Constants {
        static let baseURL = URL(string: "https://api.spotify.com")!
        static let apiPath = "v1/"
        static let authenticationHeaders = ["access-token", "client", "uid"]
        static let authenticationHeadersDefaultsKey = "authenticationHeaders"
    }
    
    var method: API.HTTPMethod
    var path: String
    var baseURL: URL
    var parameters: [String: Any]?
    var urlParameters: [String: Any]?
    var extraHeaders: [String: String]?
    
    var cacheOption = API.CacheOption.both
    var suppressErrorAlert = false
    
    var uploadBlock: ProgressBlock?
    var downloadBlock: ProgressBlock?
    var completionBlock: ResponseBlock<Any>?
    
    var parameterEncoder: ParameterEncoding.Type = API.JSONParameterEncoder.self
    
    private(set) var task: URLSessionDataTask?
    
    var shouldSaveInCache = true
    var cacheFileName: String {
        return APICacheManager.shared.cacheFileNameWith(path: self.path, method: self.method.rawValue, parameters: self.parameters)
    }
    
    init(method: API.HTTPMethod, path: String, parameters: [String: Any]?, urlParameters: [String: Any]?, cacheOption: API.CacheOption, completion: ResponseBlock<Any>?) {
        
        self.method = method
        self.path = path
        self.baseURL = Constants.baseURL.appendingPathComponent(Constants.apiPath)
        self.parameters = parameters
        self.urlParameters = urlParameters
        self.extraHeaders = nil
        self.cacheOption = cacheOption
        self.uploadBlock = nil
        self.downloadBlock = nil
        self.completionBlock = completion
        
        // on initialization, didSet is not called. But we want didSet to be called
        // on subclasses that implement it, so on this defer block all properties are
        // set again so didSet is called.
        defer {
            self.method = method
            self.path = path
            self.baseURL = [self.baseURL][0]
            self.parameters = parameters
            self.urlParameters = urlParameters
            self.extraHeaders = nil
            self.cacheOption = cacheOption
            self.uploadBlock = nil
            self.downloadBlock = nil
            self.completionBlock = completion
        }
    }
    
    func parse(_ data: Data?) -> Any? {
        
        if let data = data {
            var responseObject = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if responseObject == nil {
                responseObject = String(data: data, encoding: .utf8)
                if responseObject == nil {
                    return data
                }
            }
            
            return responseObject
        }
        
        return nil
    }
    
    func showErrorMessage(error: API.RequestError) {
        
        let errorMessage = error.localizedDescription
        
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: NSLocalizedString("Erro", comment: ""), message: errorMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }
    
    func handleSuccess(data: Data?, response: URLResponse) {
        
        guard let response = response as? HTTPURLResponse else { return }
        let responseObject = self.parse(data)
        
        NSLog("\n\n%@ %@", self.method.rawValue, response)
        NSLog("%@", "\(String(describing: responseObject))")
        
        if let responseObject = responseObject, self.shouldSaveInCache {
            APICacheManager.shared.write(data: responseObject, toCacheFile: self.cacheFileName)
        }
        
        for headerName in Constants.authenticationHeaders {
            if let headerValue = response.allHeaderFields[headerName] {
                if UserDefaults.standard.dictionary(forKey: Constants.authenticationHeadersDefaultsKey) == nil {
                    UserDefaults.standard.set([:], forKey: Constants.authenticationHeadersDefaultsKey)
                }
                
                guard var storedAuthenticationHeaders = UserDefaults.standard.dictionary(forKey: Constants.authenticationHeadersDefaultsKey) else { break }
                storedAuthenticationHeaders[headerName] = headerValue
                UserDefaults.standard.set(storedAuthenticationHeaders, forKey: Constants.authenticationHeadersDefaultsKey)
            }
        }
        
        if Thread.isMainThread {
            self.completionBlock?(responseObject, nil, false)
        } else {
            DispatchQueue.main.async {
                self.completionBlock?(responseObject, nil, false)
            }
        }
    }
    
    func handleError(data: Data?, response: URLResponse?, error: Error?) {
        
        // ignore error triggered when task is cancelled
        if let error = error as? URLError, error.code == .cancelled {
            return
        }
        
        let responseObject = self.parse(data)
        
        NSLog("\n\n%@ %@", self.method.rawValue, response ?? "<nil>")
        NSLog("%@", "\(String(describing: responseObject))")
        
        let error = API.RequestError(responseObject: responseObject, urlResponse: response as? HTTPURLResponse, originalError: error)
        
        if !self.suppressErrorAlert {
            self.showErrorMessage(error: error)
        }
        
        if Thread.isMainThread {
            self.completionBlock?(responseObject, error, false)
        } else {
            DispatchQueue.main.async {
                self.completionBlock?(responseObject, error, false)
            }
        }
    }
    
    func makeRequest() {
        
        var hasCache = false
        
        if self.cacheOption == .both || self.cacheOption == .cacheOnly {
            hasCache = APICacheManager.shared.callBlock(self.completionBlock, ifCacheExistsForFileName: self.cacheFileName)
        }
        
        if self.cacheOption == .both || self.cacheOption == .networkOnly || !hasCache {
            var parameters = self.parameters
            var urlParameters = self.urlParameters
            var headers = self.extraHeaders ?? [:]
            var path = self.path
            var body: Data? = nil
            
            for headerName in Constants.authenticationHeaders {
                let headerValue = UserDefaults.standard.dictionary(forKey: Constants.authenticationHeadersDefaultsKey)?[headerName]
                if let headerValue = headerValue as? String {
                    headers[headerName] = headerValue
                }
            }
            
            // parameters in a GET request are always urlParameters
            if self.method == .get, let bodyParameters = parameters {
                if urlParameters == nil {
                    urlParameters = [:]
                }
                
                bodyParameters.forEach { urlParameters?[$0.key] = $0.value }
                parameters = nil
            }
            
            if let urlParameters = urlParameters {
                let queryString = API.URLParameterEncoder.encode(parameters: urlParameters)
                path = path.appending("?\(queryString)")
            }
            
            if let parameters = parameters {
                let hasDataParameters = API.checkForDataObjectsIn(Array(parameters.values))
                if hasDataParameters {
                    let flattenedParameters = API.flatten(dictionary: parameters)
                    var multipartBuilder = API.MultipartFormDataBuilder()
                    
                    body = multipartBuilder.requestBody(with: flattenedParameters)
                    headers["Content-Type"] = multipartBuilder.contentTypeHeader
                } else {
                    body = self.parameterEncoder.encode(parameters: parameters).data(using: .utf8)
                    headers["Content-Type"] = self.parameterEncoder.contentTypeHeader
                }
            }
            
            var request = URLRequest(url: URL(string: path, relativeTo: self.baseURL)!)
            request.httpMethod = self.method.rawValue
            request.httpBody = body
            request.allHTTPHeaderFields = headers
            
            var task: URLSessionDataTask? // "Variable used within its own initial value" oh fuck you, Swift
            task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                API.RequestProgressWatcher.shared.remove(task: task)
                
                if let response = response as? HTTPURLResponse, response.statusCode <= 299 && error == nil {
                    self.handleSuccess(data: data, response: response)
                } else {
                    self.handleError(data: data, response: response, error: error)
                }
            })
            
            API.RequestProgressWatcher.shared.add(task: task, forRequest: self)
            task?.resume()
            
            self.task = task
        }
    }
}

extension API.RequestError: LocalizedError {
    
    public var errorDescription: String? {
        if let responseObject = self.responseObject as? [String: Any], let error = responseObject["error"] as? String {
            return error
        } else if let urlResponse = self.urlResponse {
            return HTTPURLResponse.localizedString(forStatusCode: urlResponse.statusCode)
        }
        
        return self.originalError?.localizedDescription
    }
}
