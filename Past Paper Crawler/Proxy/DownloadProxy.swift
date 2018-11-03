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

class DefaultPathProxy: DownloadProxy {
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        DispatchQueue.global().async {
            
            var failed: [WebFile] = []
            
            let path = userDefaults.string(forKey: defaultPathToken)!
            let createFolder = userDefaults.bool(forKey: createFolderToken)
            failed = downloadFiles(specifiedFiles: specifiedPapers, to: path, classify: createFolder)
            
            DispatchQueue.main.async {
                exitAction(failed)
            }
        }
    }
}

class AskUserProxy: DownloadProxy {
    let openPanel = NSOpenPanel()
    
    init() {
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.treatsFilePackagesAsDirectories = true
    }
    
    func downloadPapers(specifiedPapers: [WebFile], exitAction: @escaping ([WebFile]) -> () = { _ in }) {
        openPanel.begin{ result in
            DispatchQueue.global().async {
                
                var failed: [WebFile] = []
                
                if result == .OK {
                    let path = self.openPanel.url!.path
                    let createFolder = userDefaults.bool(forKey: createFolderToken)
                    failed = downloadFiles(specifiedFiles: specifiedPapers, to: path, classify: createFolder)
                }
                
                DispatchQueue.main.async {
                    exitAction(failed)
                }
            }
        }
    }
}
