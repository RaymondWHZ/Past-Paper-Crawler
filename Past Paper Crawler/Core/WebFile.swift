//
//  WebFile.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/2.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Foundation

class WebFile {
    let name: String
    let fullUrl: URL
    
    init?(url: String) {
        guard let _fullUrl = URL(string: url) else {
            return nil
        }
        fullUrl = _fullUrl
        
        let index = url.lastIndex(of: "/")!
        name = String(url[url.index(after: index)...])
    }
    
    func download(to path: String) -> Bool {
        guard let data = NSData(contentsOf: fullUrl) else {
            return false
        }
        
        var p = path
        if p.last != "/" {
            p += "/"
        }
        data.write(toFile: p + name, atomically: true)
        
        return true
    }
}



private var downloadStack = 0
var softwareDownloadStack: Int {
    return downloadStack
}

func downloadFiles(specifiedFiles: [WebFile], to path: String) -> [WebFile] {
    
    var failed: [WebFile] = []
    
    let count = specifiedFiles.count
    downloadStack += count
    
    let group = DispatchGroup()
    for paper in specifiedFiles {
        DispatchQueue.global().async {
            group.enter()
            defer {
                group.leave()
            }
            
            if !paper.download(to: path) {
                failed.append(paper)
            }
        }
    }
    group.wait()
    
    downloadStack -= count
    
    return failed
}
