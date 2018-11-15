//
//  Settings.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/11/9.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

let websiteToken = "Website"
let defaultWebsite = "GCE Guide"
let websites: [String: PastPaperWebsite] = [
    "GCE Guide": GCEGuide(),
    "Papa Cambridge": PapaCambridge(),
    "Past Paper.Co": PastPaperCo()
]
var usingWebsite: PastPaperWebsite {
    return websites[usingWebsiteName]!
}
var usingWebsiteName: String {
    get {
        if let website = userDefaults.string(forKey: websiteToken) {
            return website
        }
        else {
            return defaultWebsite
        }
    }
    set {
        userDefaults.set(newValue, forKey: websiteToken)
    }
}

let defaultShowAllToken = "Show Mode"
var defaultShowProxy: ShowProxy {
    get {
        return PapersWithAnswer()
    }
}
var defaultShowAll: Bool {
    get {
        return userDefaults.bool(forKey: defaultShowAllToken)
    }
    set {
        userDefaults.set(newValue, forKey: defaultShowAllToken)
    }
}

let useDefualtPathToken = "Use Default Path"
private let defaultPathProxy = DefaultPathProxy()
private let askUserProxy = AskUserProxy()
var downloadProxy: DownloadProxy {
    get {
        return (useDefaultPath) ? defaultPathProxy : askUserProxy
    }
}
var useDefaultPath: Bool {
    get {
        return userDefaults.bool(forKey: useDefualtPathToken)
    }
    set {
        userDefaults.set(newValue, forKey: useDefualtPathToken)
    }
}

var defaultPathToken = "Default Path"
var defaultPath: String {
    get {
        if let path = userDefaults.string(forKey: defaultPathToken) {
            return path
        }
        else {
            return ""
        }
    }
    set {
        userDefaults.set(newValue, forKey: defaultPathToken)
    }
}

let quickListToken = "Quick List"
let quickListChangeEvent = Event()
let quickListWriteQueue = DispatchQueue(label: "Quick List Write Protect")
var quickList: [[String: String]] {
    get {
        if let list = userDefaults.array(forKey: quickListToken) as? [[String: String]] {
            return list
        }
        else {
            return []
        }
    }
    set {
        quickListWriteQueue.async {
            userDefaults.set(newValue, forKey: quickListToken)
            quickListChangeEvent.performAll()
        }
    }
}

let createFolderToken = "Create Folder"
var createFolder: Bool {
    get {
        return userDefaults.bool(forKey: createFolderToken)
    }
    set {
        userDefaults.set(newValue, forKey: createFolderToken)
    }
}
