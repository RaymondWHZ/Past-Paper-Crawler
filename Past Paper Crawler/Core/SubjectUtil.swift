//
//  Util.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/8.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Foundation

class Subject : NSObject, NSCoding {
    let level: String
    let name: String
    let enabled: Bool
    
    init(level: String, name: String, enabled: Bool = true) {
        self.level = level
        self.name = name
        self.enabled = enabled
    }
    
    func copy(alterLevel: String? = nil, alterName: String? = nil, alterEnabled: Bool? = nil) -> Subject {
        return Subject(level: alterLevel ?? level, name: alterName ?? name, enabled: alterEnabled ?? enabled)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(level, forKey: "Level")
        coder.encode(name, forKey: "Name")
        coder.encode(enabled, forKey: "Enabled")
    }
    
    required init?(coder decoder: NSCoder) {
        level = decoder.decodeObject(forKey: "Level") as? String ?? ""
        name = decoder.decodeObject(forKey: "Name") as? String ?? ""
        enabled = decoder.decodeBool(forKey: "Enabled")
    }
}

private var subjectUtils: [String: SubjectUtil] = [:]
class SubjectUtil {
    
    static var current: SubjectUtil {
        return SubjectUtil.get(for: PFUsingWebsite)
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
                DispatchQueue.global(qos: .background).async {
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
    
    func findSubject(with str: String) -> Subject? {
        guard let subjectLists = self.subjectLists else {
            return nil
        }
        
        for level in subjectLists.keys {
            if let subject = findSubject(in: level, with: str) {
                return Subject(level: level, name: subject)
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
