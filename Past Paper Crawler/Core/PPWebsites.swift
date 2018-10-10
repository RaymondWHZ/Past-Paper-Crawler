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
    
    private let level_site = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "AS%20and%20A%20Level/",
        "O-Level": "GCE%20International%20O%20Level/"
    ]
    
    func getLevels() -> [String]? {
        return Array(level_site.keys)
    }
    
    func getSubjects(level: String) -> [String]? {
        let specifiedUrl = root + level_site[level]!
        return getContentList(url: specifiedUrl, nameTag: "<li data-name=", criteria: { name in name != ".." })
    }
    
    func getPapers(level: String, subject: String) -> [WebFile]? {
        var allPapers: [WebFile] = []
        
        let seasonsUrl = root + level_site[level]! + bond(subject) + "/"
        guard let seasons = getContentList(url: seasonsUrl, nameTag: "<li data-name=", criteria: { name in name != ".." }) else {
            return nil
        }
        
        let fileSeasonsUrl = fileRoot + level_site[level]! + bond(subject, by: [" ": "%20"]) + "/"
        
        var exception = false
        
        let group = DispatchGroup()
        for season in seasons {
            DispatchQueue.global().async {
                group.enter()
                defer {
                    group.leave()
                }
                
                let papersUrl = seasonsUrl + bond(season) + "/"
                guard let papers = getContentList(url: papersUrl, nameTag: "<li data-name=", criteria: { name in name.contains(".pdf") }) else {
                    exception = true
                    return
                }
                
                let filePapersUrl = fileSeasonsUrl + bond(season, by: [" ": "%20"]) + "/"
                
                for paper in papers{
                    let paperUrl = filePapersUrl + paper
                    allPapers.append(WebFile(url: paperUrl)!)
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
