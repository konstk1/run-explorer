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

//struct ActivityStream: Decodable {
//    var type: String
//    var data:
//}

extension Strava {
    func getActivities(after: Date? = nil, before: Date? = nil, page: Int? = nil, perPage: Int? = nil) {
        var components = Endpoint.activityList.asUrlComponents()
        components.queryItems = Array<URLQueryItem>()
        
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
        
        urlSession.dataTask(with: request) { [unowned self] (result) in
            switch result {
            case .success(_, let data):
                do {
                    let activities = try JSONDecoder().decode([Activity].self, from: data)
                    print("Got \(activities.count) activities")
                    activities.forEach { activity in
                        self.getActivityStream(forActivity: activity.id) { stream in
                            print("Saving activity \(activity.id)")
                            let date = activity.startDate.split(separator: "T").first ?? "null"
                            let fileName = "/Users/kon/Developer/run-explorer/data/strava/\(date) - \(activity.id).txt"
                            try! stream.write(toFile: fileName, atomically: true, encoding: .utf8)
                        }
                    }
                } catch {
                    print("Failed decode: \(error)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }.resume()
    }
    
    func getActivityStream(forActivity activityId: Int, completion: @escaping (_ stream: String) -> Void) {
        var components = Endpoint.activities.stream(for: activityId)
        components.queryItems = [
            URLQueryItem(name: "keys", value: "latlng")
        ]
        
        var request = URLRequest(url: components.url!)
        
        if let accessToken = accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession.dataTask(with: request) { [weak self] (result) in
            switch result {
            case .success(let response, let data):
                self?.printRateLimitInfo(response: response as? HTTPURLResponse)
                let json = try! JSONSerialization.jsonObject(with: data) as! [Any]
                json.forEach {
                    guard let stream = $0 as? [String: Any] else { return }
                    if let type = stream["type"] as? String, type == "latlng" {
                        print("Found latlng")
                        guard let latlon = stream["data"] as? [[Double]] else {
                            return
                        }
                        
                        let stream = latlon.map { "\($0[0]), \($0[1])" }.joined(separator: "\n")
                        completion(stream)
                    }
                }
//                print(json)
            case .failure(let error):
                print("Failed decode: \(error)")
            }
        }.resume()
    }
}

