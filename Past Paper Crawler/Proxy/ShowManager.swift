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
private let edition = "edition"
private let editionRange = 13
private let type = "type"
private let typeRange = 9...10

private let withPaperLength = 13 + 4
private let withEditionLength = 14 + 4

private let criteriaKeys = [year, season, paper, edition, type]

typealias Criteria = [String : String]

private let yearPrefix = "20"
private let editionOne = "Edition \(1)"
private let none = "None"
private let other = "other..."

private let seasons = [
    "s": "May/June",
    "w": "November",
    "m": "March",
    "y": none
]

let types = [
    "ms": "Mark Scheme",
    "qp": "Question Paper",
    "er": "Examiner Report",
    "qr": "Question Recording"
]

private let paperPrefix = "Paper "
private let editionPrefix = "Edition "



extension String{
    
    subscript(intIndex: Int) -> String {
        let index = self.index(self.startIndex, offsetBy: intIndex)
        return String(self[index])
    }
    
    subscript(range: ClosedRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex...endIndex])
    }
}

let regularFilePattern = "[0-9]{4}_[wsmy][0-9]{2}_[a-z]{2}(_[1-9][1-9]?)?.pdf"  // "0478_s18_ms_11.pdf" or "0478_s18_er.pdf"
let regularFileRegex = try! NSRegularExpression(pattern: regularFilePattern, options: .caseInsensitive)
func info(of paperName: String) -> Criteria {
    let count = paperName.count
    
    var ret: Criteria = [year: other, season: other, paper: other, edition: other, type: other]
    
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
        ret[edition] = editionOne
        return ret
    }
    
    let cEdition: String = paperName[editionRange]
    ret[edition] = editionPrefix + cEdition
    
    return ret
}

let paperPattern = "[0-9]{4}_[wsmy][0-9]{2}_(qp|ms)_[1-9][1-9]?.pdf"  // only "0478_s18_ms_11.pdf"
let paperRegex = try! NSRegularExpression(pattern: paperPattern, options: .caseInsensitive)
func isPaper(_ name: String) -> Bool {
    return paperRegex.firstMatch(in: name, range: NSRange(location: 0, length: name.count)) != nil
}

func paperLocator(of name: String) -> String? {
    if !isPaper(name) { return nil }
    return name[seasonRange...yearRange.upperBound] + name[paperRange...editionRange]
}

func paperDescription(of name: String) -> String? {
    if !isPaper(name) { return nil }
    let fInfo = info(of: name)
    return "\(fInfo[year]!) \(fInfo[season]!) \(fInfo[paper]!) \(fInfo[edition]!)"
}


class PaperAnswerCouple {
    
    let name: String
    let questionPaper: WebFile
    let markScheme: WebFile
    let fInfo: Criteria
    
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
}

func makeCoupleArray(from papers: [WebFile]) -> [PaperAnswerCouple] {
    // filter out files that are not qp or ms and those before 2005
    var filtered: [(WebFile, String)] = []
    papers.forEach { (f) in
        let name = f.name
        if name.count < 13 + 4 { return }
        let type = name[typeRange]
        if (type == "ms" || type == "qp") {
            let year = name[yearRange]
            if year.compare("04") == ComparisonResult.orderedDescending {
                if let locator = paperLocator(of: name) {
                    filtered.append((f, locator + type[0]))
                }
            }
        }
    }
    
    // sort the files to put same qp and ms together (faster than random search, nlogn < n^2)
    let sortedList = filtered.sorted { $0.1 < $1.1 }
    
    // find all couples and put them into array
    var coupleArray: [PaperAnswerCouple] = []
    var currentPos = 0
    while currentPos < sortedList.count - 1 {
        let file1 = sortedList[currentPos].0
        let file2 = sortedList[currentPos + 1].0
        if let couple = PaperAnswerCouple(qp: file2, ms: file1) {
            coupleArray.append(couple)
            currentPos += 1
        }
        currentPos += 1
    }
    
    return coupleArray
}


typealias CriteriaSummary = [String : [String]]

func summarizeCriteria(for papers: [WebFile]) -> CriteriaSummary {
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
    var criteriaSummary: CriteriaSummary = [:]
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


class ShowManager {
    
    var showAll: Bool = PFDefaultShowAll
    
    var currentLevel: String = ""
    var currentSubject: String = ""
    
    private var wholeList: [WebFile] = []
    private var wholeCoupleList: [PaperAnswerCouple] = []
    var criteriaSummary: CriteriaSummary = [:]
    
    // ---- access part ----
    
    func loadFrom(level: String, subject: String) -> Bool {
        guard let paperList = PFUsingWebsite.getPapers(level: level, subject: subject) else {
            return false
        }
        
        currentLevel = level
        currentSubject = subject
        wholeList = paperList
        wholeCoupleList = makeCoupleArray(from: paperList)
        criteriaSummary = summarizeCriteria(for: paperList)
        currentCriteria = [:]
        
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
    
    let authoritizedKeys = [year, season, paper, edition, type]
    
    // e.g. [year: "2018", season: "s"]
    private var currentCriteria: Criteria = [:]
    
    func setCriterion(name: String, value: String) {
        currentCriteria[name] = value
        
        // show lists must be reloaded
        cleanCache()
    }
    
    func removeCriterion(name: String) {
        currentCriteria.removeValue(forKey: name)
        
        // show lists must be reloaded
        cleanCache()
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
                for cri in currentCriteria.keys{
                    if paperInfo[cri] != currentCriteria[cri]{
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
    
    private var currentCoupleListCache: [PaperAnswerCouple]? = nil
    var currentCoupleList: [PaperAnswerCouple] {
        // filtered list acording to criteria
        if currentCoupleListCache == nil {
            currentCoupleListCache = wholeCoupleList.filter{
                (raw) in
                
                let fInfo = raw.fInfo
                for cri in currentCriteria.keys {
                    if let info = fInfo[cri], info != currentCriteria[cri]! {
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
