//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

class Subject {
    let level: String
    let name: String
    
    init(_ level: String, _ name: String) {
        self.level = level
        self.name = name
    }
}

func bondString(s: String) -> String {
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

class PastPaperWebSite {
    
    func getLevels() -> [String] {
        return []
    }
    
    func getSubjects(level: String) -> [String] {
        return []
    }
    
    func getPapers(level: String, subject: String) -> [String] {
        return []
    }
    
    func downloadPapers(level: String, subject: String, specifiedPapers: [String], toPath: String) {
        
    }
}

class PapaCambridge: PastPaperWebSite {
    
    private let root = "https://pastpapers.papacambridge.com/?dir=Cambridge%20International%20Examinations%20%28CIE%29/"
    
    private let level_site = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "AS%20and%20A%20Level/",
        "O-Level": "GCE%20International%20O%20Level/"
    ]
    
    override func getLevels() -> [String] {
        return Array(level_site.keys)
    }
    
    override func getSubjects(level: String) -> [String] {
        let specifiedUrl = root + level_site[level]!
        return getContentList(url: specifiedUrl, nameTag: "<li data-name=", criteria: { name in name != ".." })
    }
    
    override func getPapers(level: String, subject: String) -> [String] {
        return []
    }
    
    override func downloadPapers(level: String, subject: String, specifiedPapers: [String], toPath: String) {
        
    }
}
