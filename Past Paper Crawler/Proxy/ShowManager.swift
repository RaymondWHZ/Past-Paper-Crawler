//
//  FileManager.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

private let year = "year"
private let season = "season"
private let paper = "paper"
private let edition = "edition"
private let type = "type"

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
    func subString(from: Int, to: Int) -> String {
        
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: to)
        
        return String(self[startIndex...endIndex])
    }
}

let paperPattern = "[0-9]{4}_[wsmy]\\d{2}_[a-z]{2}(_[1-9][1-9]?)?.pdf"  // "0478_s18_ms_11.pdf"
let paperRegex = try! NSRegularExpression(pattern: paperPattern, options: .caseInsensitive)
func info(of paperName: String) -> [String: String]{
    let count = paperName.count
    
    var ret: [String: String] = [year: other, season: other, paper: none, edition: editionOne, type: other]
    
    if paperRegex.matches(in: paperName, options: .init(rawValue: 0), range: NSRange(location: 0, length: paperName.count)).isEmpty {
        ret[edition] = other
        return ret
    }
    
    let cYear: String = paperName.subString(from: 6, to: 7)
    ret[year] = yearPrefix + cYear
    
    let cSeason: String = paperName.subString(from: 5, to: 5)
    ret[season] = seasons[cSeason] ?? other
    
    let cType: String = paperName.subString(from: 9, to: 10)
    ret[type] = types[cType] ?? other
    
    if count < 13 + 4 {
        return ret
    }
    
    let cPaper: String = paperName.subString(from: 12, to: 12)
    ret[paper] = paperPrefix + cPaper
    
    if count < 14 + 4 {
        return ret
    }
    
    let cEdition: String = paperName.subString(from: 13, to: 13)
    ret[edition] = editionPrefix + cEdition
    
    return ret
}

func infoStrWithoutType(file: WebFile) -> String {
    let fInfo = info(of: file.name)
    return "\(fInfo[year]!) \(fInfo[season]!) \(fInfo[paper]!) \(fInfo[edition]!)"
}


class PaperAnswerCouple {
    
    let questionPaper: WebFile
    let markScheme: WebFile
    
    let fInfo: [String: String]
    
    private var desc: String
    
    init?(qp: WebFile, ms: WebFile) {
        var qpInfo = info(of: qp.name)
        let msInfo = info(of: ms.name)
        
        if qpInfo[type] != types["qp"] || msInfo[type] != types["ms"] {
            return nil
            //fatalError("Wrong file type!")
        }
        
        if infoStrWithoutType(file: qp) != infoStrWithoutType(file: ms) {
            return nil
            //fatalError("Question paper and mark scheme not match!")
        }
        
        questionPaper = qp
        markScheme = ms
        
        qpInfo.removeValue(forKey: type)
        fInfo = qpInfo
        
        desc = infoStrWithoutType(file: qp)
    }
    
    var description: String {
        return desc
    }
}

func makeCoupleArray(from papers: [WebFile]) -> [PaperAnswerCouple] {
    // filter out files that are not qp or ms and those before 2005
    let filtered = papers.filter { (f) -> Bool in
        let fInfo = info(of: f.name)
        if fInfo["type"] == types["ms"] || fInfo["type"] == types["qp"] {
            return fInfo["year"]!.compare("2004") == ComparisonResult.orderedDescending
        }
        return false
    }
    // sort the files to put same qp and ms together (faster than random search, nlogn < n^2)
    let sortedList = filtered.sorted { (f1, f2) -> Bool in
        let f1InfoStr = infoStrWithoutType(file: f1)
        let f2InfoStr = infoStrWithoutType(file: f2)
        return f1InfoStr.compare(f2InfoStr) == ComparisonResult.orderedAscending
    }
    
    // find all couples and put them into array
    var coupleArray: [PaperAnswerCouple] = []
    var currentPos = 0
    while currentPos < sortedList.count {
        let currentFile = sortedList[currentPos]  // fetch the file at this place
        currentPos += 1
        if currentPos >= sortedList.count {  // if the index has been out of bound, exit the loop
            break
        }
        
        let cfInfo = info(of: currentFile.name)
        
        let nextFile = sortedList[currentPos]
        
        if cfInfo["type"] == types["qp"] {
            if let fileCouple = PaperAnswerCouple(qp: currentFile, ms: nextFile) {
                coupleArray.append(fileCouple)
                currentPos += 1
            }
        }
        else {
            if let fileCouple = PaperAnswerCouple(qp: nextFile, ms: currentFile) {
                coupleArray.append(fileCouple)
                currentPos += 1
            }
        }
    }
    
    return coupleArray
}



class ShowManager {
    
    var showAll: Bool = PFDefaultShowAll
    
    var currentLevel: String = ""
    var currentSubject: String = ""
    
    private var wholeList: [WebFile] = []
    
    // ---- user interface part ----
    
    func loadFrom(level: String, subject: String) -> Bool {
        guard let paperList = PFUsingWebsite.getPapers(level: level, subject: subject) else {
            return false
        }
        
        currentLevel = level
        currentSubject = subject
        wholeList = paperList
        
        // all cache must be reloaded
        cleanAllCache()
        
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
    private var currentCriteria: Dictionary<String, String> = [:]
    
    private var criteriaSummaryCache: Dictionary<String, [String]>?
    // uses 'wholeList' to generate summary
    var criteriaSummary: Dictionary<String, [String]> {
        if criteriaSummaryCache == nil {
            // set is able to exclude duplicated items automatically
            var setSummary: [String: Set<String>] = [:]
            for key in authoritizedKeys {
                setSummary[key] = Set()
            }
            
            // get all paper infos and put them together into set
            for rawPaper in wholeList{
                let paperInfo = info(of: rawPaper.name)
                for key in authoritizedKeys {
                    setSummary[key]!.insert(paperInfo[key]!)
                }
            }
            
            // sort the elements in each set and put them into final summary
            criteriaSummaryCache = [:]
            for key in authoritizedKeys {
                let unsorted = setSummary[key]!
                
                if unsorted.count == 1 {
                    criteriaSummaryCache![key] = []
                    continue
                }
                
                let sorted = unsorted.sorted()
                criteriaSummaryCache![key] = sorted
            }
        }
        
        return criteriaSummaryCache!
    }
    
    func setCriterion(name: String, value: String) {
        currentCriteria[name] = value
        
        // show lists must be reloaded
        cleanShowListCache()
    }
    
    func removeCriterion(name: String) {
        currentCriteria.removeValue(forKey: name)
        
        // show lists must be reloaded
        cleanShowListCache()
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
    
    private var wholeCoupleListCache: [PaperAnswerCouple]? = nil
    var wholeCoupleList: [PaperAnswerCouple] {
        if wholeCoupleListCache == nil {
            wholeCoupleListCache = makeCoupleArray(from: wholeList)
        }
        
        return wholeCoupleListCache!
    }
    
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
            showCoupleListCache = currentCoupleList.map { $0.description }
        }
        
        return showCoupleListCache!
    }
    
    // ---- clean part ----
    
    func cleanShowListCache() {
        currentAllListCache = nil
        showAllListCache = nil
        currentCoupleListCache = nil
        showCoupleListCache = nil
    }
    
    func cleanAllCache() {
        currentCriteria = [:]
        criteriaSummaryCache = nil
        wholeCoupleListCache = nil
        
        // clean show lists as well
        cleanShowListCache()
    }
}
