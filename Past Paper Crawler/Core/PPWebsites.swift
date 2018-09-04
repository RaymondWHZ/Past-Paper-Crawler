//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

func bondString(s: String) -> String {
    // todo implement the function that replaces all spaces into %<number>
    /*
    var ns = ""
    for i in 0...s.count - 1 {
        var cs = &s[s.index(s.startIndex, offsetBy: i)]
        if s[s.index(s.startIndex, offsetBy: i)] == " " {
            s.
        }
    }
     */
    return ""
}

protocol PastPaperWebsite {
    
    func getLevels() -> [String]
    
    func getSubjects(level: String) -> [String]
    
    func getPapers(level: String, subject: String) -> [String]
    
    func downloadPapers(level: String, subject: String, specifiedPapers: [String], toPath: String)
}

class PapaCambridge: PastPaperWebsite {
    
    private let root = "https://pastpapers.papacambridge.com/?dir=Cambridge%20International%20Examinations%20%28CIE%29/"
    
    private let level_site = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "AS%20and%20A%20Level/",
        "O-Level": "GCE%20International%20O%20Level/"
    ]
    
    func getLevels() -> [String] {
        return Array(level_site.keys)
    }
    
    func getSubjects(level: String) -> [String] {
        let specifiedUrl = root + level_site[level]!
        return getContentList(url: specifiedUrl, nameTag: "<li data-name=", criteria: { name in name != ".." })
    }
    
    func getPapers(level: String, subject: String) -> [String] {
        // todo implement get action
        return []
    }
    
    func downloadPapers(level: String, subject: String, specifiedPapers: [String], toPath: String) {
        // todo implement download action
        
    }
}
