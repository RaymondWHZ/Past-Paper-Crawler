//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

class WebFile {
    let name: String
    let fullUrl: URL
    
    init(url: String) {
        var index = url.index(before: url.endIndex)
        while url[index] != "/" {
            index = url.index(before: index)
        }
        
        name = String(url[url.index(after: index)...])
        fullUrl = URL(string: url)!
    }
    
    func download(to path: String) {
        let data = NSData(contentsOf: fullUrl)!
        var p = path
        if p.last != "/" {
            p += "/"
        }
        data.write(toFile: p + name, atomically: true)
    }
}

protocol PastPaperWebsite {
    
    func getLevels() -> [String]
    
    func getSubjects(level: String) -> [String]
    
    func getPapers(level: String, subject: String) -> [WebFile]
    
    func downloadPapers(specifiedPapers: [WebFile], to path: String)
}

class PapaCambridge: PastPaperWebsite {
    
    private let root = "https://pastpapers.papacambridge.com/?dir=Cambridge%20International%20Examinations%20%28CIE%29/"
    private let fileRoot = "https://pastpapers.papacambridge.com/Cambridge%20International%20Examinations%20(CIE)/"
    
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
    
    func getPapers(level: String, subject: String) -> [WebFile] {
        var allPapers: [WebFile] = []
        
        let seasonsUrl = root + level_site[level]! + bond(subject) + "/"
        let seasons = getContentList(url: seasonsUrl, nameTag: "<li data-name=", criteria: { name in name != ".." })
        
        let fileSeasonsUrl = fileRoot + level_site[level]! + bond(subject, by: [" ": "%20"]) + "/"
        
        let group = DispatchGroup()
        for season in seasons{
            group.enter()
            DispatchQueue.global().async {
                let papersUrl = seasonsUrl + bond(season) + "/"
                let papers = getContentList(url: papersUrl, nameTag: "<li data-name=", criteria: { name in name.contains(".pdf") })
                
                let filePapersUrl = fileSeasonsUrl + bond(season, by: [" ": "%20"]) + "/"
                
                for paper in papers{
                    let paperUrl = filePapersUrl + paper
                    allPapers.append(WebFile(url: paperUrl))
                }
                group.leave()
            }
        }
        
        group.wait()
        return allPapers
    }
    
    func downloadPapers(specifiedPapers: [WebFile], to path: String) {
        let group = DispatchGroup()
        for paper in specifiedPapers{
            group.enter()
            DispatchQueue.global().async {
                paper.download(to: path)
                group.leave()
            }
        }
        group.wait()
    }
    
}
