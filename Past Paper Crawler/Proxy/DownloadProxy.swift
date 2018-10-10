//
//  DownloadProxy.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

protocol DownloadProxy {
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> ())
}

class FileManagerProxy: DownloadProxy {
    // todo implement local file manager
    
    let website: PastPaperWebsite
    let localPath: String
    
    init(website: PastPaperWebsite, localPath: String) {
        self.website = website
        self.localPath = localPath
    }
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        
    }
}

class DirectAccess: DownloadProxy {
    let openPanel = NSOpenPanel()
    
    init() {
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
    }
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        self.openPanel.begin{ result in
            DispatchQueue.global().async {
                
                var failed: [WebFile] = []
                
                if result == NSApplication.ModalResponse.OK {
                    failed = downloadFiles(specifiedFiles: specifiedPapers, to: self.openPanel.url!.path)
                }
                
                DispatchQueue.main.async {
                    exitAction(failed)
                }
            }
        }
    }
}
