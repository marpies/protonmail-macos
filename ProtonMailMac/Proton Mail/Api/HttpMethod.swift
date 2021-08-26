public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    
    func toString() -> String {
        return self.rawValue
    }
}
