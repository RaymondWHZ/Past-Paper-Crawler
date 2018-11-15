//
//  PPWebsite.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/8/28.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

var arrayLoadQueues: [String: DispatchQueue] = [:]
let arrayCache = NSCache<NSString, NSArray>()
func getArray<T>(identifier: String, loadFunc: () -> [T]?) -> [T]? {
    var ret: [T]?
    let loadQueue = arrayLoadQueues[identifier] ?? {
        let queue = DispatchQueue(label: identifier + " Protect")
        arrayLoadQueues[identifier] = queue
        return queue
    }()
    loadQueue.sync {
        let i = identifier as NSString
        if let array = arrayCache.object(forKey: i) {
            ret = array as? [T]
            return
        }
        if let array = loadFunc() {
            arrayCache.setObject(array as NSArray, forKey: i)
            ret = array
            return
        }
    }
    return ret
}

class PastPaperWebsite {
    
    let root: String
    
    init(root: String) {
        self.root = root
    }
    
    final func getLevels() -> [String]? {
        return getArray(identifier: self.root, loadFunc: getLevels0)
    }
    
    fileprivate func getLevels0() -> [String]? { return nil }
    
    final func getSubjects(level: String) -> [String]? {
        return getArray(identifier: self.root + level, loadFunc: { getSubjects0(level: level) })
    }
    
    fileprivate func getSubjects0(level: String) -> [String]? { return nil }
    
    final func getPapers(level: String, subject: String) -> [WebFile]? {
        return getArray(identifier: self.root + level + subject, loadFunc: { getPapers0(level: level, subject: subject) })
    }
    
    fileprivate func getPapers0(level: String, subject: String) -> [WebFile]? { return nil }
}

class PapaCambridge: PastPaperWebsite {
    
    init() {
        super.init(root: "https://pastpapers.papacambridge.com/?dir=Cambridge%20International%20Examinations%20%28CIE%29/")
    }
    private let fileRoot = "https://pastpapers.papacambridge.com/Cambridge%20International%20Examinations%20(CIE)/"
    
    private let levelSites = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "AS%20and%20A%20Level/",
        "O-Level": "GCE%20International%20O%20Level/"
    ]
    
    override fileprivate func getLevels0() -> [String]? {
        return Array(levelSites.keys)
    }
    
    override fileprivate func getSubjects0(level: String) -> [String]? {
        let specifiedUrl = root + levelSites[level]!
        return getContentList(url: specifiedUrl, XPath: "//*[@id=\"directory-listing\"]/li", name: "data-name", criteria: { $0 != ".." })
    }
    
    override fileprivate func getPapers0(level: String, subject: String) -> [WebFile]? {
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
    
    init() {
        super.init(root: "https://papers.gceguide.com/")
    }
    
    private let levelSites = [
        "IGCSE": "IGCSE/",
        "AS & A-Level": "A%20Levels/",
        "O-Level": "O%20Levels/"
    ]
    
    override fileprivate func getLevels0() -> [String]? {
        return Array(levelSites.keys)
    }
    
    override fileprivate func getSubjects0(level: String) -> [String]? {
        let specifiedUrl = root + levelSites[level]!
        return getContentList(url: specifiedUrl, XPath: "//*[@id=\"ggTable\"]/tbody/tr/td/a", name: "href", criteria: { $0 != "error_log" })
    }
    
    override fileprivate func getPapers0(level: String, subject: String) -> [WebFile]? {
        let papersUrl = root + levelSites[level]! + bond(subject, by: [" ": "%20"]) + "/"
        guard let papers = getContentList(url: papersUrl, XPath: "//*[@id=\"ggTable\"]/tbody/tr/td/a", name: "href", criteria: { $0.hasSuffix("pdf") }) else {
            return nil
        }
        return papers.map({ WebFile(url: papersUrl + bond($0, by: [" ": "%20"]), classification: subject)! })
    }
}

class PastPaperCo: PastPaperWebsite {
    
    init() {
        super.init(root: "https://pastpapers.co")
    }
    private let dirRoot = "https://pastpapers.co/cie/?dir="
    private let fileRoot = "https://pastpapers.co/cie/"
    
    private let levelSites = [
        "IGCSE": "IGCSE",
        "AS & A-Level": "A-Level",
        "O-Level": "O-Level"
    ]
    
    override fileprivate func getLevels0() -> [String]? {
        return Array(levelSites.keys)
    }
    
    override fileprivate func getSubjects0(level: String) -> [String]? {
        let specifiedUrl = dirRoot + levelSites[level]!
        let rawList = getContentList(url: specifiedUrl, XPath: "/html/body/div[5]/div[2]/div/div/table/tbody/tr/td/a/text()", name: nil)
        func filterName(name: String) -> String {
            return name.filter({ (c) -> Bool in
                let isCapital = (c >= "A" && c <= "Z")
                let isSmaller = (c >= "a" && c <= "z")
                let isNumber = (c >= "0" && c <= "9")
                let isDash = (c == "-")
                return isCapital || isSmaller || isNumber || isDash
            })
        }
        return rawList?.map({ filterName(name: $0) })
    }
    
    override fileprivate func getPapers0(level: String, subject: String) -> [WebFile]? {
        let yearsUrl = dirRoot + levelSites[level]! + "%2F" + subject
        guard let years = getContentList(url: yearsUrl, XPath: "/html/body/div[5]/div[2]/div/div/table/tbody/tr/td/a", name: "href") else {
            return nil
        }
        
        let fileYearsUrl = fileRoot + levelSites[level]! + "/" + subject + "/"
        
        var allPapers: [WebFile] = []
        let arrayProtect = DispatchQueue(label: "Array Protection")
        
        var exception = false
        
        let group = DispatchGroup()
        // fetch every year
        for year in years {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    group.leave()
                }
                
                let seasonsUrl = self.root + year
                guard let seasons = getContentList(url: seasonsUrl, XPath: "/html/body/div[5]/div[2]/div/div/table/tbody/tr/td/a", name: "href") else {
                    exception = true
                    return
                }
                
                // fetch every season
                let subGroup = DispatchGroup()
                for season in seasons {
                    subGroup.enter()
                    DispatchQueue.global(qos: .userInitiated).async {
                        defer {
                            subGroup.leave()
                        }
                        
                        let papersUrl = self.root + season
                        guard let papers = getContentList(url: papersUrl, XPath: "/html/body/div[5]/div[3]/div/div/table/tbody/tr/td/a", name: "href") else {
                            exception = true
                            return
                        }
                        
                        let newFiles = papers.map({ (s) -> WebFile in
                            let equalIndex = s.firstIndex(of: "=")!
                            let startIndex = s.index(equalIndex, offsetBy: 1)
                            let urlPart = String(s[startIndex...])
                            let bonded = bond(urlPart)
                            return WebFile(url: self.root + bonded, classification: subject)!
                        })
                        arrayProtect.sync {
                            allPapers.append(contentsOf: newFiles)
                        }
                    }
                }
                subGroup.wait()
            }
        }
        group.wait()
        
        if exception {
            return nil
        }
        
        return allPapers.sorted(by: { $0.name.compare($1.name) == ComparisonResult.orderedAscending })
    }
}
