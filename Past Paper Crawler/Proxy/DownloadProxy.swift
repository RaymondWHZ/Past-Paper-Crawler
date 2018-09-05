//
//  DownloadProxy.swift
//  Past Paper Crawler
//
//  Created by 吴浩榛 on 2018/9/3.
//  Copyright © 2018年 吴浩榛. All rights reserved.
//

import Cocoa

protocol DownloadProxy {
    func downloadPapers(specifiedPapers: [WebFile])
}

class FileManagerProxy: DownloadProxy {
    
    // todo implement local file manager
    
    let website: PastPaperWebsite
    let localPath: String
    
    init(website: PastPaperWebsite, localPath: String) {
        self.website = website
        self.localPath = localPath
    }
    
    func downloadPapers(specifiedPapers: [WebFile]) {
        
    }
}

class DirectAccess: DownloadProxy {
    func downloadPapers(specifiedPapers: [WebFile]) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
        openPanel.begin{ result in
            if result == NSApplication.ModalResponse.OK {
                website.downloadPapers(specifiedPapers: specifiedPapers, to: openPanel.url!.path)
            }
        }
    }
}
