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
    
    func download(to path: String, classify: Bool = false) -> String? {
        guard let data = NSData(contentsOf: fullUrl) else {
            return nil
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
        p += name
        
        data.write(toFile: p, atomically: true)
        
        return p
    }
}



private var downloadStack = 0
var webFileDownloadStack: Int {
    get {
        return downloadStack
    }
}

extension Array where Element: WebFile {
    
    func download(to path: String, classify: Bool = false, showInFinder: Bool = false) -> [WebFile] {
        var paths: [String]? = (showInFinder) ? [] : nil
        var failed: [WebFile] = []
        
        let count = self.count
        downloadStack += count
        
        let group = DispatchGroup()
        for paper in self {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                defer {
                    group.leave()
                }
                
                if let actualPath = paper.download(to: path, classify: classify) {
                    paths?.append(actualPath)
                }
                else {
                    failed.append(paper)
                }
            }
        }
        group.wait()
        
        if let urls = paths?.map({ URL(fileURLWithPath: $0) }) {
            workspace.activateFileViewerSelecting(urls)
        }
        
        downloadStack -= count
        
        return failed
    }
}
