//
//  Core.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

private var dataCache: [String: Data] = [:]
func readUrl(url: String) -> Data? {
    if let cacheItem = dataCache[url] {
        return cacheItem
    }
    
    print("Read URL: \(url)")
    
    let url = URL(string: url)!
    return try? Data(contentsOf: url)
}

private var contentListCache: [String: [String]] = [:]
func getContentList(url: String, XPath: String, name: String, criteria: (String) -> Bool = { _ in true }) -> [String]? {
    if let cacheItem = contentListCache[url+XPath+name] {
        return cacheItem.filter(criteria)
    }
    
    guard let data = readUrl(url: url) else {
        return nil
    }
    
    let doc = try! HTML(html: data, encoding: .utf8)
    
    let object = doc.xpath(XPath)
    var list: [String] = []
    for node in object {
        list.append(node[name]!)
    }
    
    contentListCache[url+XPath+name] = list
    return list.filter(criteria)
}

let defaultDict: [Character: String] = [
    " ": "%20",
    "&": "%26",
    "(": "%28",
    ")": "%29"
]

func bond(_ s: String, by dict: [Character: String] = defaultDict) -> String {
    var final = ""
    for c in s{
        if dict.keys.contains(c) {
            final += dict[c]!
            continue
        }
        final.append(c)
    }
    return final
}
