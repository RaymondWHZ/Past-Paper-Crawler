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
    private var criteriaSummaryCache: Dictionary<String, [String]>?
    var criteriaSummary: Dictionary<String, [String]> {
        get {
            if criteriaSummaryCache == nil {
                criteriaSummaryCache = [:]
            }
            
            return criteriaSummaryCache!
        }
    }
    
    private var wholeList: [WebFile] = []
    private var currentCriteria: Dictionary<String, String> = [:]
    
    func reloadFrom(level: String, subject: String) {
        wholeList = website.getPapers(level: level, subject: subject)
        
        // all cache must be reloaded
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
    
    private var currentListCache: [WebFile]?
    var currentList: [WebFile] {
        get {
            if currentListCache == nil {
                currentListCache = wholeList
                // implement filter according to criteria
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
