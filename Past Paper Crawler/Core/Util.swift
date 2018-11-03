//
//  Util.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/8.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Foundation

private var subjectListsCache: [String: [String]]? = nil
var subjectLists: [String: [String]]? {
    if subjectListsCache == nil {
        subjectListsCache = [:]
        
        guard let levels = website.getLevels() else {
            subjectListsCache = nil
            return nil
        }
        
        let group = DispatchGroup()
        for level in levels {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    group.leave()
                }
                guard let subjects = website.getSubjects(level: level) else {
                    subjectListsCache = nil
                    return
                }
                
                subjectListsCache?[level] = subjects
            }
        }
        group.wait()
    }
    
    return subjectListsCache
}

func findSubject(with str: String) -> (String, String)? {
    guard let subjectLists = subjectLists else {
        return nil
    }
    
    for level in subjectLists.keys {
        let subject = findSubject(in: level, with: str)
        if subject != nil {
            return (level, subject!)
        }
    }
    
    return nil
}

func findSubject(in level: String, with str: String) -> String? {
    guard let subjectList = subjectListsCache?[level] else {
        return nil
    }
    return subjectList.first(where: { $0.contains(str) })
}

func getCode(of subject: String) -> String {
    let end = subject.lastIndex(where: { $0 <= "9" && $0 >= "0"})!
    let start = subject.index(end, offsetBy: -3)
    let code = String(subject[start...end])
    return code
}

func cleanSubjectsCache() {
    subjectListsCache = nil
}
