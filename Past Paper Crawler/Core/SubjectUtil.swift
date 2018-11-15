//
//  Util.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/8.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Foundation

private var subjectUtils: [String: SubjectUtil] = [:]
class SubjectUtil {
    
    static var current: SubjectUtil {
        return SubjectUtil.get(for: usingWebsite)
    }
    
    let website: PastPaperWebsite
    
    private init(website: PastPaperWebsite) {
        self.website = website
    }
    
    static func get(for website: PastPaperWebsite) -> SubjectUtil {
        if let subjectUtil = subjectUtils[website.root] {
            return subjectUtil
        }
        
        let new = SubjectUtil(website: website)
        subjectUtils[website.root] = new
        return new
    }
    
    private var subjectListsCache: [String: [String]]?
    private let subjectListsQueue = DispatchQueue(label: "Subject Lists Protect")
    var subjectLists: [String: [String]]? {
        var ret: [String: [String]]?
        subjectListsQueue.sync {
            if subjectListsCache != nil {
                ret = subjectListsCache
                return
            }
            
            guard let levels = website.getLevels() else {
                return
            }
            
            subjectListsCache = [:]
            
            let group = DispatchGroup()
            for level in levels {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    defer {
                        group.leave()
                    }
                    
                    guard let subjects = self.website.getSubjects(level: level) else {
                        self.subjectListsCache = nil
                        return
                    }
                    
                    self.subjectListsCache?[level] = subjects
                }
            }
            group.wait()
            
            ret = subjectListsCache
        }
        return ret
    }
    
    func findSubject(with str: String) -> (String, String)? {
        guard let subjectLists = self.subjectLists else {
            return nil
        }
        
        for level in subjectLists.keys {
            if let subject = findSubject(in: level, with: str) {
                return (level, subject)
            }
        }
        
        return nil
    }
    
    func findSubject(in level: String, with str: String) -> String? {
        guard let subjectList = self.subjectLists?[level] else {
            return nil
        }
        
        return subjectList.first(where: { $0.lowercased().contains(str) })
    }
}

func getSubjectCode(of subject: String) -> String {
    let end = subject.lastIndex(where: { $0 <= "9" && $0 >= "0"})!
    let start = subject.index(end, offsetBy: -3)
    let code = String(subject[start...end])
    return code
}
