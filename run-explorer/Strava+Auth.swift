//
//  Strava+Auth.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/5/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import WebKit

struct TokenResponse: Decodable {
    var tokenType: String
    var expiresAt: Int
    var refreshToken: String
    var accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
    }
}

extension Strava {
    internal var accessToken: String? {
        get {
            return userDefaults.string(forKey: "StravaAccessTokenKey")
        }
        set {
            //            print("Saving access token \(newValue)")
            userDefaults.set(newValue, forKey: "StravaAccessTokenKey")
        }
    }
    internal var refreshToken: String? {
        get {
            return userDefaults.string(forKey: "StravaRefreshTokenKey")
        }
        set {
            //            print("Saving refresh token \(newValue)")
            userDefaults.set(newValue, forKey: "StravaRefreshTokenKey")
        }
    }
    internal var accessTokenExpiresAt: Date? {
        get {
            return userDefaults.object(forKey: "StravaTokenExpiresAtKey") as? Date
        }
        set {
            //            print("Saving access token \(newValue)")
            userDefaults.set(newValue, forKey: "StravaTokenExpiresAtKey")
        }
    }
    
    func auth() {
        if let accessTokenExpiresAt = accessTokenExpiresAt, accessToken != nil && accessTokenExpiresAt > Date() {
            print("Valid Access token found (expires at \(accessTokenExpiresAt))")
            return                                  // nothing else to do
        } else if refreshToken != nil {
            fetchAuthToken(code: nil)               // fetch access token using refresh token
            return
        }
        
        // if neither is available, open browser window for full OAuth
        createAuthWindow()
    }
    
    // if code is nil, will use refresh token to get new access token
    func fetchAuthToken(code: String?) {
        var components = Endpoint.token.asUrlComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "client_secret", value: clientSecret),
        ]
        
        if let code = code {
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                ])
        } else if let refreshToken = refreshToken {
            components.queryItems?.append(contentsOf: [
                URLQueryItem(name: "refresh_token", value: refreshToken),
                URLQueryItem(name: "grant_type", value: "refresh_token"),
                ])
        } else {
            print("No code or refresh token available")
            return
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        urlSession.dataTask(with: request) { [weak self] (result: Result<(URLResponse, Data), Error>) in
            switch result {
            case .success(_, let data):
                do {
                    let response = try JSONDecoder().decode(TokenResponse.self, from: data)
                    self?.accessToken = response.accessToken
                    self?.refreshToken = response.refreshToken
                    self?.accessTokenExpiresAt = Date(timeIntervalSince1970: TimeInterval(response.expiresAt))
                    // TODO: persist both tokens
                    print("Access token: \(response.accessToken)")
                    print("Refresh token: \(response.refreshToken)")
                    print("Expires at \(response.expiresAt) - \(self!.accessTokenExpiresAt!)")
                } catch {
                    print("Failed to get token: \(error)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
            }.resume()
    }
    
    func createAuthWindow() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 300, height: 600), configuration: config)
        
        authWindow = NSWindow(contentRect: webView.frame, styleMask: [.closable, .titled, .resizable], backing: .buffered, defer: false)
        authWindow.contentView = webView
        authWindow.title = "Strava"
        authWindow.center()
        
        authWindow.makeKeyAndOrderFront(nil)
        
        var components = Endpoint.auth.asUrlComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: "http://run-explorer"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:read"),
        ]
        
        webView.navigationDelegate = self
        webView.load(URLRequest(url: components.url!))
    }
    
    func closeAuthWindow() {
        authWindow.close()
    }
}
