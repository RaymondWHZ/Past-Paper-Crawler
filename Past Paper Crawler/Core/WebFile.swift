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
    var classification: String?
    
    init?(url: String, classification: String? = nil) {
        guard let _fullUrl = URL(string: url) else {
            return nil
        }
        fullUrl = _fullUrl
        
        if let index = url.lastIndex(of: "/") {
            name = String(url[url.index(after: index)...])
        }
        else {
            name = url
        }
        
        self.classification = classification
    }
    
    func download(to path: String, classify: Bool = false) -> Bool {
        guard let data = NSData(contentsOf: fullUrl) else {
            return false
        }
        
        var p = path
        if p.last != "/" {
            p += "/"
        }
        if classify && classification != nil {
            p += classification! + "/"
        }
        if !fileManager.fileExists(atPath: p) {
            try? fileManager.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: nil)
        }
        
        data.write(toFile: p + name, atomically: true)
        
        return true
    }
}



private var downloadStack = 0
var webFileDownloadStack: Int {
    get {
        return downloadStack
    }
}

extension Array where Element: WebFile {
    
    func download(to path: String, classify: Bool = false) -> [WebFile] {
        var failed: [WebFile] = []
        
        let count = self.count
        downloadStack += count
        
        let group = DispatchGroup()
        for paper in self {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    group.leave()
                }
                
                if !paper.download(to: path, classify: classify) {
                    failed.append(paper)
                }
            }
        }
        group.wait()
        
        downloadStack -= count
        
        return failed
    }
}
