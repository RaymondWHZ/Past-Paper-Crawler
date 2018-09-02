//
//  AppDelegate.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

let notificationCenter = NotificationCenter.default
let userDefaults = UserDefaults.standard

var exitEvents = Event()

let quickListToken = "Quick List"
private var _quickList: [Dictionary<String, String>]? = nil
var quickList: [Dictionary<String, String>] {
    get {
        if _quickList == nil {
            if let list = userDefaults.array(forKey: quickListToken) as? [Dictionary<String, String>] {
                _quickList = list
            }
            else {
                _quickList = []
            }
            exitEvents.addAction(Action{
                userDefaults.set(_quickList, forKey: quickListToken)
            })
        }
        return _quickList!
    }
    set {
        _quickList = newValue
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        exitEvents.performAll()
    }
}
