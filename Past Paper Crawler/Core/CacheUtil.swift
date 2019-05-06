//
//  CacheUtil.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2019/5/2.
//  Copyright © 2019 吴浩榛. All rights reserved.
//

import Cocoa

private let cacheQueue = DispatchQueue(label: "Cache Protect")

private let memoryCache = NSCache<NSString, NSArray>()

let cacheDirectory = NSHomeDirectory() + "/Library/Caches/" + Bundle.main.bundleIdentifier! + "/Customized/"

private func mapPath(from key: String) -> String {
    return cacheDirectory + key
}

private func cacheToFile<T>(array: [T], for key: String) {
    let nsArray = array as NSArray
    if !nsArray.write(toFile: mapPath(from: key), atomically: true) {
        if array.first is NSObject && array.first is NSCoding {
            let archivedArray = array.map { NSKeyedArchiver.archivedData(withRootObject: $0) }
            let nsArray = archivedArray as NSArray
            nsArray.write(toFile: mapPath(from: key), atomically: true)
        }
    }
}

private func fetchFromFile<T>(for key: String) -> [T]? {
    if let nsArray = NSArray(contentsOfFile: mapPath(from: key)) {
        return nsArray as? [T] ?? {
            if nsArray.firstObject is Data {
                let unarchivedArray = nsArray.map { NSKeyedUnarchiver.unarchiveObject(with: $0 as! Data) }
                return unarchivedArray as? [T]
            }
            return nil
        }()
    }
    return nil
}

private func removeFile(for key: String) {
    try? PCFileManager.removeItem(atPath: mapPath(from: key))
}

var diskCachedKeys: [String] {
    var ret: [String] = []
    cacheQueue.sync {
        if let content = try? PCFileManager.contentsOfDirectory(atPath: cacheDirectory) {
            ret = content.filter { !$0.hasPrefix(".") }
        }
    }
    return ret
}

func cacheArray<T>(array: [T], for key: String) {
    cacheQueue.sync {
        let nsArray = NSArray(array: array)
        let nsKey = NSString(string: key)
        memoryCache.setObject(nsArray, forKey: nsKey)  // fast volatile
        if PFCacheToDisk {
            cacheToFile(array: array, for: key)  // slow, involatile
        }
    }
}

func fetchArray<T>(for key: String) -> [T]? {
    var ret: [T]?
    cacheQueue.sync {
        let nsKey = NSString(string: key)
        ret = memoryCache.object(forKey: nsKey) as? [T]
        if ret != nil {
            if PFCacheToDisk && !PCFileManager.fileExists(atPath: mapPath(from: key)) {
                cacheToFile(array: ret!, for: key)
            }
            return
        }
        ret = fetchFromFile(for: key)
        if ret != nil {
            let nsArray = ret! as NSArray
            memoryCache.setObject(nsArray, forKey: nsKey)
        }
    }
    return ret
}

func removeArray(for key: String) {
    cacheQueue.sync {
        let nsKey = NSString(string: key)
        memoryCache.removeObject(forKey: nsKey)
        removeFile(for: key)
    }
}

private var arrayLoadQueues: [String: DispatchQueue] = [:]
private let arrayLoadQueuesQueue = DispatchQueue(label: "Array Load Queues Protect")

func smartProcessArray<T>(for key: String, loadFunc: () -> [T]?) -> [T]? {
    var ret: [T]?
    var loadQueue: DispatchQueue?
    arrayLoadQueuesQueue.sync {
        if arrayLoadQueues[key] == nil {
            arrayLoadQueues[key] = DispatchQueue(label: key + " Protect")
        }
        loadQueue = arrayLoadQueues[key]
    }
    loadQueue!.sync {
        ret = fetchArray(for: key)
        if ret != nil { return }
        ret = loadFunc()
        if ret != nil {
            cacheArray(array: ret!, for: key)
        }
    }
    return ret
}
