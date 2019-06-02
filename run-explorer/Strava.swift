//
//  Strava.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/1/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa

final class Strava {
    
    func auth(vc: NSViewController) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let webview = storyboard.instantiateController(withIdentifier: "webview")
        vc.presentAsModalWindow(webview as! NSViewController)
    }
}
