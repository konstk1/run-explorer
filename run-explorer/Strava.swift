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
        case activities = "https://www.strava.com/api/v3/athlete/activities"
        
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
