//
//  File.swift
//  
//
//  Created by Marcel Piešťanský on 22.08.2021.
//

import Foundation
import AFNetworking

public protocol ApiServiceAuthDelegate: AnyObject {
    func refreshSession(completion:  @escaping (_ auth: AuthCredential?, _ error: NSError?) -> Void)
    func onForceUpgrade()
    func sessionDidRevoke()
}

public protocol ApiService: ApiUrlInjected {
    var sessionManager: AFHTTPSessionManager { get }
    
    var authDelegate: ApiServiceAuthDelegate? { get set }
    
    func request<T>(_ request: Request, completion: @escaping (_ response: T) -> Void) where T: Response
    func request<T>(_ request: Request, completion: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, Error>) -> Void) where T: Codable
    func request(_ request: Request, completion: @escaping (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void)
}

public extension ApiService {
    
    func request<T>(_ request: Request, completion: @escaping (_ response: T) -> Void) where T: Response {
        self.request(request) { _, resp, err in
            let type = T.self
            let response = type.init()
            
            if let error = err {
                response.parseHttpError(error)
                
                if let res = resp {
                    response.parseResponse(res)
                }
                
                completion(response)
                return
            }
            
            if let res = resp {
                var hasError: Bool = response.parseResponseError(res)
                if !hasError {
                    hasError = !response.parseResponse(res)
                }
                
                completion(response)
                return
            }
            
            response.error = NSError.badResponse()
            completion(response)
        }
    }
    
    func request<T>(_ request: Request, completion: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, Error>) -> Void) where T: Codable {
        self.request(request) { task, resp, err in
            let result: Result<T, Error> = self.getCodableResult(resp, err: err)
            completion(task, result)
        }
    }
    
    func request<T>(_ request: Request, completion: @escaping (_ result: Result<T, Error>) -> Void) where T: Codable {
        self.request(request) { _, resp, err in
            let result: Result<T, Error> = self.getCodableResult(resp, err: err)
            completion(result)
        }
    }
    
    func request(_ request: Request, completion: @escaping (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void) {
        do {
            try self.makeRequest(request, completion: completion)
        } catch {
            completion(nil, nil, error as NSError)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func makeRequest(_ request: Request, refreshTokenIfNeeded: Bool = true, completion: @escaping (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void) throws {
        let accessToken: String = request.authCredential?.accessToken ?? ""
        
        if request.isAuth && accessToken.isEmpty {
            #if DEBUG
            print("   Endpoint /\(request.path) requires authentication, requesting credential from the delegate = \(self.authDelegate != nil)")
            #endif
            
            if refreshTokenIfNeeded, let delegate = self.authDelegate {
                delegate.refreshSession { newCredential, err in
                    self.processRefreshedCredential(request: request, newCredential: newCredential, error: err, completion: completion)
                }
            } else {
                let error = NSError.protonMailError(401,
                                                    localizedDescription: "The request failed, invalid access token.",
                                                    localizedFailureReason: "The request failed, invalid access token.",
                                                    localizedRecoverySuggestion: nil)
                completion(nil, nil, error)
            }
            return
        }
        
        #if DEBUG
        print(" Loading endpoint /\(request.path)")
        #endif
        
        let url: String = self.getApiUrl(path: request.path)
        let urlRequest: NSMutableURLRequest = try self.sessionManager.requestSerializer.request(withMethod: request.method.toString(),
                                                                                                urlString: url,
                                                                                                parameters: request.parameters)
        
        var headers = request.headers
        headers[HTTPHeader.apiVersion] = request.version
        
        // Set headers
        for (k, v) in headers {
            urlRequest.setValue("\(v)", forHTTPHeaderField: k)
        }
        
        // Set auth
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // Set session id
        if let userid = request.authCredential?.sessionID {
            urlRequest.setValue(userid, forHTTPHeaderField: "x-pm-uid")
        }
        
        // App version
        let appversion: String = "iOS_1.15.3"
        urlRequest.setValue(appversion, forHTTPHeaderField: "x-pm-appversion")
        
        urlRequest.setValue("application/vnd.protonmail.v1+json", forHTTPHeaderField: "Accept")
        
        // User agent
        let ua: String = "ProtonMail/1.15.3 (iOS/14.5 iPhone11,2)"
        urlRequest.setValue(ua, forHTTPHeaderField: "User-Agent")
        
        var task: URLSessionDataTask?
        task = self.sessionManager.dataTask(with: urlRequest as URLRequest, uploadProgress: { (_) in
            // Ignored
        }, downloadProgress: { (_) in
            // Ignored
        }, completionHandler: { (urlresponse, res, error) in
            if let urlres = urlresponse as? HTTPURLResponse,
               let allheader = urlres.allHeaderFields as? [String: Any] {
                if let strData = allheader["Date"] as? String {
                    // Create dateFormatter with UTC time format
                    let dateFormatter = DateFormatter()
                    dateFormatter.calendar = .some(.init(identifier: .gregorian))
                    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    if let date = dateFormatter.date(from: strData) {
                        // todo save server time
//                        let timeInterval = date.timeIntervalSince1970
//                        self.serviceDelegate?.onUpdate(serverTime: Int64(timeInterval))
                    }
                }
            }
            
            // Not using DoH to attempt to handle an error
            
            self.processResponse(forRequest: request, task: task, rawResponse: res, error: error, completion: completion)
        })
        task?.resume()
    }
    
    private func processRefreshedCredential(request: Request, newCredential: AuthCredential?, error: NSError?, completion: @escaping (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void) {
        if let credential = newCredential {
            // Create a new request with the updated credential
            let reqCopy: Request = request.copyWithCredential(credential)
            do {
                try self.makeRequest(reqCopy, refreshTokenIfNeeded: false, completion: completion)
            } catch {
                completion(nil, nil, error as NSError)
            }
        } else {
            let error: NSError = error ?? NSError.unknownError()
            completion(nil, nil, error)
        }
    }
    
    private func getCodableResult<T>(_ resp: [String: Any]?, err: Error?) -> Result<T, Error> where T: Codable {
        do {
            if let res = resp {
                let responseData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                
                if let error = try? decoder.decode(ErrorResponse.self, from: responseData) {
                    throw NSError(error)
                }
                
                let decodedResponse = try decoder.decode(T.self, from: responseData)
                return .success(decodedResponse)
            }
            
            if let error = err {
                return .failure(error)
            }
            
            return .failure(NSError.badResponse())
        } catch {
            return .failure(error)
        }
    }
    
    //
    // MARK: - Response parsing
    //
    
    private func processResponse(forRequest request: Request, task: URLSessionDataTask?, rawResponse: Any?, error: Error?, completion: @escaping (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void) {
        if let error = error {
            completion(task, nil, error as NSError)
        } else if let json = rawResponse as? [String: Any] {
            // Check if the response contains an error code
            if let error = self.parseResponse(json: json, authenticated: request.isAuth) {
                completion(task, nil, error)
            }
            // All good
            else {
                completion(task, json, nil)
            }
        } else {
            completion(task, nil, NSError(domain: "unable to parse response", code: 0, userInfo: nil))
        }
    }
    
    private func parseResponse(json: [String: Any], authenticated: Bool) -> NSError? {
        guard let responseCode = json["Code"] as? Int else {
            return NSError(domain: "unable to parse response", code: 0, userInfo: nil)
        }
        
        var error: NSError?
        if responseCode != 1000 && responseCode != 1001 {
            let errorMessage: String = (json["Error"] as? String) ?? "Unknown error"
            error = NSError.protonMailError(responseCode,
                                            localizedDescription: errorMessage,
                                            localizedFailureReason: errorMessage,
                                            localizedRecoverySuggestion: nil)
        }
        
        if authenticated && responseCode == 401 {
            self.authDelegate?.sessionDidRevoke()
        } else if responseCode == APIErrorCode.humanVerificationRequired {
            // todo implement human verification
            fatalError("Human verification unsupported")
        } else if responseCode == APIErrorCode.badAppVersion || responseCode == APIErrorCode.badApiVersion {
            // todo implement upgrade handler
            fatalError("Upgrade handler not implemented")
        }
        
        return error
    }
    
}
