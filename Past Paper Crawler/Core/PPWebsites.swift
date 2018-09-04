//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

func bondString(_ s: String) -> String {
    var final: String = ""
    let changeDict: [String: String] = [
        " ": "%20",
        "(": "%28",
        ")": "%29"
    ]
    var char: String
    
    for c in s{
        char = String(c)
        for key in changeDict.keys{
            if char == key{
                char = changeDict[key]!
                break
            }
        }
        final += char
    }
    return final
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
        var allPapers: [String] = Array()
        
        let lv1SpecifiedUrl = bondString(root + level_site[level]! + subject + "/")
        let lv1f = getContentList(url: lv1SpecifiedUrl, nameTag: "<li data-name=", criteria: { name in name != ".." })
        
        let group = DispatchGroup()
        for folder in lv1f{
            group.enter()
            DispatchQueue.global().async {
                let lv2SpecifiedUrl = bondString(lv1SpecifiedUrl + folder + "/")
                for paper in getContentList(url: lv2SpecifiedUrl, nameTag: "<li data-name=", criteria: { name in name.contains(".pdf") }){
                    allPapers.append(paper)
                }
                print("Completed: \(folder)")
                group.leave()
            }
        }
        
        group.wait()
        return allPapers
    }
    
    func downloadPapers(level: String, subject: String, specifiedPapers: [String], toPath: String) {
        // todo implement download action
    }
    
}
