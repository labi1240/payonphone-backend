import Foundation
import StripeTerminal

class APIClient: NSObject, ConnectionTokenProvider {
    static let shared = APIClient()
    
    // Replace with your actual backend URL
    private let baseURL = "https://payonphone-backend.onrender.com"
    
    func fetchConnectionToken(_ completion: @escaping ConnectionTokenCompletionBlock) {
        guard let url = URL(string: "\(baseURL)/connection_token") else {
            let error = NSError(domain: "APIClientError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(nil, error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "APIClientError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(nil, error)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let secret = json["secret"] as? String {
                    completion(secret, nil)
                } else {
                    let error = NSError(domain: "APIClientError", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                    completion(nil, error)
                }
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
}