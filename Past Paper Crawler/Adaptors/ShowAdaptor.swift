//
//  FileManager.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

private let year = "year"
private let yearRange = 6...7
private let season = "season"
private let seasonRange = 5
private let paper = "paper"
private let paperRange = 12
private let region = "region"
private let regionRange = 13
private let type = "type"
private let typeRange = 9...10

private let withPaperLength = 13 + 4
private let withEditionLength = 14 + 4

private let criteriaKeys = [year, season, paper, region, type]

typealias ADCriteria = [String : String]

private let yearPrefix = "20"
private let noRegion = "Region -"
private let none = "None"
private let other = "other..."

private let seasons = [
    "s": "May/June",
    "w": "November",
    "m": "March",
    "y": none
]

private let types = [
    "ms": "Mark Scheme",
    "qp": "Question Paper",
    "er": "Examiner Report",
    "qr": "Question Recording"
]

private let paperPrefix = "Paper "
private let regionPrefix = "Region "


private let regularFilePattern = "[0-9]{4}_[wsmy][0-9]{2}_[a-z]{2}(_[1-9][1-9]?)?.pdf"  // "0478_s18_ms_11.pdf" or "0478_s18_er.pdf"
private let regularFileRegex = try! NSRegularExpression(pattern: regularFilePattern, options: .caseInsensitive)
private func info(of paperName: String) -> ADCriteria {
    let count = paperName.count
    
    var ret: ADCriteria = [year: other, season: other, paper: other, region: other, type: other]
    
    if regularFileRegex.firstMatch(in: paperName, range: NSRange(location: 0, length: paperName.count)) == nil {
        return ret
    }
    
    let cYear: String = paperName[yearRange]
    ret[year] = yearPrefix + cYear
    
    let cSeason: String = paperName[seasonRange]
    ret[season] = seasons[cSeason] ?? other
    
    let cType: String = paperName[typeRange]
    ret[type] = types[cType] ?? other
    
    if count < withPaperLength {
        return ret
    }
    
    let cPaper: String = paperName[paperRange]
    ret[paper] = paperPrefix + cPaper
    
    if count < withEditionLength {
        ret[region] = noRegion
        return ret
    }
    
    let cEdition: String = paperName[regionRange]
    ret[region] = regionPrefix + cEdition
    
    return ret
}

private let paperPattern = "[0-9]{4}_[wsmy][0-9]{2}_(qp|ms)_[1-9][1-9]?.pdf"  // only "0478_s18_ms_11.pdf"
private let paperRegex = try! NSRegularExpression(pattern: paperPattern, options: .caseInsensitive)
private func isPaper(_ name: String) -> Bool {
    return paperRegex.firstMatch(in: name, range: NSRange(location: 0, length: name.count)) != nil
}

private func paperLocator(of name: String) -> String? {
    if !isPaper(name) { return nil }
    return name[seasonRange...yearRange.upperBound] + name[paperRange...regionRange]
}

private func paperDescription(of name: String) -> String? {
    if !isPaper(name) { return nil }
    let fInfo = info(of: name)
    return "\(fInfo[year]!) \(fInfo[season]!) \(fInfo[paper]!) \(fInfo[region]!)"
}


class ADPaperAnswerCouple {
    
    let name: String
    let questionPaper: WebFile
    let markScheme: WebFile
    let fInfo: ADCriteria
    
    init?(qp: WebFile, ms: WebFile) {
        let qpName = qp.name
        let msName = ms.name
        if qpName[typeRange] != "qp" || msName[typeRange] != "ms" { return nil }
        
        guard
            let qpLocator = paperLocator(of: qpName),
            let msLocator = paperLocator(of: msName)
        else { return nil }
        if qpLocator != msLocator { return nil }
        
        questionPaper = qp
        markScheme = ms
        
        name = paperDescription(of: qpName)!
        
        fInfo = info(of: qpName).filter { $0.key != type }
    }
    
    static func makeArray(from papers: [WebFile]) -> [ADPaperAnswerCouple] {
        // filter out files that are not qp or ms and those before 2005
        var filtered: [(WebFile, String)] = []
        papers.forEach { (f) in
            let name = f.name
            if name.count < 13 + 4 { return }
            let type = name[typeRange]
            if (type == "ms" || type == "qp") {
                let year = name[yearRange]
                if year > "04" {
                    if let locator = paperLocator(of: name) {
                        filtered.append((f, locator + type[0]))
                    }
                }
            }
        }
        
        // sort the files to put same qp and ms together (faster than random search, nlogn < n^2)
        let sortedList = filtered.sorted { $0.1 < $1.1 }
        
        // find all couples and put them into array
        var coupleArray: [ADPaperAnswerCouple] = []
        var currentPos = 0
        while currentPos < sortedList.count - 1 {
            let file1 = sortedList[currentPos].0
            let file2 = sortedList[currentPos + 1].0
            if let couple = ADPaperAnswerCouple(qp: file2, ms: file1) {
                coupleArray.append(couple)
                currentPos += 1
            }
            currentPos += 1
        }
        
        return coupleArray
    }
}


typealias ADCriteriaSummary = [String : [String]]

private func summarizeCriteria(for papers: [WebFile]) -> ADCriteriaSummary {
    // set is able to exclude duplicated items automatically
    var setSummary: [String: Set<String>] = [:]
    for key in criteriaKeys {
        setSummary[key] = Set()
    }
    
    // get all paper infos and put them together into set
    for rawPaper in papers {
        let paperInfo = info(of: rawPaper.name)
        for key in criteriaKeys {
            setSummary[key]!.insert(paperInfo[key]!)
        }
    }
    
    // sort the elements in each set and put them into final summary
    var criteriaSummary: ADCriteriaSummary = [:]
    for key in criteriaKeys {
        let unsorted = setSummary[key]!
        
        if unsorted.count == 1 {
            criteriaSummary[key] = []
            continue
        }
        
        let sorted = unsorted.sorted()
        criteriaSummary[key] = sorted
    }
    
    return criteriaSummary
}


class ADShowManager {
    
    var showAll: Bool = PFDefaultShowAll
    
    var currentSubject: Subject?
    
    private var wholeList: [WebFile] = []
    private var wholeCoupleList: [ADPaperAnswerCouple] = []
    var criteriaSummary: ADCriteriaSummary = [:]
    
    // ---- access part ----
    
    func loadFrom(subject: Subject) -> Bool {
        guard let paperList = PFUsingWebsite.getPapers(level: subject.level, subject: subject.name) else {
            return false
        }
        
        currentSubject = subject
        wholeList = paperList
        wholeCoupleList = ADPaperAnswerCouple.makeArray(from: paperList)
        criteriaSummary = summarizeCriteria(for: paperList)
        _criteria = [:]
        
        // all cache must be reloaded
        cleanCache()
        
        return true
    }
    
    var currentShowList: [String] {
        if showAll {
            return showAllList
        }
        else {
            return showCoupleList
        }
    }
    
    func getSelectedPapers(at indices: [Int]) -> [WebFile] {
        var papers: [WebFile]
        if showAll {
            papers = indices.map({ currentAllList[$0] })
        }
        else {
            papers = []
            for index in indices {
                let fileCouple = currentCoupleList[index]
                papers.append(fileCouple.questionPaper)
                papers.append(fileCouple.markScheme)
            }
        }
        return papers
    }
    
    // ---- critria part ----
    
    let authoritizedKeys = [year, season, paper, region, type]
    
    // e.g. [year: "2018", season: "s"]
    private var _criteria: ADCriteria = [:]
    var criteria: ADCriteria {
        get {
            return _criteria
        }
        set {
            _criteria = newValue
            cleanCache()
        }
    }
    
    // ---- all part ----
    
    private var currentAllListCache: [WebFile]?
    // uses wholeList and criteria to generate new list
    var currentAllList: [WebFile] {
        // filtered list acording to criteria
        if currentAllListCache == nil {
            currentAllListCache = wholeList.filter{
                (raw) in
                
                let paperInfo = info(of: raw.name)
                for cri in _criteria.keys{
                    if paperInfo[cri] != _criteria[cri]{
                        return false
                    }
                }
                
                return true
            }
        }
        
        return currentAllListCache!
    }
    
    private var showAllListCache: [String]?
    var showAllList: [String] {
        if showAllListCache == nil {
            showAllListCache = currentAllList.map({ $0.name })
        }
        
        return showAllListCache!
    }
    
    // ---- couple part ----
    
    private var currentCoupleListCache: [ADPaperAnswerCouple]? = nil
    var currentCoupleList: [ADPaperAnswerCouple] {
        // filtered list acording to criteria
        if currentCoupleListCache == nil {
            currentCoupleListCache = wholeCoupleList.filter{
                (raw) in
                
                let fInfo = raw.fInfo
                for cri in _criteria.keys {
                    if let info = fInfo[cri], info != _criteria[cri]! {
                        return false
                    }
                }
                
                return true
            }
        }
        
        return currentCoupleListCache!
    }
    
    var showCoupleListCache: [String]? = nil
    var showCoupleList: [String] {
        if showCoupleListCache == nil {
            showCoupleListCache = currentCoupleList.map { $0.name }
        }
        
        return showCoupleListCache!
    }
    
    // ---- clean part ----
    
    func cleanCache() {
        currentAllListCache = nil
        showAllListCache = nil
        currentCoupleListCache = nil
        showCoupleListCache = nil
    }
}
