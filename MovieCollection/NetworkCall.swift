//
//  NetworkCall.swift
//  MovieCollection
//
//  Created by Christopher Fouts on 5/20/22.
//

import Foundation

class NetworkCall {
    
    func fetchRemoteContent<T: Decodable>(from url:String, completion: @escaping (T) -> ()) {
        
        guard let request = requestFrom(url) else { return }
        
        let configuration  = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let data = data {

                if let model = try? JSONDecoder().decode(T.self, from: data) {
                    
                    completion(model)
                    return
                }
            } else {
                // TODO: add error handling
                print("We didn't get data...")
            }
            
            if let error = error {
                // TODO: add error handling
                print(error.localizedDescription)
            }
            
    //            if let response = response {
    //                dump(response)
    //            }
            
        }.resume()
    }

    private func requestFrom(_ urlString: String) -> URLRequest? {
        
        // build request for URL Session
        guard let url = URL(string: urlString) else {
            // TODO: more error handling
            print("BadURL: \(urlString)")
            return nil
        }

        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.timeoutInterval = 60.0
        
        return request
    }

    
}
