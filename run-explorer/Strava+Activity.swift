//
//  Strava+Activity.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/5/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import CoreLocation

struct Activity: Decodable {
    var id: Int
    var startDate: String
    var type: String
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case startDate = "start_date"
        case type = "type"
    }
}

struct ActivityStream {
    var activityId: Int
    var startDate: Date
    var coords: [CLLocationCoordinate2D]
}

extension Strava {
    func getActivities(after: Date? = nil, before: Date? = nil, page: Int? = nil, perPage: Int? = nil, completion: ((Result<Int, Error>) -> Void)? = nil) {
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

        print("Fetching activities after: \(after!) (\(String(Int(after!.timeIntervalSince1970)))")
        
        urlSession.dataTask(with: request) { [unowned self] (result) in
            switch result {
            case .success((_, let data)):
                do {
                    let activities = try JSONDecoder().decode([Activity].self, from: data)
                    print("Got \(activities.count) activities")
                    activities.forEach { activity in
                        // only keep run activities
                        guard activity.type == "Run" else {
                            print("Ignoring activity (\(activity.id)) type \(activity.type)")
                            return
                        }

                        self.getActivityStream(forActivity: activity.id) { stream in
                            print("Saving activity \(activity.id)")
                            let date = activity.startDate.split(separator: "T").first ?? "null"
                            let fileName = "\(self.dataDir)\(date) - \(activity.id).txt"
                            try! stream.write(toFile: fileName, atomically: true, encoding: .utf8)
                        }
                    }
                    completion?(.success(activities.count))
                } catch {
                    print("Failed decode: \(error)")
                    completion?(.failure(error))
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
            case .success((let response, let data)):
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
    
    func loadStreamsFromDisk() -> [ActivityStream]? {
        let fileMgr = FileManager.default
        
        do {
            let fileNames = try fileMgr.contentsOfDirectory(atPath: dataDir)
            let streams = fileNames.compactMap { (fileName) -> ActivityStream? in
                if !fileName.hasSuffix(".txt") {
                    print("Unsupported file type: \(fileName)")
                    return nil
                }

                let url = URL(fileURLWithPath: dataDir).appendingPathComponent(fileName)

                let data: String
                do {
                    data = try String(contentsOf: url)
                } catch {
                    print("Failed to get data from url: \(error)")
                    return nil
                }
                
                let coords = data.components(separatedBy: .newlines).map { (line) -> CLLocationCoordinate2D in
                    let latlon = line.split(separator: ",").map { Double(String($0).trimmingCharacters(in: .whitespaces))! }
                    return CLLocationCoordinate2D(latitude: latlon[0], longitude: latlon[1])
                }
                
                let comps = fileName.components(separatedBy: CharacterSet(charactersIn: " -.")).filter { !$0.isEmpty }
                
                guard comps.count == 5 else {
                    print("Badly formatted file name (expected 5 components, got \(comps.count)): \(fileName)")
                    return nil
                }
                
                let year = Int(comps[0]) ?? 0
                let month = Int(comps[1]) ?? 0
                let day = Int(comps[2]) ?? 0
                let activityId = Int(comps[3]) ?? 0
                
                let calendar = Calendar(identifier: .gregorian)
                let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
                
//                print("Processed \(fileName) with \(coords.count) points \(date)")
                
                return ActivityStream(activityId: activityId, startDate: date, coords: coords)
            }
            
            return streams
        } catch {
            print("Failed to fetch data dir contents: \(error)")
            return nil
        }
    }
    
    
}

