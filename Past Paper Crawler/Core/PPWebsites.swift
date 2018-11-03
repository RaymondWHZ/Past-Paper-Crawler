//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

protocol PastPaperWebsite {
    
    func getLevels() -> [String]?
    
    func getSubjects(level: String) -> [String]?
    
    func getPapers(level: String, subject: String) -> [WebFile]?
}

class PapaCambridge: PastPaperWebsite {
    
    private let root = "https://pastpapers.papacambridge.com/?dir=Cambridge%20International%20Examinations%20%28CIE%29/"
    private let fileRoot = "https://pastpapers.papacambridge.com/Cambridge%20International%20Examinations%20(CIE)/"
    
    private let levelSites = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "AS%20and%20A%20Level/",
        "O-Level": "GCE%20International%20O%20Level/"
    ]
    
    func getLevels() -> [String]? {
        return Array(levelSites.keys)
    }
    
    func getSubjects(level: String) -> [String]? {
        let specifiedUrl = root + levelSites[level]!
        return getContentList(url: specifiedUrl, XPath: "//*[@id=\"directory-listing\"]/li", name: "data-name", criteria: { $0 != ".." })
    }
    
    func getPapers(level: String, subject: String) -> [WebFile]? {
        
        let seasonsUrl = root + levelSites[level]! + bond(subject) + "/"
        guard let seasons = getContentList(url: seasonsUrl, XPath: "//*[@id=\"directory-listing\"]/li", name: "data-name", criteria: { $0 != ".." }) else {
            return nil
        }
        
        let fileSeasonsUrl = fileRoot + levelSites[level]! + bond(subject, by: [" ": "%20"]) + "/"
        
        var allPapers: [WebFile] = []
        let arrayProtect = DispatchQueue(label: "Array Protection")
        
        var exception = false
        
        let group = DispatchGroup()
        for season in seasons {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    group.leave()
                }
                
                let papersUrl = seasonsUrl + bond(season) + "/"
                guard let papers = getContentList(url: papersUrl, XPath: "//*[@id=\"directory-listing\"]/li", name: "data-name", criteria: { name in name.contains(".pdf") }) else {
                    exception = true
                    return
                }
                
                let filePapersUrl = fileSeasonsUrl + bond(season, by: [" ": "%20"]) + "/"
                let newFiles = papers.map({ WebFile(url: filePapersUrl + $0, classification: subject)! })
                arrayProtect.sync {
                    allPapers.append(contentsOf: newFiles)
                }
            }
        }
        group.wait()
        
        if exception {
            return nil
        }
        
        return allPapers.sorted(by: { $0.name.compare($1.name) == ComparisonResult.orderedAscending })
    }
}

class GCEGuide: PastPaperWebsite {
    private let root = "https://papers.gceguide.com/"
    
    private let levelSites = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "A%20Levels/",
        "O-Level": "O%20Levels/"
    ]
    
    func getLevels() -> [String]? {
        return Array(levelSites.keys)
    }
    
    func getSubjects(level: String) -> [String]? {
        let specifiedUrl = root + levelSites[level]!
        return getContentList(url: specifiedUrl, XPath: "//*[@id=\"ggTable\"]/tbody/tr/td/a", name: "href", criteria: { $0 != "error_log" })
    }
    
    func getPapers(level: String, subject: String) -> [WebFile]? {
        let papersUrl = root + levelSites[level]! + bond(subject, by: [" ": "%20"]) + "/"
        guard let papers = getContentList(url: papersUrl, XPath: "//*[@id=\"ggTable\"]/tbody/tr/td/a", name: "href", criteria: { $0.hasSuffix("pdf") }) else {
            return nil
        }
        return papers.map({ WebFile(url: papersUrl + bond($0, by: [" ": "%20"]), classification: subject)! })
    }
}
