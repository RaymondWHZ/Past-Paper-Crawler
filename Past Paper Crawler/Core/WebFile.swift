//
//  WebFile.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/10/2.
//  Copyright © 2018 吴浩榛. All rights reserved.
//

import Cocoa

class WebFile : NSObject, NSCoding {
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
    
    func download(to path: String, classify: Bool = false, avoidDuplication: Bool = false) -> String? {
        var p = path
        if p.last != "/" {
            p += "/"
        }
        if classify && classification != nil {
            let existingFolders = try? PCFileManager.contentsOfDirectory(atPath: p)
            let classificationCode = getSubjectCode(of: classification!)
            if let sameClassification = existingFolders?.first(where: { $0.contains(classificationCode) }) {
                p += sameClassification + "/"
            }
            else {
                p += classification! + "/"
            }
        }
        if !PCFileManager.fileExists(atPath: p) {
            try? PCFileManager.createDirectory(atPath: p, withIntermediateDirectories: true, attributes: nil)
        }
        p += name
        
        if avoidDuplication && PCFileManager.fileExists(atPath: p) {
            return p
        }
        
        guard let data = NSData(contentsOf: fullUrl) else {
            return nil
        }
        
        if data.write(toFile: p, atomically: true) {
            return p
        }
        
        return nil
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "Name")
        aCoder.encode(fullUrl, forKey: "Full Url")
        aCoder.encode(classification, forKey: "Classification")
    }
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObject(forKey: "Name") as! String
        fullUrl = aDecoder.decodeObject(forKey: "Full Url") as! URL
        classification = aDecoder.decodeObject(forKey: "Classification") as? String
    }
}



extension Array where Element: WebFile {
    
    func download(to path: String, classify: Bool = false, showInFinder: Bool = false, avoidDuplication: Bool = true) -> [WebFile] {
        var paths: [String]? = (showInFinder) ? [] : nil
        var failed: [WebFile] = []
        
        let group = DispatchGroup()
        for paper in self {
            group.enter()
            DispatchQueue.global(qos: .background).async {
                defer {
                    group.leave()
                }
                
                if let actualPath = paper.download(to: path, classify: classify, avoidDuplication: avoidDuplication) {
                    paths?.append(actualPath)
                }
                else {
                    failed.append(paper)
                }
            }
        }
        group.wait()
        
        if let urls = paths?.map({ URL(fileURLWithPath: $0) }), !urls.isEmpty {
            workspace.activateFileViewerSelecting(urls)
        }
        
        return failed
    }
}
