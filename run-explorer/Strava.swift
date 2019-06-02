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
    fileprivate let clientId: String
    fileprivate let clientSecret: String
    fileprivate let callbackUrl: String
    
    fileprivate var token: String?
    fileprivate var refreshToken: String?
    
    fileprivate var webView: WKWebView!
    
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
    
    func auth(vc: NSViewController) {
//        let storyboard = NSStoryboard(name: "Main", bundle: nil)
//        let webVc = storyboard.instantiateController(withIdentifier: "webview") as! NSViewController
//        vc.presentAsModalWindow(webVc)
//
//        webView = webVc.view.subviews[0] as? WKWebView
//        webView.navigationDelegate = self
//
//        let authUrl = "https://www.strava.com/oauth/authorize"
//        var components = URLComponents(string: authUrl)!
//        components.queryItems = [
//            URLQueryItem(name: "client_id", value: clientId),
//            URLQueryItem(name: "redirect_uri", value: "http://run-explorer"),
//            URLQueryItem(name: "response_type", value: "code"),
//            URLQueryItem(name: "approval_prompt", value: "auto"),
//            URLQueryItem(name: "scope", value: "activity:read"),
//        ]
//
////        print(components.url)
//        webView.load(URLRequest(url: components.url!))
        createAuthWindow()
    }
    
    func createAuthWindow() {
        print("Making window")
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 300, height: 600))
        let window = NSWindow(contentRect: webView.frame, styleMask: [.closable], backing: .buffered, defer: false)
        window.contentView = webView
        window.center()
        
        let vc = NSWindowController(window: window)
        vc.showWindow(nil)
//        window.makeKeyAndOrderFront(nil)
    }
}

extension Strava: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed nav: \(error)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed provisional: \(error)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("policy for action")
        if(navigationAction.navigationType == .formSubmitted) {
            print(navigationAction.request.url!)
            if let url = navigationAction.request.url,
                url.absoluteString.starts(with: "http://run-explorer") {
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("Redirect to: \(webView.url!)")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Started nav")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("Did commit")
    }
}
