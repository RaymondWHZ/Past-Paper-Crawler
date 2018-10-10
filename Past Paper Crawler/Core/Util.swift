//
//  Util.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/8.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Foundation

func findSubject(with str: String) -> (String, String)? {
    guard let levels = website.getLevels() else {
        return nil
    }
    
    var ret: (String, String)? = nil
    
    let group = DispatchGroup()
    for level in levels {
        DispatchQueue.global().async {
            group.enter()
            defer {
                group.leave()
            }
            
            guard let subjects = website.getSubjects(level: level) else {
                return
            }
            
            if let subject = subjects.first(where: { $0.contains(str) }) {
                ret = (level, subject)
            }
        }
    }
    group.wait()
    
    return ret
}
