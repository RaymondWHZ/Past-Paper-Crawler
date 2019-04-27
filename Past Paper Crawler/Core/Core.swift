//
//  Core.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

func readUrl(url: String) -> Data? {
    print("Read URL: \(url)")
    
    guard let url = URL(string: url) else {
        return nil
    }
    
    return try? Data(contentsOf: url)
}

func getContentList(url: String, XPath: String, name: String?, criteria: (String) -> Bool = { _ in true }) -> [String]? {
    guard let url_t = URL(string: url), let doc = try? HTML(url: url_t, encoding: .utf8) else {
        return nil
    }
    
    let object = doc.xpath(XPath)
    var list: [String] = []
    if name == nil {
        for node in object {
            if let content = node.content {
                list.append(content)
            }
        }
    }
    else {
        for node in object {
            if let attibute = node[name!] {
                list.append(attibute)
            }
        }
    }
    
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
