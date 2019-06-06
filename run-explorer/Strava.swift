//
//  Strava.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/1/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import WebKit

final class Strava: NSObject {
    internal let clientId: String
    internal let clientSecret: String
    internal let callbackUrl: String
    
    internal var authWindow: NSWindow!
    internal var webView: WKWebView!
    
    internal let userDefaults = UserDefaults.standard
    
    internal let urlSession = URLSession(configuration: .default)
    
    internal enum Endpoint: String {
        case auth = "https://www.strava.com/oauth/authorize"
        case token = "https://www.strava.com/oauth/token"
        case activityList = "https://www.strava.com/api/v3/athlete/activities"
        case activities = "https://www.strava.com/api/v3/activities/"
        
        func stream(for activityId: Int) -> URLComponents {
            var url = self.asUrl()
            url.appendPathComponent(String(activityId))
            url.appendPathComponent("streams")
            return URLComponents(url: url, resolvingAgainstBaseURL: false)!
        }
        
        func asUrl() -> URL {
            return URL(string: self.rawValue)!
        }
        
        func asUrlComponents() -> URLComponents {
            return URLComponents(string: self.rawValue)!
        }
    }
    
    override init() {
        guard let secrets = getPlist(named: "Secrets"),
              let clientId = secrets["StravaClientId"],
              let clientSecret = secrets["StravaClientSecret"],
              let callbackUrl = secrets["StravaCallbackUrl"] else {
            fatalError("Failed to get plit or all strava secrets")
        }

        self.clientId = clientId
        self.clientSecret = clientSecret
        self.callbackUrl = callbackUrl
        
        super.init()
    }
    
    func printRateLimitInfo(response: HTTPURLResponse?) {
        guard let response = response else {
            print("Invalid response")
            return
        }
        
        guard let limit = response.allHeaderFields["x-ratelimit-limit"] as? String,
            let usage = response.allHeaderFields["x-ratelimit-usage"] as? String else {
                print("No x-ratelimit-limit/x-ratelimit-usage headers")
                return
        }
        
        let limits = limit.split(separator: ",").map { Int($0) ?? 0 }
        let usages = usage.split(separator: ",").map { Int($0) ?? 0 }
        
        print("Usage 15-min \(usages[0])/\(limits[0]) | daily \(usages[1])/\(limits[1])")
    }
}

extension Strava: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed nav: \(error)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if(navigationAction.navigationType == .formSubmitted) {
            if let url = navigationAction.request.url, url.absoluteString.starts(with: "http://run-explorer") {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let code = components.queryItems?.first(where: { $0.name == "code"})?.value {
                    fetchAuthToken(code: code)
                }
                closeAuthWindow()
                decisionHandler(.cancel)
                return;
            }
        }
        
        decisionHandler(.allow)
    }
}
