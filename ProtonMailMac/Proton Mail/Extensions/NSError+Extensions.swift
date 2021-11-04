import Foundation

public extension NSError {
    
    static var cancelledErrorCode: Int {
        return -3
    }
    
    var isBadVersionError: Bool {
        return self.code == APIErrorCode.badAppVersion || self.code == APIErrorCode.badApiVersion
    }
    
    convenience init(_ serverError: ErrorResponse) {
        let userInfo = [NSLocalizedDescriptionKey: serverError.error,
                        NSLocalizedFailureReasonErrorKey: serverError.errorDescription]
        
        self.init(domain: "PMAuthentication", code: serverError.code, userInfo: userInfo)
    }
    
    convenience init(domain: String, code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) {
        var userInfo = [NSLocalizedDescriptionKey : localizedDescription]
        
        if let localizedFailureReason = localizedFailureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = localizedFailureReason
        }
        
        if let localizedRecoverySuggestion = localizedRecoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = localizedRecoverySuggestion
        }
        
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    class func badResponse() -> NSError {
        return apiServiceError(
            code: APIErrorCode.badResponse,
            localizedDescription: NSLocalizedString("Bad response", comment: "Error Description"),
            localizedFailureReason: NSLocalizedString("Can't find the value from the response body", comment: "Description"))
    }
    
    class func protonMailError(_ code: Int, localizedDescription: String, localizedFailureReason: String? = nil, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(domain: protonMailErrorDomain(), code: code, localizedDescription: localizedDescription, localizedFailureReason: localizedFailureReason, localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func protonMailErrorDomain(_ subdomain: String? = nil) -> String {
        var domain = Bundle.main.bundleIdentifier ?? "ch.protonmail"
        
        if let subdomain = subdomain {
            domain += ".\(subdomain)"
        }
        return domain
    }
    
    func getCode() -> Int {
        var defaultCode : Int = code;
        if defaultCode == Int.max {
            if let detail = self.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                defaultCode = detail.statusCode
            }
        }
        return defaultCode
    }
    
    class func unknownError() -> NSError {
        return apiServiceError(
            code: -1,
            localizedDescription: NSLocalizedString("Unknown Error", comment: "Error"),
            localizedFailureReason: NSLocalizedString("Unknown Error", comment: "Error"))
    }
    
    class func cancelledError() -> NSError {
        return apiServiceError(
            code: NSError.cancelledErrorCode,
            localizedDescription: "",
            localizedFailureReason: "")
    }
    
    func isInternetError() -> Bool {
        var isInternetIssue = false
        if let _ = self.userInfo ["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
        } else {
            //                        if(error?.code == -1001) {
            //                            // request timed out
            //                        }
            if self.code == -1009 || self.code == -1004 || self.code == -1001 { //internet issue
                isInternetIssue = true
            }
        }
        return isInternetIssue
    }
    
    class func apiServiceError(code: Int, localizedDescription: String, localizedFailureReason: String?, localizedRecoverySuggestion: String? = nil) -> NSError {
        return NSError(
            domain: "APIService",
            code: code,
            localizedDescription: localizedDescription,
            localizedFailureReason: localizedFailureReason,
            localizedRecoverySuggestion: localizedRecoverySuggestion)
    }
    
    class func userLoggedOut() -> NSError {
        return apiServiceError(code: 9999,
                               localizedDescription: NSLocalizedString("Sender account has been logged out!", comment: ""),
                               localizedFailureReason: NSLocalizedString("Sender account has been logged out!", comment: ""))
    }
    
}
