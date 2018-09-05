//
//  FileManager.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

extension String{
    func slice(from: Int, to: Int) -> String {
        
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        
        return String(self[startIndex...endIndex])
    }
}



class ShowProxy {
    
    var currentLevel: String = ""
    var currentSubject: String = ""
    
    private let authoritizedKeys = ["year", "season", "paper", "edition", "type"]
    private var criteriaSummaryCache: Dictionary<String, Set<String>>?
    var criteriaSummary: Dictionary<String, Set<String>> {
        get {
            if criteriaSummaryCache == nil {
                criteriaSummaryCache = [:]
                for key in authoritizedKeys {
                    criteriaSummaryCache![key] = Set()
                }

                for rawPaper in wholeList{
                    let paperInfo = slice(paper: rawPaper.name)
                    for key in authoritizedKeys {
                        criteriaSummaryCache![key]?.insert(paperInfo[key]!)
                    }
                }
            }
            return criteriaSummaryCache!
        }
    }
    
    private var wholeList: [WebFile] = []
    
    // e.g. ["year": "2018", "season": "s"]
    private var currentCriteria: Dictionary<String, String> = [:]
    
    func loadFrom(level: String, subject: String) {
        currentLevel = level
        currentSubject = subject
        wholeList = website.getPapers(level: level, subject: subject)
        
        // all cache must be reloaded
        currentCriteria = [:]
        criteriaSummaryCache = nil
        currentListCache = nil
        showListCache = nil
    }
    
    func setCriterion(name: String, value: String) {
        currentCriteria[name] = value
        
        // show lists must be reloaded
        currentListCache = nil
        showListCache = nil
    }
    
    func removeCriterion(name: String) {
        currentCriteria.removeValue(forKey: name)
        
        // show lists must be reloaded
        currentListCache = nil
        showListCache = nil
    }
    
    //"0478_s18_ms_11.pdf"
    private func slice(paper: String) -> [String: String]{
        guard paper.count == 18 else{
            return["year": "xx", "season": "x", "paper": "x", "edition": "x", "type": "xx"]
        }
        let cYear: String = paper.slice(from: 6, to: 7)
        let cSeason: String = paper.slice(from: 5, to: 5)
        let cPaper: String = paper.slice(from: 12, to: 12)
        let cEdition: String = paper.slice(from: 13, to: 13)
        let cType: String = paper.slice(from: 9, to: 10)
        
        return["year": cYear, "season": cSeason, "paper": cPaper, "edition": cEdition, "type": cType]
    }
    
    private var currentListCache: [WebFile]?
    var currentList: [WebFile] {
        // filtered list acording to criteria
        get {
            if currentListCache == nil {
                currentListCache = wholeList.filter{
                    (raw) in
                    let paperInfo = slice(paper: raw.name)
                    
                    for cri in currentCriteria.keys{
                        if paperInfo[cri] != currentCriteria[cri]{
                            return false
                        }
                    }
                    return true
                }
            }
            return currentListCache!
        }
    }
    
    private var showListCache: [String]?
    var currentShowList: [String] {
        get {
            if showListCache == nil {
                showListCache = []
                for webFile in currentList {
                    showListCache!.append(webFile.name)
                }
            }
            
            return showListCache!
        }
    }
    
    func downloadPapers(at indices: [Int]) {
        var papers: [WebFile] = []
        for index in indices {
            papers.append(currentList[index])
        }
        downloadProxy.downloadPapers(specifiedPapers: papers)
    }
}

class PapersWithAnswer: ShowProxy {
    
}
