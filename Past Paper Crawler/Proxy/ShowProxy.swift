//
//  FileManager.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/2.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Foundation

class ShowProxy {
    
    var level: String?
    var subject: String?
    
    // authoritized keys: season, paper, edition, type
    private var _criteriaSummary: Dictionary<String, [String]>?
    var criteriaSummary: Dictionary<String, [String]> {
        get {
            if _criteriaSummary == nil {
                _criteriaSummary = [:]
            }
            
            return _criteriaSummary!
        }
    }
    
    var currentCriteria: Dictionary<String, String> = [:]
    
    private var wholeList: [String] = []
    
    var currentShowList: [String] {
        get {
            return wholeList
        }
    }
    
    func reloadFrom(level: String, subject: String) {
        wholeList = website.getPapers(level: level, subject: subject)
    }
    
    func downloadPapers(at indices: [Int]) {
        var papers: [String] = []
        for index in indices {
            papers.append(currentShowList[index])
        }
        downloadProxy.downloadPapers(level: level!, subject: subject!, specifiedPapers: papers)
    }
}

class PapersWithAnswer: ShowProxy {
    
}
