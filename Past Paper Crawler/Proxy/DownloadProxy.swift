//
//  DownloadProxy.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

protocol DownloadProxy {
    func downloadPapers(level: String, subject: String, specifiedPapers: [String])
}

class FileManagerProxy: DownloadProxy {
    // todo implement local file manager
    
    let website: PastPaperWebsite
    let localPath: String
    
    init(website: PastPaperWebsite, localPath: String) {
        self.website = website
        self.localPath = localPath
    }
    
    func downloadPapers(level: String, subject: String, specifiedPapers: [String]) {
        
    }
}

class DirectAccess: DownloadProxy {
    func downloadPapers(level: String, subject: String, specifiedPapers: [String]) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.begin{ result in
            if result == NSApplication.ModalResponse.OK {
                website.downloadPapers(level: level, subject: subject, specifiedPapers: specifiedPapers, toPath: openPanel.url!.path)
            }
        }
    }
}
