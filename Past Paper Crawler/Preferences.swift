//
//  Settings.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/11/9.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

// Website part

let PFWebsiteToken = "Website"
private let defaultWebsite = "GCE Guide"
var PFUsingWebsite: PastPaperWebsite {
    return allPastPaperWebsites[PFUsingWebsiteName]!
}
var PFUsingWebsiteName: String {
    get {
        if let website = userDefaults.string(forKey: PFWebsiteToken) {
            return website
        }
        else {
            return defaultWebsite
        }
    }
    set {
        userDefaults.set(newValue, forKey: PFWebsiteToken)
    }
}

// Show mode part

let PFDefaultShowAllToken = "Show Mode"
var PFDefaultShowAll: Bool {
    get {
        return userDefaults.bool(forKey: PFDefaultShowAllToken)
    }
    set {
        userDefaults.set(newValue, forKey: PFDefaultShowAllToken)
    }
}

// Default path part

let PFUseDefualtPathToken = "Use Default Path"
var PFUseDefaultPath: Bool {
    get {
        return userDefaults.bool(forKey: PFUseDefualtPathToken)
    }
    set {
        userDefaults.set(newValue, forKey: PFUseDefualtPathToken)
    }
}

let PFDefaultPathToken = "Default Path"
var PFDefaultPath: String {
    get {
        if let path = userDefaults.string(forKey: PFDefaultPathToken) {
            return path
        }
        else {
            return ""
        }
    }
    set {
        userDefaults.set(newValue, forKey: PFDefaultPathToken)
    }
}

// Open in Finder part

let PFOpenInFinderToken = "Open in Finder"
var PFOpenInFinder: Bool {
    get {
        return userDefaults.bool(forKey: PFOpenInFinderToken)
    }
    set {
        userDefaults.set(newValue, forKey: PFOpenInFinderToken)
    }
}

// Quick list part. Design note: Direct access to quick list object is forbiden. It can only be accessed through PFUseQuickList and PFModifyQuickList

typealias QuickList = [Subject]

let PFQuickListToken = "Quick List"
private var quickList: QuickList = {
    if
        let rawArray = userDefaults.array(forKey: PFQuickListToken) as? [Data],
        let array = rawArray.map({ NSKeyedUnarchiver.unarchiveObject(with: $0) }) as? [Subject]
    {
        return array
    }
    return []
}()
private let quickListQueue = DispatchQueue(label: "Quick List Protect")

var PFQuickListCount: Int {
    return quickList.count
}

func PFUseQuickList(_ action: (QuickList) -> ()) {
    quickListQueue.sync {
        action(quickList)
    }
}

private let quickListChangedName = NSNotification.Name(rawValue: "Quick List Changed")
func PFModifyQuickList(_ action: (inout QuickList) -> ()) {
    quickListQueue.sync {
        action(&quickList)
        let rawArray = quickList.map { NSKeyedArchiver.archivedData(withRootObject: $0) }
        userDefaults.set(rawArray, forKey: PFQuickListToken)
    }
    notificationCenter.post(name: quickListChangedName, object: nil)
}

func PFObserveQuickListChange(_ observer: Any, selector: Selector) {
    notificationCenter.addObserver(observer, selector: selector, name: quickListChangedName, object: nil)
}

func PFEndObserve(_ observer: Any) {
    notificationCenter.removeObserver(observer)
}

// Create subfolder part

let PFAvoidDuplicationToken = "Avoid Duplication"
var PFAvoidDuplication: Bool {
    get {
        return !userDefaults.bool(forKey: PFAvoidDuplicationToken)
    }
    set {
        userDefaults.set(!newValue, forKey: PFAvoidDuplicationToken)
    }
}

let PFCreateFolderToken = "Create Folder"
var PFCreateFolder: Bool {
    get {
        return userDefaults.bool(forKey: PFCreateFolderToken)
    }
    set {
        userDefaults.set(newValue, forKey: PFCreateFolderToken)
    }
}

let PFCacheToDiskToken = "Cache To Disk"
var PFCacheToDisk: Bool {
    get {
        return !userDefaults.bool(forKey: PFCacheToDiskToken)
    }
    set {
        userDefaults.set(!newValue, forKey: PFCacheToDiskToken)
    }
}
