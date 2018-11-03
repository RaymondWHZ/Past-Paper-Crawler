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

let websiteToken = "Website"
let defaultWebsite = "GCE Guide"
let websites: [String: PastPaperWebsite] = [
    "GCE Guide": GCEGuide(),
    "Papa Cambridge": PapaCambridge()
]
var website: PastPaperWebsite {
    var name = userDefaults.string(forKey: websiteToken)
    if name == nil {
        name = defaultWebsite
        userDefaults.set(name, forKey: websiteToken)
    }
    return websites[name!]!
}

let defaultShowAllToken = "Show Mode"
var defaultShowProxy: ShowProxy {
    get {
        return PapersWithAnswer()
    }
}

let useDefualtPathToken = "Use Default Path"
private let defaultPathProxy = DefaultPathProxy()
private let askUserProxy = AskUserProxy()
var downloadProxy: DownloadProxy {
    get {
        let useDefaultPath = userDefaults.bool(forKey: useDefualtPathToken)
        return (useDefaultPath) ? defaultPathProxy : askUserProxy
    }
}

var defaultPathToken: String {
    let token = "Default Path"
    let test = userDefaults.string(forKey: token)
    if test == nil {
        userDefaults.set("", forKey: token)
    }
    return token
}

let createFolderToken = "Create Folder"

var exitEvents = Event()

let quickListToken = "Quick List"
private var _quickList: [[String: String]]? = nil
let quickListChangeEvent = Event()
var quickList: [[String: String]] {
    get {
        if _quickList == nil {
            if let list = userDefaults.array(forKey: quickListToken) as? [[String: String]] {
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
        quickListChangeEvent.performAll()
    }
}
