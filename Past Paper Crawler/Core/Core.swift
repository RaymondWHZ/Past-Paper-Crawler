//
//  Core.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/26.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

func readUrl(url: String) -> Data {
    let url = URL(string: url)!
    return try! Data(contentsOf: url)
}

func getContentList(url: String, nameTag: String, criteria: (String) -> Bool) -> [String] {
    let data = readUrl(url: url)
    let str = String(data: data, encoding: String.Encoding.utf8)!
    let scanner = Scanner.init(string: str)
    
    var cur: NSString?
    var ret: [String] = []
    while true {
        scanner.scanUpTo(nameTag, into: nil)
        if scanner.isAtEnd {
            return ret
        }
        scanner.scanUpTo("\"", into: nil)
        scanner.scanLocation += 1
        scanner.scanUpTo("\"", into: &cur)
        let s = cur! as String
        if criteria(s) {
            ret.append(String(s))
        }
    }
}

let defaultDict: [Character: String] = [
    " ": "%20",
    "(": "%28",
    ")": "%29"
]

func bond(_ s: String, by dict: Dictionary<Character, String> = defaultDict) -> String {
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
