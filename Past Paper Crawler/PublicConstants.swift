//
//  PublicConstants.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/4.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

let storyboard = NSStoryboard(name: "Main", bundle: nil)
func getController(_ name: String) -> Any {
    let rawValue = storyboard.instantiateController(withIdentifier: name)
    return rawValue
}

let notificationCenter = NotificationCenter.default
let userDefaults = UserDefaults.standard
let fileManager = FileManager.default

let website = PapaCambridge()
let downloadProxy = DirectAccess()
var defaultShowProxy: ShowProxy {
    return PapersWithAnswer()
}

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
