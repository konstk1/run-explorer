//
//  Strava+Activity.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/5/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

struct Activity: Decodable {
    var id: Int
    var startDate: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case startDate = "start_date"
        
    }
}

extension Strava {
    func getActivities(after: Date? = nil, before: Date? = nil, page: Int? = nil, perPage: Int? = nil) {
        var components = Endpoint.activities.asUrlComponents()
        
        if let after = after {
            components.queryItems?.append(URLQueryItem(name: "after", value: String(Int(after.timeIntervalSince1970))))
        }
        if let before = before {
            components.queryItems?.append(URLQueryItem(name: "before", value: String(Int(before.timeIntervalSince1970))))
        }
        if let page = page {
            components.queryItems?.append(URLQueryItem(name: "page", value: String(page)))
        }
        if let perPage = perPage {
            components.queryItems?.append(URLQueryItem(name: "per_page", value: String(perPage)))
        }
        
        var request = URLRequest(url: components.url!)
        
        if let accessToken = accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession.dataTask(with: request) { (result) in
            switch result {
            case .success(_, let data):
                do {
                    let activities = try JSONDecoder().decode([Activity].self, from: data)
                    print("Got \(activities.count) activities")
                } catch {
                    print("Failed decode: \(error)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }.resume()
    }
}

